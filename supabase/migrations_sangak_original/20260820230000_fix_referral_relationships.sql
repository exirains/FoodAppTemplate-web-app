-- Migration to fix missing relationships for referrals table
-- This allows Supabase to correctly join referrals with profiles for statistics
DO $$
BEGIN
    -- 1. Ensure referred_user_id is a foreign key to profiles
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'referrals' AND constraint_type = 'FOREIGN KEY'
        AND constraint_name = 'referrals_referred_user_id_fkey'
    ) THEN
        -- Drop existing if it exists with a different name to avoid confusion
        -- ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS referrals_referred_user_id_fkey;

        ALTER TABLE public.referrals
        ADD CONSTRAINT referrals_referred_user_id_fkey
        FOREIGN KEY (referred_user_id)
        REFERENCES public.profiles(id)
        ON DELETE CASCADE;
    END IF;

    -- 2. Ensure referrer_user_id is a foreign key to profiles
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'referrals' AND constraint_type = 'FOREIGN KEY'
        AND constraint_name = 'referrals_referrer_user_id_fkey'
    ) THEN
        ALTER TABLE public.referrals
        ADD CONSTRAINT referrals_referrer_user_id_fkey
        FOREIGN KEY (referrer_user_id)
        REFERENCES public.profiles(id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- 3. Fix award_loyalty_points to allow 0 amount (skipping transaction record)
-- This avoids check constraint violations during account initialization
CREATE OR REPLACE FUNCTION public.award_loyalty_points(
    p_user_id UUID,
    p_amount INT,
    p_reason TEXT,
    p_type TEXT,
    p_related_id TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_current_points INT;
BEGIN
    -- Check balance if spending
    IF p_amount < 0 THEN
        SELECT current_points INTO v_current_points
        FROM public.user_loyalty
        WHERE user_id = p_user_id;

        IF v_current_points IS NULL OR v_current_points + p_amount < 0 THEN
            RAISE EXCEPTION 'Insufficient points balance';
        END IF;
    END IF;

    -- Only insert transaction record if amount is not zero
    -- This handles "Account Initialization" without violating amount > 0 constraints
    IF p_amount <> 0 THEN
        INSERT INTO public.points_transactions (
            user_id,
            amount,
            reason,
            type,
            related_id
        ) VALUES (
            p_user_id,
            p_amount,
            p_reason,
            p_type,
            p_related_id
        );
    END IF;

    -- Update user_loyalty balance (Upsert logic)
    INSERT INTO public.user_loyalty (user_id, current_points, total_earned_points, updated_at)
    VALUES (
        p_user_id,
        GREATEST(0, p_amount),
        GREATEST(0, p_amount),
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE
    SET
        current_points = GREATEST(0, public.user_loyalty.current_points + p_amount),
        total_earned_points = public.user_loyalty.total_earned_points + GREATEST(0, p_amount),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
