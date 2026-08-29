-- 1. Ensure one user can only be referred once
-- This constraint enforces the "one new account = one successful referral" rule
ALTER TABLE public.referrals
ADD CONSTRAINT referrals_referred_user_id_unique UNIQUE (referred_user_id);

-- 2. Function to validate a referral code safely
-- This can be called from the UI before signup to provide instant feedback
CREATE OR REPLACE FUNCTION public.validate_referral_code(
    p_code TEXT,
    p_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_code_id UUID;
    v_referrer_id UUID;
    v_is_active BOOLEAN;
BEGIN
    SELECT id, user_id, is_active INTO v_code_id, v_referrer_id, v_is_active
    FROM public.referral_codes
    WHERE LOWER(code) = LOWER(p_code);

    IF v_code_id IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'error', 'invalid_code');
    END IF;

    IF NOT v_is_active THEN
        RETURN jsonb_build_object('valid', false, 'error', 'inactive_code');
    END IF;

    -- p_user_id might be null during validation if the user hasn't signed up yet
    IF p_user_id IS NOT NULL AND v_referrer_id = p_user_id THEN
        RETURN jsonb_build_object('valid', false, 'error', 'self_referral');
    END IF;

    RETURN jsonb_build_object(
        'valid', true,
        'code_id', v_code_id,
        'referrer_id', v_referrer_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Atomic processing of referral reward
-- This function handles the entire referral lifecycle in a single transaction
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
    -- The UNIQUE constraint also protects this, but an explicit check provides a cleaner error
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
    -- This allows admins to change reward values without updating code
    SELECT COALESCE((SELECT (value::INT) FROM public.options WHERE name = 'referral_reward_referrer'), 50) INTO v_referrer_reward;
    SELECT COALESCE((SELECT (value::INT) FROM public.options WHERE name = 'referral_reward_referred'), 25) INTO v_referred_reward;

    -- Atomic Transactional Block
    -- 1. Create the referral relationship
    INSERT INTO public.referrals (
        referrer_user_id,
        referred_user_id,
        referral_code_id,
        status
    ) VALUES (
        v_referrer_id,
        p_referred_user_id,
        v_code_id,
        'rewarded'
    );

    -- 2. Award points to the referrer
    -- We use the existing award_loyalty_points RPC for point management
    PERFORM public.award_loyalty_points(
        v_referrer_id,
        v_referrer_reward,
        'Referral Reward',
        'earn',
        p_referred_user_id::TEXT
    );

    -- 3. Award points to the referred user (new user)
    PERFORM public.award_loyalty_points(
        p_referred_user_id,
        v_referred_reward,
        'Sign up Reward',
        'earn',
        v_referrer_id::TEXT
    );

    RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
    -- If any step fails (e.g. UNIQUE constraint violation elsewhere), the whole transaction rolls back
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
