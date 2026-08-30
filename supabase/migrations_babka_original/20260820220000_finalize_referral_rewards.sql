-- 1. Ensure rewarded_at column exists in referrals table
ALTER TABLE public.referrals ADD COLUMN IF NOT EXISTS rewarded_at TIMESTAMPTZ;

-- 2. Update existing rewarded referrals to have a rewarded_at timestamp
UPDATE public.referrals
SET rewarded_at = created_at
WHERE status = 'rewarded' AND rewarded_at IS NULL;

-- 3. Update the referral processing RPC to populate rewarded_at atomically
CREATE OR REPLACE FUNCTION public.process_referral_reward(
    p_referred_user_id UUID,
    p_referral_code TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_validation JSONB;
    v_referrer_id UUID;
    v_code_id UUID;
    v_referrer_reward INT;
    v_referred_reward INT;
BEGIN
    -- Check if user already has a referral record (Idempotency check)
    -- The UNIQUE constraint on referred_user_id also protects this at the schema level
    IF EXISTS (SELECT 1 FROM public.referrals WHERE referred_user_id = p_referred_user_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'already_referred');
    END IF;

    -- Validate the code
    v_validation := public.validate_referral_code(p_referral_code, p_referred_user_id);
    IF NOT (v_validation->>'valid')::BOOLEAN THEN
        RETURN v_validation;
    END IF;

    v_referrer_id := (v_validation->>'referrer_id')::UUID;
    v_code_id := (v_validation->>'code_id')::UUID;

    -- Get reward values from options table with fallback to defaults
    -- These keys allow admins to adjust rewards without changing code
    SELECT COALESCE((SELECT (value::INT) FROM public.options WHERE name = 'referral_reward_referrer'), 50) INTO v_referrer_reward;
    SELECT COALESCE((SELECT (value::INT) FROM public.options WHERE name = 'referral_reward_referred'), 25) INTO v_referred_reward;

    -- Atomic Transactional Block
    -- 1. Create the referral relationship and record the reward timestamp
    INSERT INTO public.referrals (
        referrer_user_id,
        referred_user_id,
        referral_code_id,
        status,
        rewarded_at
    ) VALUES (
        v_referrer_id,
        p_referred_user_id,
        v_code_id,
        'rewarded',
        NOW()
    );

    -- 2. Award points to the referrer
    -- Pass the new user's ID as related_id for easy auditing/tracking
    PERFORM public.award_loyalty_points(
        v_referrer_id,
        v_referrer_reward,
        'Referral Reward',
        'earn',
        p_referred_user_id::TEXT
    );

    -- 3. Award points to the referred user (the brand new account)
    -- Pass the referrer's ID as related_id
    PERFORM public.award_loyalty_points(
        p_referred_user_id,
        v_referred_reward,
        'Sign up Reward',
        'earn',
        v_referrer_id::TEXT
    );

    RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
    -- If any step fails, the whole operation rolls back to keep data consistent
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
