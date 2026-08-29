


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."award_loyalty_points"("p_user_id" "uuid", "p_amount" integer, "p_reason" "text", "p_type" "text", "p_related_id" "uuid" DEFAULT NULL::"uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_current_points int;
BEGIN
    IF p_amount < 0 THEN
        SELECT COALESCE(ul.current_points, 0)
        INTO v_current_points
        FROM public.user_loyalty ul
        WHERE ul.user_id = p_user_id;

        IF v_current_points + p_amount < 0 THEN
            RAISE EXCEPTION 'Insufficient points';
        END IF;
    END IF;

    -- Skip transaction log for 0 points
    IF p_amount <> 0 THEN
        INSERT INTO public.points_transactions (user_id, amount, reason, type, related_id)
        VALUES (p_user_id, p_amount, p_reason, p_type, p_related_id);
    END IF;

    INSERT INTO public.user_loyalty (user_id, current_points, total_earned_points, updated_at)
    VALUES (p_user_id, GREATEST(0, p_amount), GREATEST(0, p_amount), NOW())
    ON CONFLICT (user_id) DO UPDATE SET
        current_points = GREATEST(0, public.user_loyalty.current_points + p_amount),
        total_earned_points = public.user_loyalty.total_earned_points + GREATEST(0, p_amount),
        updated_at = NOW();
END;
$$;


ALTER FUNCTION "public"."award_loyalty_points"("p_user_id" "uuid", "p_amount" integer, "p_reason" "text", "p_type" "text", "p_related_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."clamp_user_loyalty_points"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.current_points := GREATEST(COALESCE(NEW.current_points, 0), 0);
  NEW.total_earned_points := GREATEST(COALESCE(NEW.total_earned_points, 0), 0);

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."clamp_user_loyalty_points"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."confirm_delivery"("p_order_id" "uuid", "p_pin" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_correct_pin TEXT;
    v_assigned_id UUID;
    v_user_role TEXT;
BEGIN
    -- 1. Get current user's role
    SELECT role INTO v_user_role FROM public.profiles WHERE id = auth.uid();

    -- 2. Get order details
    SELECT delivery_code, assigned_delivery_person INTO v_correct_pin, v_assigned_id
    FROM public.orders WHERE id = p_order_id;

    -- 3. Validation: Only the assigned driver OR an ADMIN can confirm
    IF v_user_role != 'admin' AND (v_assigned_id IS NULL OR v_assigned_id != auth.uid()) THEN
        RAISE EXCEPTION 'Not authorized to confirm delivery' USING ERRCODE = 'P0001';
    END IF;

    -- 4. Check PIN
    IF v_correct_pin != p_pin THEN
        RAISE EXCEPTION 'Incorrect PIN' USING ERRCODE = 'P0002';
    END IF;

    -- 5. Update Order Status
    UPDATE public.orders 
    SET status = 'delivered', updated_at = NOW() 
    WHERE id = p_order_id;

    -- 6. Log history
    INSERT INTO public.order_status_history (order_id, status, changed_by)
    VALUES (p_order_id, 'delivered', auth.uid());
END;
$$;


ALTER FUNCTION "public"."confirm_delivery"("p_order_id" "uuid", "p_pin" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_referral_code"("p_user_id" "uuid") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_full_name TEXT;
    v_base_code TEXT;
    v_final_code TEXT;
    v_counter INTEGER := 0;
    v_random_suffix TEXT;
BEGIN
    SELECT split_part(full_name, ' ', 1)
    INTO v_full_name
    FROM public.profiles
    WHERE id = p_user_id;

    IF v_full_name IS NULL OR v_full_name = '' THEN
        v_base_code := 'SNK';
    ELSE
        v_base_code := UPPER(
            REGEXP_REPLACE(v_full_name, '[^A-Za-z0-9]', '', 'g')
        );

        IF v_base_code = '' THEN
            v_base_code := 'SNK';
        END IF;

        v_base_code := LEFT(v_base_code, 6);
    END IF;

    LOOP
        v_random_suffix := UPPER(
            SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 3)
        );

        v_final_code := v_base_code || v_random_suffix;

        IF NOT EXISTS (
            SELECT 1
            FROM public.referral_codes
            WHERE LOWER(code) = LOWER(v_final_code)
        ) THEN
            RETURN v_final_code;
        END IF;

        v_counter := v_counter + 1;

        IF v_counter >= 10 THEN
            RETURN UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
        END IF;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."generate_referral_code"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
    insert into public.profiles (
        id,
        email
    )
    values (
        new.id,
        new.email
    );

    return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_delivery_assignment"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    BEGIN
        PERFORM net.http_post(
            'https://obealvlqkffozfigtobc.supabase.co/functions/v1/notify-delivery'::text,

            -- Request body
            jsonb_build_object(
                'type', 'delivery_assignment',
                'table', 'orders',
                'record', row_to_json(NEW),
                'old_record', row_to_json(OLD),
                'schema', 'public'
            ),

            -- Query parameters
            '{}'::jsonb,

            -- Headers
            jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9iZWFsdmxxa2Zmb3pmaWd0b2JjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NTQ4NTEzOCwiZXhwIjoyMTAxMDYxMTM4fQ.smW7z_M2POmZUnpsRufplCWwyczimu186_D0k4udpUI'
            ),

            -- Timeout
            5000
        );

    EXCEPTION WHEN OTHERS THEN
        -- Notification failure must never prevent the order update/pickup
        -- from succeeding.
        RAISE WARNING
            'Delivery assignment notification failed: %',
            SQLERRM;
    END;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_delivery_assignment"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."on_order_status_change_referral"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    IF NEW.status = 'delivered'
       AND OLD.status IS DISTINCT FROM 'delivered'
    THEN
        PERFORM public.process_referral_reward(NEW.id);
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."on_order_status_change_referral"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."on_profile_created_generate_referral"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    INSERT INTO public.referral_codes (user_id, code)
    VALUES (NEW.id, public.generate_referral_code(NEW.id))
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."on_profile_created_generate_referral"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."place_order_atomic"("p_address_snapshot" "jsonb", "p_payment_method" "text", "p_total_price" numeric, "p_estimated_prep_time" integer, "p_items" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_order_id UUID;
    v_item JSONB;
    v_order JSONB;
BEGIN

    -- Create order
    INSERT INTO public.orders (
        user_id,
        status,
        address_snapshot,
        payment_method,
        total_price,
        estimated_prep_time
    )
    VALUES (
        auth.uid(),
        'pending',
        p_address_snapshot,
        p_payment_method,
        p_total_price,
        p_estimated_prep_time
    )
    RETURNING id INTO v_order_id;


    -- Create order items
    FOR v_item IN 
        SELECT * FROM jsonb_array_elements(p_items)
    LOOP

        INSERT INTO public.order_items (
            order_id,
            product_id,
            name_snapshot,
            quantity,
            price_at_purchase,
            image_snapshot
        )
        VALUES (
            v_order_id,
            (v_item->>'product_id')::UUID,
            v_item->>'name_snapshot',
            (v_item->>'quantity')::INTEGER,
            (v_item->>'price_at_purchase')::DECIMAL,
            v_item->>'image_snapshot'
        );

    END LOOP;


    -- Return created order
    SELECT row_to_json(o)::jsonb
    INTO v_order
    FROM public.orders o
    WHERE o.id = v_order_id;


    RETURN v_order;


EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;


ALTER FUNCTION "public"."place_order_atomic"("p_address_snapshot" "jsonb", "p_payment_method" "text", "p_total_price" numeric, "p_estimated_prep_time" integer, "p_items" "jsonb") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."orders" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "status" "text" DEFAULT 'pending'::"text",
    "total_price" numeric(10,2) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "address" "jsonb",
    "payment_method" "text" DEFAULT 'cash'::"text",
    "notes" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "assigned_delivery_person" "uuid",
    "address_snapshot" "jsonb" DEFAULT '{}'::"jsonb",
    "estimated_prep_time" integer,
    "delivery_code" "text",
    CONSTRAINT "orders_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'confirmed'::"text", 'preparing'::"text", 'ready'::"text", 'out_for_delivery'::"text", 'delivered'::"text", 'cancelled'::"text"])))
);

ALTER TABLE ONLY "public"."orders" REPLICA IDENTITY FULL;


ALTER TABLE "public"."orders" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."place_order_atomic"("p_address_snapshot" "jsonb", "p_payment_method" "text", "p_total_price" numeric, "p_items" "jsonb"[], "p_delivery_code" "text" DEFAULT NULL::"text", "p_estimated_prep_time" integer DEFAULT 25) RETURNS "public"."orders"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_order public.orders;
  v_item JSONB;
BEGIN
  -- 1. Create the Order with the PIN
  INSERT INTO public.orders (
    user_id, 
    status, 
    address_snapshot, 
    payment_method, 
    total_price, 
    delivery_code, 
    estimated_prep_time
  )
  VALUES (
    auth.uid(), 
    'pending', 
    p_address_snapshot, 
    p_payment_method, 
    p_total_price, 
    COALESCE(p_delivery_code, (FLOOR(RANDOM() * 90) + 10)::TEXT), 
    p_estimated_prep_time
  )
  RETURNING * INTO v_order;

  -- 2. Record initial status history
  INSERT INTO public.order_status_history (order_id, status, changed_by)
  VALUES (v_order.id, 'pending', auth.uid());

  -- 3. Insert Items from the array
  FOREACH v_item IN ARRAY p_items LOOP
    INSERT INTO public.order_items (
      order_id, 
      product_id, 
      name_snapshot, 
      quantity, 
      price_at_purchase, 
      image_snapshot
    )
    VALUES (
      v_order.id, 
      (v_item->>'product_id')::UUID, 
      v_item->>'name_snapshot', 
      (v_item->>'quantity')::INT, 
      (v_item->>'price_at_purchase')::NUMERIC, 
      v_item->>'image_snapshot'
    );
  END LOOP;

  RETURN v_order;
END;
$$;


ALTER FUNCTION "public"."place_order_atomic"("p_address_snapshot" "jsonb", "p_payment_method" "text", "p_total_price" numeric, "p_items" "jsonb"[], "p_delivery_code" "text", "p_estimated_prep_time" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_referral_reward"("p_order_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_referral RECORD;
    v_referrer_reward INTEGER := 100;
    v_referred_reward INTEGER := 50;
BEGIN
    -- Find the pending referral belonging to the order customer
    SELECT r.*
    INTO v_referral
    FROM public.referrals r
    JOIN public.orders o
      ON o.user_id = r.referred_user_id
    WHERE o.id = p_order_id
      AND r.status = 'pending'
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Only reward after the referred user has completed
    -- their first delivered order.
    IF (
        SELECT COUNT(*)
        FROM public.orders
        WHERE user_id = v_referral.referred_user_id
          AND status = 'delivered'
    ) <> 1 THEN
        RETURN;
    END IF;

    -- Lock and mark the referral first.
    -- This prevents duplicate rewards if the function is called twice.
    UPDATE public.referrals
    SET
        status = 'rewarded',
        qualified_at = COALESCE(qualified_at, now()),
        rewarded_at = now(),
        qualifying_order_id = p_order_id
    WHERE id = v_referral.id
      AND status = 'pending';

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Existing Sangak loyalty system
    PERFORM public.award_loyalty_points(
        v_referral.referrer_user_id,
        v_referrer_reward,
        'Referral Reward',
        'earn',
        v_referral.id
    );

    PERFORM public.award_loyalty_points(
        v_referral.referred_user_id,
        v_referred_reward,
        'Welcome Referral Reward',
        'earn',
        v_referral.id
    );
END;
$$;


ALTER FUNCTION "public"."process_referral_reward"("p_order_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_referral_reward"("p_referred_user_id" "uuid", "p_referral_code" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_validation JSONB;
    v_referrer_id UUID;
    v_code_id UUID;
    v_referrer_reward INT;
    v_referred_reward INT;
BEGIN
    -- User can only be referred once.
    IF EXISTS (
        SELECT 1
        FROM public.referrals
        WHERE referred_user_id = p_referred_user_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'already_referred'
        );
    END IF;

    -- Validate again on the server before processing.
    v_validation := public.validate_referral_code(
        p_referral_code,
        p_referred_user_id
    );

    IF NOT COALESCE((v_validation->>'valid')::BOOLEAN, false) THEN
        RETURN v_validation;
    END IF;

    v_referrer_id := (v_validation->>'referrer_id')::UUID;
    v_code_id := (v_validation->>'code_id')::UUID;

    -- Existing reward configuration.
    SELECT COALESCE(
        (
            SELECT value::INT
            FROM public.options
            WHERE name = 'referral_reward_referrer'
        ),
        50
    )
    INTO v_referrer_reward;

    SELECT COALESCE(
        (
            SELECT value::INT
            FROM public.options
            WHERE name = 'referral_reward_referred'
        ),
        25
    )
    INTO v_referred_reward;

    -- Create referral relationship.
    INSERT INTO public.referrals (
        referrer_user_id,
        referred_user_id,
        referral_code_id,
        status
    )
    VALUES (
        v_referrer_id,
        p_referred_user_id,
        v_code_id,
        'rewarded'
    );

    -- Award referrer reward.
    PERFORM public.award_loyalty_points(
        v_referrer_id,
        v_referrer_reward,
        'Referral Reward',
        'earn',
        p_referred_user_id
    );

    -- Award new-user reward.
    PERFORM public.award_loyalty_points(
        p_referred_user_id,
        v_referred_reward,
        'Sign up Reward',
        'earn',
        v_referrer_id
    );

    RETURN jsonb_build_object(
        'success', true
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;


ALTER FUNCTION "public"."process_referral_reward"("p_referred_user_id" "uuid", "p_referral_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_basket_items_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_basket_items_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_referral_codes_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_referral_codes_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_translation_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_translation_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_user_addresses_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_user_addresses_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_user_push_tokens_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_user_push_tokens_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_referral_code"("p_code" "text", "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_code_id UUID;
    v_referrer_id UUID;
    v_is_active BOOLEAN;
BEGIN
    -- Case-insensitive lookup for the code
    SELECT id, user_id, is_active INTO v_code_id, v_referrer_id, v_is_active
    FROM public.referral_codes
    WHERE LOWER(code) = LOWER(p_code);

    IF v_code_id IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'error', 'invalid_code');
    END IF;

    IF NOT v_is_active THEN
        RETURN jsonb_build_object('valid', false, 'error', 'inactive_code');
    END IF;

    -- Prevent users from referring themselves
    IF p_user_id IS NOT NULL AND v_referrer_id = p_user_id THEN
        RETURN jsonb_build_object('valid', false, 'error', 'self_referral');
    END IF;

    RETURN jsonb_build_object(
        'valid', true, 
        'code_id', v_code_id, 
        'referrer_id', v_referrer_id
    );
END;
$$;


ALTER FUNCTION "public"."validate_referral_code"("p_code" "text", "p_user_id" "uuid") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "setting_key" "text" NOT NULL,
    "setting_value" "text" NOT NULL,
    "value_type" "text" DEFAULT 'string'::"text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "app_settings_value_type_check" CHECK (("value_type" = ANY (ARRAY['string'::"text", 'number'::"text", 'boolean'::"text"])))
);


ALTER TABLE "public"."app_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."basket_items" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "quantity" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."basket_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "image_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "priority" smallint
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."category_translations" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "category_id" "uuid" NOT NULL,
    "language_code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."category_translations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."favorites" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "product_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."favorites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."loyalty_levels" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "minimum_points" integer NOT NULL,
    "icon" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."loyalty_levels" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."options" (
    "id" smallint NOT NULL,
    "name" "text",
    "value" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."options" OWNER TO "postgres";


ALTER TABLE "public"."options" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."options_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."order_items" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "order_id" "uuid",
    "product_id" "uuid",
    "quantity" integer NOT NULL,
    "price_at_purchase" numeric(10,2) NOT NULL,
    "product_image_url" "text",
    "product_name_snapshot" "text",
    "image_snapshot" "text",
    "name_snapshot" "text" DEFAULT ''::"text"
);


ALTER TABLE "public"."order_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_ratings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "order_id" "uuid",
    "overall_rating" integer,
    "quality_rating" integer,
    "freshness_rating" integer,
    "packaging_rating" integer,
    "delivery_rating" integer,
    "review_text" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "is_approved" boolean DEFAULT false,
    CONSTRAINT "order_ratings_delivery_rating_check" CHECK ((("delivery_rating" >= 1) AND ("delivery_rating" <= 5))),
    CONSTRAINT "order_ratings_freshness_rating_check" CHECK ((("freshness_rating" >= 1) AND ("freshness_rating" <= 5))),
    CONSTRAINT "order_ratings_overall_rating_check" CHECK ((("overall_rating" >= 1) AND ("overall_rating" <= 5))),
    CONSTRAINT "order_ratings_packaging_rating_check" CHECK ((("packaging_rating" >= 1) AND ("packaging_rating" <= 5))),
    CONSTRAINT "order_ratings_quality_rating_check" CHECK ((("quality_rating" >= 1) AND ("quality_rating" <= 5)))
);


ALTER TABLE "public"."order_ratings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_status_history" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "order_id" "uuid" NOT NULL,
    "status" "text" NOT NULL,
    "changed_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "order_status_history_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'confirmed'::"text", 'preparing'::"text", 'ready'::"text", 'out_for_delivery'::"text", 'delivered'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."order_status_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."points_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "amount" integer NOT NULL,
    "reason" "text" NOT NULL,
    "type" "text",
    "related_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "points_transactions_check" CHECK (((("type" = 'earn'::"text") AND ("amount" > 0)) OR (("type" = 'spend'::"text") AND ("amount" < 0)))),
    CONSTRAINT "points_transactions_type_check" CHECK (("type" = ANY (ARRAY['earn'::"text", 'spend'::"text"])))
);


ALTER TABLE "public"."points_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."popular_today" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "product_id" "uuid",
    "display_date" "date" DEFAULT CURRENT_DATE,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."popular_today" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."product_translations" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "product_id" "uuid" NOT NULL,
    "language_code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE ONLY "public"."product_translations" REPLICA IDENTITY FULL;


ALTER TABLE "public"."product_translations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "category_id" "uuid",
    "name" "text" NOT NULL,
    "description" "text",
    "price" numeric(10,2) NOT NULL,
    "image_url" "text",
    "available" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "tag" "text",
    "preparation_time" integer DEFAULT 20,
    "calories" integer DEFAULT 250,
    "is_organic" boolean DEFAULT false,
    "prep_time" integer DEFAULT 20,
    "weight" "text"
);


ALTER TABLE "public"."products" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "full_name" "text",
    "email" "text",
    "phone" "text",
    "avatar_url" "text",
    "language" "text" DEFAULT 'en'::"text",
    "role" "text" DEFAULT 'customer'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "is_active" boolean DEFAULT true,
    "current_streak" integer DEFAULT 0,
    "max_streak" integer DEFAULT 0,
    "last_login_date" "date",
    "last_order_date" "date",
    "fcm_token" "text",
    "notifications_new_order_enabled" boolean DEFAULT true NOT NULL,
    "preferred_language" "text" DEFAULT 'en'::"text" NOT NULL,
    CONSTRAINT "profiles_preferred_language_check" CHECK (("preferred_language" = ANY (ARRAY['en'::"text", 'tr'::"text", 'fa'::"text"]))),
    CONSTRAINT "profiles_role_check" CHECK (("role" = ANY (ARRAY['customer'::"text", 'admin'::"text", 'delivery'::"text", 'staff'::"text"])))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."promotions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "image_url" "text",
    "is_active" boolean DEFAULT true,
    "start_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "priority" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."promotions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."referral_codes" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."referral_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."referrals" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "referrer_user_id" "uuid" NOT NULL,
    "referred_user_id" "uuid" NOT NULL,
    "referral_code_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "qualifying_order_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "qualified_at" timestamp with time zone,
    "rewarded_at" timestamp with time zone,
    CONSTRAINT "referrals_no_self_referral" CHECK (("referrer_user_id" <> "referred_user_id")),
    CONSTRAINT "referrals_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'qualified'::"text", 'rewarded'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."referrals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reward_redemptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "reward_id" "uuid",
    "points_spent" integer NOT NULL,
    "status" "text" DEFAULT 'completed'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "reward_redemptions_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'completed'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."reward_redemptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."rewards" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "points_cost" integer NOT NULL,
    "image_url" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "rewards_points_cost_check" CHECK (("points_cost" > 0))
);


ALTER TABLE "public"."rewards" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_addresses" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "label" "text" NOT NULL,
    "address" "text",
    "city" "text",
    "district" "text",
    "street" "text",
    "building_number" "text",
    "floor" "text",
    "door_number" "text",
    "delivery_note" "text",
    "latitude" double precision,
    "longitude" double precision,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE ONLY "public"."user_addresses" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_addresses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_loyalty" (
    "user_id" "uuid" NOT NULL,
    "current_points" integer DEFAULT 0,
    "total_earned_points" integer DEFAULT 0,
    "loyalty_level" "text" DEFAULT 'Bronze'::"text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_loyalty_current_points_check" CHECK (("current_points" >= 0)),
    CONSTRAINT "user_loyalty_total_earned_points_check" CHECK (("total_earned_points" >= 0))
);


ALTER TABLE "public"."user_loyalty" OWNER TO "postgres";


ALTER TABLE ONLY "public"."app_settings"
    ADD CONSTRAINT "app_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_settings"
    ADD CONSTRAINT "app_settings_setting_key_key" UNIQUE ("setting_key");



ALTER TABLE ONLY "public"."basket_items"
    ADD CONSTRAINT "basket_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."basket_items"
    ADD CONSTRAINT "basket_items_user_id_product_id_key" UNIQUE ("user_id", "product_id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."category_translations"
    ADD CONSTRAINT "category_translations_category_id_language_code_key" UNIQUE ("category_id", "language_code");



ALTER TABLE ONLY "public"."category_translations"
    ADD CONSTRAINT "category_translations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_user_id_product_id_key" UNIQUE ("user_id", "product_id");



ALTER TABLE ONLY "public"."loyalty_levels"
    ADD CONSTRAINT "loyalty_levels_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."loyalty_levels"
    ADD CONSTRAINT "loyalty_levels_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."options"
    ADD CONSTRAINT "options_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."options"
    ADD CONSTRAINT "options_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_ratings"
    ADD CONSTRAINT "order_ratings_order_id_key" UNIQUE ("order_id");



ALTER TABLE ONLY "public"."order_ratings"
    ADD CONSTRAINT "order_ratings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_status_history"
    ADD CONSTRAINT "order_status_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."points_transactions"
    ADD CONSTRAINT "points_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."popular_today"
    ADD CONSTRAINT "popular_today_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."popular_today"
    ADD CONSTRAINT "popular_today_unique_product_date" UNIQUE ("product_id", "display_date");



ALTER TABLE ONLY "public"."product_translations"
    ADD CONSTRAINT "product_translations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_translations"
    ADD CONSTRAINT "product_translations_product_id_language_code_key" UNIQUE ("product_id", "language_code");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."promotions"
    ADD CONSTRAINT "promotions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referral_codes"
    ADD CONSTRAINT "referral_codes_code_unique" UNIQUE ("code");



ALTER TABLE ONLY "public"."referral_codes"
    ADD CONSTRAINT "referral_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referral_codes"
    ADD CONSTRAINT "referral_codes_user_unique" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_referred_user_id_unique" UNIQUE ("referred_user_id");



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_referred_user_unique" UNIQUE ("referred_user_id");



ALTER TABLE ONLY "public"."reward_redemptions"
    ADD CONSTRAINT "reward_redemptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."rewards"
    ADD CONSTRAINT "rewards_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_addresses"
    ADD CONSTRAINT "user_addresses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_addresses"
    ADD CONSTRAINT "user_addresses_user_label_unique" UNIQUE ("user_id", "label");



ALTER TABLE ONLY "public"."user_loyalty"
    ADD CONSTRAINT "user_loyalty_pkey" PRIMARY KEY ("user_id");



CREATE INDEX "category_translations_category_idx" ON "public"."category_translations" USING "btree" ("category_id");



CREATE INDEX "category_translations_language_idx" ON "public"."category_translations" USING "btree" ("language_code");



CREATE INDEX "idx_order_status_history_order_id" ON "public"."order_status_history" USING "btree" ("order_id");



CREATE INDEX "idx_referral_codes_user_id" ON "public"."referral_codes" USING "btree" ("user_id");



CREATE INDEX "idx_referrals_qualifying_order_id" ON "public"."referrals" USING "btree" ("qualifying_order_id");



CREATE INDEX "idx_referrals_referred_user_id" ON "public"."referrals" USING "btree" ("referred_user_id");



CREATE INDEX "idx_referrals_referrer_user_id" ON "public"."referrals" USING "btree" ("referrer_user_id");



CREATE INDEX "order_items_order_id_idx" ON "public"."order_items" USING "btree" ("order_id");



CREATE INDEX "orders_user_id_idx" ON "public"."orders" USING "btree" ("user_id");



CREATE UNIQUE INDEX "popular_today_product_date_idx" ON "public"."popular_today" USING "btree" ("product_id", "display_date");



CREATE INDEX "product_translations_language_idx" ON "public"."product_translations" USING "btree" ("language_code");



CREATE INDEX "product_translations_product_idx" ON "public"."product_translations" USING "btree" ("product_id");



CREATE INDEX "products_available_idx" ON "public"."products" USING "btree" ("available");



CREATE INDEX "products_category_idx" ON "public"."products" USING "btree" ("category_id");



CREATE INDEX "products_organic_idx" ON "public"."products" USING "btree" ("is_organic");



CREATE INDEX "products_tag_idx" ON "public"."products" USING "btree" ("tag");



CREATE INDEX "profiles_fcm_token_idx" ON "public"."profiles" USING "btree" ("fcm_token");



CREATE OR REPLACE TRIGGER "basket_items_updated_at" BEFORE UPDATE ON "public"."basket_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_basket_items_updated_at"();



CREATE OR REPLACE TRIGGER "category_translations_updated" BEFORE UPDATE ON "public"."category_translations" FOR EACH ROW EXECUTE FUNCTION "public"."update_translation_timestamp"();



CREATE OR REPLACE TRIGGER "notify-delivery-on-ready" AFTER UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://obealvlqkffozfigtobc.supabase.co/functions/v1/notify-delivery', 'POST', '{"Content-type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9iZWFsdmxxa2Zmb3pmaWd0b2JjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NTQ4NTEzOCwiZXhwIjoyMTAxMDYxMTM4fQ.smW7z_M2POmZUnpsRufplCWwyczimu186_D0k4udpUI"}', '{}', '5000');



CREATE OR REPLACE TRIGGER "notify-staff-on-new-order" AFTER INSERT ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://obealvlqkffozfigtobc.supabase.co/functions/v1/notify-staff', 'POST', '{"Content-type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9iZWFsdmxxa2Zmb3pmaWd0b2JjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NTQ4NTEzOCwiZXhwIjoyMTAxMDYxMTM4fQ.smW7z_M2POmZUnpsRufplCWwyczimu186_D0k4udpUI"}', '{"order_id":"{{NEW.id}}","order_number":"{{NEW.order_number}}"}', '5000');



CREATE OR REPLACE TRIGGER "product_translations_updated" BEFORE UPDATE ON "public"."product_translations" FOR EACH ROW EXECUTE FUNCTION "public"."update_translation_timestamp"();



CREATE OR REPLACE TRIGGER "referral_codes_updated_at" BEFORE UPDATE ON "public"."referral_codes" FOR EACH ROW EXECUTE FUNCTION "public"."update_referral_codes_updated_at"();



CREATE OR REPLACE TRIGGER "trg_clamp_user_loyalty_points" BEFORE INSERT OR UPDATE ON "public"."user_loyalty" FOR EACH ROW EXECUTE FUNCTION "public"."clamp_user_loyalty_points"();



CREATE OR REPLACE TRIGGER "trigger_delivery_assignment_notification" AFTER UPDATE ON "public"."orders" FOR EACH ROW WHEN ((("old"."assigned_delivery_person" IS DISTINCT FROM "new"."assigned_delivery_person") AND ("new"."assigned_delivery_person" IS NOT NULL))) EXECUTE FUNCTION "public"."notify_delivery_assignment"();



CREATE OR REPLACE TRIGGER "trigger_generate_referral_code" AFTER INSERT ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."on_profile_created_generate_referral"();



CREATE OR REPLACE TRIGGER "trigger_referral_on_delivery" AFTER UPDATE OF "status" ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."on_order_status_change_referral"();



ALTER TABLE ONLY "public"."basket_items"
    ADD CONSTRAINT "basket_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."basket_items"
    ADD CONSTRAINT "basket_items_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."category_translations"
    ADD CONSTRAINT "category_translations_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_ratings"
    ADD CONSTRAINT "order_ratings_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_ratings"
    ADD CONSTRAINT "order_ratings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_status_history"
    ADD CONSTRAINT "order_status_history_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."order_status_history"
    ADD CONSTRAINT "order_status_history_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_assigned_delivery_person_fkey" FOREIGN KEY ("assigned_delivery_person") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_user_id_fkey1" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."points_transactions"
    ADD CONSTRAINT "points_transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."popular_today"
    ADD CONSTRAINT "popular_today_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_translations"
    ADD CONSTRAINT "product_translations_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referral_codes"
    ADD CONSTRAINT "referral_codes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_qualifying_order_id_fkey" FOREIGN KEY ("qualifying_order_id") REFERENCES "public"."orders"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_referral_code_id_fkey" FOREIGN KEY ("referral_code_id") REFERENCES "public"."referral_codes"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_referred_user_id_fkey" FOREIGN KEY ("referred_user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_referrer_user_id_fkey" FOREIGN KEY ("referrer_user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reward_redemptions"
    ADD CONSTRAINT "reward_redemptions_reward_id_fkey" FOREIGN KEY ("reward_id") REFERENCES "public"."rewards"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reward_redemptions"
    ADD CONSTRAINT "reward_redemptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_addresses"
    ADD CONSTRAINT "user_addresses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_loyalty"
    ADD CONSTRAINT "user_loyalty_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Admins can manage categories" ON "public"."categories" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"text"));



CREATE POLICY "Admins can manage options" ON "public"."options" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Admins can manage product translations" ON "public"."product_translations" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"text"));



CREATE POLICY "Admins can manage products" ON "public"."products" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"text")) WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"text"));



