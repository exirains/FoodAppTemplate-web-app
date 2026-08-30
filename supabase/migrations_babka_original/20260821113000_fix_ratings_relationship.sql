-- Migration to fix relationships for order_ratings table
DO $$
BEGIN
    -- 1. Ensure user_id is a foreign key to profiles
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'order_ratings' AND constraint_type = 'FOREIGN KEY'
        AND constraint_name = 'order_ratings_user_id_fkey'
    ) THEN
        ALTER TABLE public.order_ratings
        ADD CONSTRAINT order_ratings_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES public.profiles(id)
        ON DELETE CASCADE;
    END IF;

    -- 2. Ensure order_id is a foreign key to orders
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'order_ratings' AND constraint_type = 'FOREIGN KEY'
        AND constraint_name = 'order_ratings_order_id_fkey'
    ) THEN
        ALTER TABLE public.order_ratings
        ADD CONSTRAINT order_ratings_order_id_fkey
        FOREIGN KEY (order_id)
        REFERENCES public.orders(id)
        ON DELETE CASCADE;
    END IF;
END $$;
