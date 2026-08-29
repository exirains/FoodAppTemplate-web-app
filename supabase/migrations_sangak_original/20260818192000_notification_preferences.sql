-- 1. Add notification preference and language columns to profiles table
-- These columns are used by the notify-staff Edge Function for personalization.
-- We use safely-wrapped statements to avoid breaking existing infrastructure.

DO $$
BEGIN
    -- Add notifications_new_order_enabled if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'notifications_new_order_enabled'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN notifications_new_order_enabled BOOLEAN NOT NULL DEFAULT TRUE;
    END IF;

    -- Add preferred_language if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'preferred_language'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN preferred_language TEXT NOT NULL DEFAULT 'en';

        -- Add the check constraint separately to be safe
        ALTER TABLE public.profiles ADD CONSTRAINT preferred_language_check CHECK (preferred_language IN ('en', 'tr', 'fa'));
    END IF;
END
$$;

-- 2. Ensure RLS policies allow users to update their own notification preferences
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'profiles' AND policyname = 'Users can update own notification preferences'
    ) THEN
        CREATE POLICY "Users can update own notification preferences"
        ON public.profiles
        FOR UPDATE
        USING (auth.uid() = id)
        WITH CHECK (auth.uid() = id);
    END IF;
END
$$;

-- Note: We are NOT recreating the notify_staff_new_order() function or trigger here
-- to avoid duplication if they were already manually or previously created and functional.
-- If they are missing, they should be added via a separate infrastructure sync.