CREATE POLICY "Admins can update all profiles" ON "public"."profiles" FOR UPDATE USING ((( SELECT "profiles_1"."role"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"())) = 'admin'::"text")) WITH CHECK ((( SELECT "profiles_1"."role"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"())) = 'admin'::"text"));



CREATE POLICY "Admins manage loyalty levels" ON "public"."loyalty_levels" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Admins manage promotions" ON "public"."promotions" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Admins manage rewards" ON "public"."rewards" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Admins manage settings" ON "public"."app_settings" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Allow authenticated users to insert popular today" ON "public"."popular_today" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Allow authenticated users to read popular today" ON "public"."popular_today" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow public insert popular today" ON "public"."popular_today" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "Allow public read access" ON "public"."options" FOR SELECT USING (true);



CREATE POLICY "Allow public read access for categories" ON "public"."categories" FOR SELECT USING (true);



CREATE POLICY "Allow public read access for category_translations" ON "public"."category_translations" FOR SELECT USING (true);



CREATE POLICY "Allow public read access for product_translations" ON "public"."product_translations" FOR SELECT USING (true);



CREATE POLICY "Allow public read access for products" ON "public"."products" FOR SELECT USING (true);



CREATE POLICY "Allow public read access on categories" ON "public"."categories" FOR SELECT USING (true);



