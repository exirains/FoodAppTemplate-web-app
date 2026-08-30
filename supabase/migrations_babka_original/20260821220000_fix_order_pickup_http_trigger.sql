-- Fix PostgrestException (Code 42883) by modernizing the HTTP trigger
-- This replaces the legacy supabase_functions.http_request with net.http_post

CREATE OR REPLACE FUNCTION public.notify_delivery_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_project_ref TEXT;
    v_service_role_key TEXT;
BEGIN
    -- 1. Get configuration dynamically from options table
    SELECT value INTO v_project_ref FROM public.options WHERE name = 'supabase_project_ref';
    SELECT value INTO v_service_role_key FROM public.options WHERE name = 'supabase_service_role_key';

    -- 2. Fallback to hardcoded project ref if option not found (based on your current trigger)
    IF v_project_ref IS NULL THEN
        v_project_ref := 'obealvlqkffozfigtobc';
    END IF;

    -- 3. Perform asynchronous HTTP call using pg_net
    -- Explicitly cast all arguments to ensure no type mismatch (Fixes Code 42883)
    BEGIN
        PERFORM net.http_post(
            url := ('https://' || v_project_ref || '.supabase.co/functions/v1/notify-delivery')::text,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || COALESCE(v_service_role_key, 'YOUR_EXISTING_WORKING_JWT')
            ),
            body := jsonb_build_object(
                'type', 'delivery_assignment'::text,
                'table', 'orders'::text,
                'record', row_to_json(NEW),
                'old_record', row_to_json(OLD),
                'schema', 'public'::text
            )
        );
    EXCEPTION WHEN OTHERS THEN
        -- Fault Tolerance: Ensure the database transaction (order pickup)
        -- succeeds even if the notification fails.
        RAISE WARNING 'Failed to trigger delivery assignment notification: %', SQLERRM;
    END;

    RETURN NEW;
END;
$$;

-- Ensure the trigger is correctly applied
DROP TRIGGER IF EXISTS trigger_delivery_assignment_notification ON public.orders;

CREATE TRIGGER trigger_delivery_assignment_notification
AFTER UPDATE ON public.orders
FOR EACH ROW
WHEN (
    OLD.assigned_delivery_person IS DISTINCT FROM NEW.assigned_delivery_person
    AND NEW.assigned_delivery_person IS NOT NULL
)
EXECUTE FUNCTION public.notify_delivery_assignment();
