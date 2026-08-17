-- 1. Function to notify delivery team via Edge Function
-- Compatible with standard Supabase Webhook payload format
-- Single source of truth: profiles.fcm_token
CREATE OR REPLACE FUNCTION public.notify_delivery_team()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger when status changes to 'ready'
    IF NEW.status = 'ready' AND (OLD.status IS NULL OR OLD.status <> 'ready') THEN
        PERFORM net.http_post(
            url := 'https://' || (SELECT value FROM public.options WHERE name = 'supabase_project_ref') || '.supabase.co/functions/v1/notify-delivery',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || (SELECT value FROM public.options WHERE name = 'supabase_service_role_key')
            ),
            body := jsonb_build_object(
                'type', TG_OP,
                'table', TG_TABLE_NAME,
                'record', row_to_json(NEW),
                'old_record', row_to_json(OLD),
                'schema', TG_TABLE_SCHEMA
            )
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Trigger on Orders
-- Note: 'net' extension must be enabled in Supabase for this to work
DROP TRIGGER IF EXISTS trigger_order_ready_notification ON public.orders;

CREATE TRIGGER trigger_order_ready_notification
AFTER UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.notify_delivery_team();
