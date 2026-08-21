-- Migration: Add notification preferences and language to profiles
-- 1. Add columns with default values for existing and new users
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS notifications_new_order_enabled BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS preferred_language TEXT NOT NULL DEFAULT 'en'
CHECK (preferred_language IN ('en', 'tr', 'fa'));

-- 2. Function to notify staff/admin team via Edge Function
-- Compatible with standard Supabase Webhook payload format
CREATE OR REPLACE FUNCTION public.notify_staff_new_order()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger on new order creation
    PERFORM net.http_post(
        url := 'https://' || (SELECT value FROM public.options WHERE name = 'supabase_project_ref') || '.supabase.co/functions/v1/notify-staff',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || (SELECT value FROM public.options WHERE name = 'supabase_service_role_key')
        ),
        body := jsonb_build_object(
            'type', TG_OP,
            'table', TG_TABLE_NAME,
            'record', row_to_json(NEW),
            'schema', TG_TABLE_SCHEMA
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger on Orders (INSERT only)
DROP TRIGGER IF EXISTS trigger_new_order_staff_notification ON public.orders;

CREATE TRIGGER trigger_new_order_staff_notification
AFTER INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.notify_staff_new_order();