CREATE POLICY "Allow public read access on category_translations" ON "public"."category_translations" FOR SELECT USING (true);



CREATE POLICY "Allow public read popular today" ON "public"."popular_today" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Anyone can read category translations" ON "public"."category_translations" FOR SELECT USING (true);



CREATE POLICY "Anyone can view categories" ON "public"."categories" FOR SELECT USING (true);



CREATE POLICY "Anyone can view category translations" ON "public"."category_translations" FOR SELECT USING (true);



CREATE POLICY "Anyone can view product translations" ON "public"."product_translations" FOR SELECT USING (true);



CREATE POLICY "Anyone can view products" ON "public"."products" FOR SELECT USING (true);



CREATE POLICY "Authorized roles can insert status history" ON "public"."order_status_history" FOR INSERT WITH CHECK (true);



CREATE POLICY "Enable read access for all users" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Order items are viewable by authorized" ON "public"."order_items" FOR SELECT USING (true);



CREATE POLICY "Orders are viewable by authorized roles" ON "public"."orders" FOR SELECT USING ((("auth"."uid"() = "user_id") OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND (("profiles"."role" = 'admin'::"text") OR ("profiles"."role" = 'staff'::"text") OR ("profiles"."role" = 'delivery'::"text")))))));



CREATE POLICY "Orders can be updated by authorized roles" ON "public"."orders" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND (("profiles"."role" = 'admin'::"text") OR ("profiles"."role" = 'staff'::"text") OR ("profiles"."role" = 'delivery'::"text"))))));



