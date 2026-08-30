-- Fix Delivery Confirmation RPC with robust authorization and atomicity
CREATE OR REPLACE FUNCTION public.confirm_delivery(
    p_order_id UUID,
    p_pin TEXT
)
RETURNS VOID AS $$
DECLARE
    v_assigned_id UUID;
    v_order_status TEXT;
    v_delivery_code TEXT;
    v_user_role TEXT;
BEGIN
    -- 1. Get current user role from profiles
    SELECT role INTO v_user_role FROM public.profiles WHERE id = auth.uid();

    -- 2. Fetch order details for verification
    SELECT assigned_delivery_person, status, delivery_code
    INTO v_assigned_id, v_order_status, v_delivery_code
    FROM public.orders
    WHERE id = p_order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found';
    END IF;

    -- 3. Authorization Check
    -- Source of truth is auth.uid()
    -- Allow admins OR the specifically assigned delivery person
    IF COALESCE(v_user_role, '') != 'admin' AND (v_assigned_id IS NULL OR v_assigned_id != auth.uid()) THEN
        RAISE EXCEPTION 'Not authorized to confirm this delivery';
    END IF;

    -- 4. Status Check
    IF v_order_status != 'out_for_delivery' THEN
        RAISE EXCEPTION 'Order is not in delivery status';
    END IF;

    -- 5. PIN Check
    -- Handles null/empty mismatch correctly
    IF v_delivery_code IS DISTINCT FROM p_pin THEN
        RAISE EXCEPTION 'Invalid verification code';
    END IF;

    -- 6. Atomic Update
    UPDATE public.orders
    SET
        status = 'delivered',
        updated_at = NOW()
    WHERE id = p_order_id;

    -- 7. Record History
    INSERT INTO public.order_status_history (order_id, status, changed_by)
    VALUES (p_order_id, 'delivered', auth.uid());

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
