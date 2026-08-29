-- 1. Fix award_loyalty_points RPC to use 'amount' column
-- This ensures that point awarding logic correctly references the schema
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
    -- Insert transaction record using the correct 'amount' column
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

    -- Update user_loyalty balance
    -- We assume user_loyalty uses current_points and total_earned_points based on our models
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

-- 2. Audit existing referrals logic if any other functions use 'points'
-- (Based on audit, 'process_referral_reward' already calls 'award_loyalty_points' correctly)