CREATE POLICY "Profiles are viewable by everyone" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Public can read product translations" ON "public"."product_translations" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Public profiles are viewable by everyone" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Staff manage order status history" ON "public"."order_status_history" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'staff'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'staff'::"text"]))))));



CREATE POLICY "Status history is viewable by authorized" ON "public"."order_status_history" FOR SELECT USING (true);



CREATE POLICY "User deletes own order ratings" ON "public"."order_ratings" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "User inserts own order rating" ON "public"."order_ratings" FOR INSERT TO "authenticated" WITH CHECK ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_ratings"."order_id") AND ("o"."user_id" = "auth"."uid"()))))));



CREATE POLICY "User selects own order ratings" ON "public"."order_ratings" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "User updates own order ratings" ON "public"."order_ratings" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can create their order items" ON "public"."order_items" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."orders"
  WHERE (("orders"."id" = "order_items"."order_id") AND ("orders"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can delete own addresses" ON "public"."user_addresses" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own addresses" ON "public"."user_addresses" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert their own profile" ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can manage own profile" ON "public"."profiles" TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can update own addresses" ON "public"."user_addresses" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own profile" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can update their own profile" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view own addresses" ON "public"."user_addresses" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own profile" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view their order items" ON "public"."order_items" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."orders"
  WHERE (("orders"."id" = "order_items"."order_id") AND ("orders"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users create orders" ON "public"."orders" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users create own order items" ON "public"."order_items" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."orders"
  WHERE (("orders"."id" = "order_items"."order_id") AND ("orders"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users edit own ratings" ON "public"."order_ratings" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage favorites" ON "public"."favorites" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own basket" ON "public"."basket_items" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users rate own orders" ON "public"."order_ratings" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users update own referral code" ON "public"."referral_codes" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users view own loyalty" ON "public"."user_loyalty" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users view own order items" ON "public"."order_items" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."orders"
  WHERE (("orders"."id" = "order_items"."order_id") AND ("orders"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users view own order status history" ON "public"."order_status_history" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."orders"
  WHERE (("orders"."id" = "order_status_history"."order_id") AND ("orders"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users view own orders" ON "public"."orders" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users view own referral code" ON "public"."referral_codes" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users view own transactions" ON "public"."points_transactions" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users view their referrals" ON "public"."referrals" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "referrer_user_id") OR (( SELECT "auth"."uid"() AS "uid") = "referred_user_id")));



CREATE POLICY "View active promotions" ON "public"."promotions" FOR SELECT USING ((("is_active" = true) AND (("start_date" IS NULL) OR ("start_date" <= "now"())) AND (("end_date" IS NULL) OR ("end_date" >= "now"()))));



CREATE POLICY "View active rewards" ON "public"."rewards" FOR SELECT USING (("is_active" = true));



CREATE POLICY "View app settings" ON "public"."app_settings" FOR SELECT USING (true);



CREATE POLICY "View loyalty levels" ON "public"."loyalty_levels" FOR SELECT USING (true);



ALTER TABLE "public"."app_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."basket_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "block direct inserts" ON "public"."order_status_history" FOR INSERT TO "authenticated" WITH CHECK (false);



ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."category_translations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "courier read history" ON "public"."order_status_history" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_status_history"."order_id") AND ("o"."assigned_delivery_person" = "auth"."uid"()) AND (EXISTS ( SELECT 1
           FROM "public"."profiles" "p"
          WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'delivery'::"text"))))))));



