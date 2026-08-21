-- 1. Function to notify a specific driver when an order is assigned to them
CREATE OR REPLACE FUNCTION public.notify_delivery_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM supabase_functions.http_request(
        'https://obealvlqkffozfigtobc.supabase.co/functions/v1/notify-delivery',
        'POST',
        '{"Content-type":"application/json","Authorization":"Bearer YOUR_EXISTING_WORKING_JWT"}',
        jsonb_build_object(
            'type', 'delivery_assignment',
            'table', 'orders',
            'record', row_to_json(NEW),
            'old_record', row_to_json(OLD),
            'schema', 'public'
        )::text,
        '5000'
    );

    RETURN NEW;
END;
$$;

-- 2. Trigger on Orders
DROP TRIGGER IF EXISTS trigger_delivery_assignment_notification ON public.orders;

CREATE TRIGGER trigger_delivery_assignment_notification
AFTER UPDATE ON public.orders
FOR EACH ROW
WHEN (
    OLD.assigned_delivery_person IS DISTINCT FROM NEW.assigned_delivery_person
    AND NEW.assigned_delivery_person IS NOT NULL
)
EXECUTE FUNCTION public.notify_delivery_assignment();
