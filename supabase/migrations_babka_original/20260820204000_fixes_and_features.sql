-- 1. Fix Order Rating RLS Error
-- Allow authenticated users to insert/upsert ratings for their orders
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'order_ratings' AND policyname = 'Users can insert own ratings'
    ) THEN
        CREATE POLICY "Users can insert own ratings"
        ON public.order_ratings
        FOR INSERT
        WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'order_ratings' AND policyname = 'Users can update own ratings'
    ) THEN
        CREATE POLICY "Users can update own ratings"
        ON public.order_ratings
        FOR UPDATE
        USING (auth.uid() = user_id);
    END IF;
END
$$;

-- 2. Fix Loyalty Reward Redemption RPC
-- Update award_loyalty_points to correctly handle negative amounts for spending
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

    -- Insert transaction record
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

-- 3. Add Weight field to Products
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS weight TEXT;

-- 4. Add Points Earning Rule to Options
-- Default to 'total_spent' (1 TL = 1 Point) as requested to fix the bug
INSERT INTO public.options (name, value)
VALUES ('points_earning_rule', 'total_spent')
ON CONFLICT (name) DO NOTHING;