CREATE POLICY "courier read orders" ON "public"."orders" FOR SELECT TO "authenticated" USING ((("assigned_delivery_person" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'delivery'::"text"))))));



CREATE POLICY "customer read history" ON "public"."order_status_history" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."orders" "o"
  WHERE (("o"."id" = "order_status_history"."order_id") AND ("o"."user_id" = "auth"."uid"())))));



CREATE POLICY "customer read orders" ON "public"."orders" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."favorites" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."loyalty_levels" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."options" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."order_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."order_ratings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."order_status_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."orders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."points_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."popular_today" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."product_translations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."promotions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."referral_codes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."referrals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reward_redemptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rewards" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_addresses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_loyalty" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."categories";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."options";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."order_status_history";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."orders";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."products";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."profiles";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."user_loyalty";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































GRANT ALL ON FUNCTION "public"."confirm_delivery"("p_order_id" "uuid", "p_pin" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."place_order_atomic"("p_address_snapshot" "jsonb", "p_payment_method" "text", "p_total_price" numeric, "p_estimated_prep_time" integer, "p_items" "jsonb") TO "authenticated";



GRANT ALL ON TABLE "public"."orders" TO "anon";
GRANT ALL ON TABLE "public"."orders" TO "authenticated";
GRANT ALL ON TABLE "public"."orders" TO "service_role";


















GRANT ALL ON TABLE "public"."app_settings" TO "anon";
GRANT ALL ON TABLE "public"."app_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."app_settings" TO "service_role";



GRANT ALL ON TABLE "public"."basket_items" TO "anon";
GRANT ALL ON TABLE "public"."basket_items" TO "authenticated";
GRANT ALL ON TABLE "public"."basket_items" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."category_translations" TO "anon";
GRANT ALL ON TABLE "public"."category_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."category_translations" TO "service_role";



GRANT ALL ON TABLE "public"."favorites" TO "anon";
GRANT ALL ON TABLE "public"."favorites" TO "authenticated";
GRANT ALL ON TABLE "public"."favorites" TO "service_role";



GRANT ALL ON TABLE "public"."loyalty_levels" TO "anon";
GRANT ALL ON TABLE "public"."loyalty_levels" TO "authenticated";
GRANT ALL ON TABLE "public"."loyalty_levels" TO "service_role";



GRANT ALL ON TABLE "public"."options" TO "anon";
GRANT ALL ON TABLE "public"."options" TO "authenticated";
GRANT ALL ON TABLE "public"."options" TO "service_role";



GRANT ALL ON SEQUENCE "public"."options_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."options_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."options_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."order_items" TO "anon";
GRANT ALL ON TABLE "public"."order_items" TO "authenticated";
GRANT ALL ON TABLE "public"."order_items" TO "service_role";



GRANT ALL ON TABLE "public"."order_ratings" TO "anon";
GRANT ALL ON TABLE "public"."order_ratings" TO "authenticated";
GRANT ALL ON TABLE "public"."order_ratings" TO "service_role";



GRANT ALL ON TABLE "public"."order_status_history" TO "anon";
GRANT ALL ON TABLE "public"."order_status_history" TO "authenticated";
GRANT ALL ON TABLE "public"."order_status_history" TO "service_role";



GRANT ALL ON TABLE "public"."points_transactions" TO "anon";
GRANT ALL ON TABLE "public"."points_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."points_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."popular_today" TO "anon";
GRANT ALL ON TABLE "public"."popular_today" TO "authenticated";
GRANT ALL ON TABLE "public"."popular_today" TO "service_role";



GRANT ALL ON TABLE "public"."product_translations" TO "anon";
GRANT ALL ON TABLE "public"."product_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."product_translations" TO "service_role";



GRANT ALL ON TABLE "public"."products" TO "anon";
GRANT ALL ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."promotions" TO "anon";
GRANT ALL ON TABLE "public"."promotions" TO "authenticated";
GRANT ALL ON TABLE "public"."promotions" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."referral_codes" TO "anon";
GRANT ALL ON TABLE "public"."referral_codes" TO "authenticated";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."referral_codes" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."referrals" TO "anon";
GRANT ALL ON TABLE "public"."referrals" TO "authenticated";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."referrals" TO "service_role";



GRANT ALL ON TABLE "public"."reward_redemptions" TO "anon";
GRANT ALL ON TABLE "public"."reward_redemptions" TO "authenticated";
GRANT ALL ON TABLE "public"."reward_redemptions" TO "service_role";



GRANT ALL ON TABLE "public"."rewards" TO "anon";
GRANT ALL ON TABLE "public"."rewards" TO "authenticated";
GRANT ALL ON TABLE "public"."rewards" TO "service_role";



GRANT ALL ON TABLE "public"."user_addresses" TO "anon";
GRANT ALL ON TABLE "public"."user_addresses" TO "authenticated";
GRANT ALL ON TABLE "public"."user_addresses" TO "service_role";



GRANT ALL ON TABLE "public"."user_loyalty" TO "anon";
GRANT ALL ON TABLE "public"."user_loyalty" TO "authenticated";
GRANT ALL ON TABLE "public"."user_loyalty" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLES TO "service_role";



































