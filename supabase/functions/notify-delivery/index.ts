import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { JWT } from "https://esm.sh/google-auth-library@8.7.0"

interface WebhookPayload {
  type: string; // e.g. 'INSERT', 'UPDATE', 'delivery_assignment'
  table: string;
  record: any;
  old_record: any;
  schema: string;
}

const getLocalizedContent = (type: string, lang: string, orderNumber: string) => {
  const translations: any = {
    new_delivery_order: {
      en: { title: '🛵 New Sangak Order!', body: `Order #${orderNumber} is ready!` },
      tr: { title: '🛵 Yeni Sangak Siparişi!', body: `Sipariş #${orderNumber} hazır!` },
      fa: { title: '🛵 سفارش جدید سنگک!', body: `سفارش #${orderNumber} آماده است!` },
    },
    delivery_assignment: {
      en: { title: '🚚 New Delivery Assigned', body: `Order #${orderNumber} has been assigned to you.` },
      tr: { title: '🚚 Yeni Teslimat Atandı', body: `Sipariş #${orderNumber} size atandı.` },
      fa: { title: '🚚 ارسال جدید به شما واگذار شد', body: `سفارش #${orderNumber} به شما واگذار شد.` },
    }
  }

  const isAssignment = type === 'delivery_assignment';
  const typeKey = isAssignment ? 'delivery_assignment' : 'new_delivery_order';
  const content = translations[typeKey][lang] || translations[typeKey]['en'];
  return content;
}

serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json()
    const { record, old_record, type } = payload

    const isAssignment = type === 'delivery_assignment';
    const isReady = record?.status === 'ready' && old_record?.status !== 'ready';

    if (!isAssignment && !isReady) {
      return new Response(JSON.stringify({
        message: `Ignore: type=${type}, status=${old_record?.status}->${record?.status}`
      }), { status: 200 })
    }

    const orderId = record.id
    const orderNumber = `SNK-${orderId.substring(0, 4).toUpperCase()}`

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Fetch delivery staff profiles
    const { data: deliveryUsers, error: profileError } = await supabase
      .from('profiles')
      .select('id, fcm_token, preferred_language')
      .eq('role', 'delivery')
      .not('fcm_token', 'is', null)
      .neq('fcm_token', '')

    if (profileError || !deliveryUsers || deliveryUsers.length === 0) {
      return new Response(JSON.stringify({ message: 'No delivery staff with FCM tokens found' }), { status: 200 })
    }

    // Identify recipients
    let recipients = deliveryUsers;
    if (isAssignment) {
      const assignedId = record.assigned_delivery_person;
      recipients = deliveryUsers.filter(u => u.id === assignedId);
      if (recipients.length === 0) {
        return new Response(JSON.stringify({ message: `Assigned user ${assignedId} has no token` }), { status: 200 })
      }
    }

    // Get FCM Auth Token
    const client = new JWT({
      email: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
      key: Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    const gTokens = await client.authorize()
    const accessToken = gTokens.access_token

    const project_id = Deno.env.get('FIREBASE_PROJECT_ID')
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${project_id}/messages:send`

    const sendPromises = recipients.map(user => {
      const typeKey = isAssignment ? 'delivery_assignment' : 'new_delivery_order';
      const localized = getLocalizedContent(typeKey, user.preferred_language || 'en', orderNumber);

      return fetch(fcmUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: user.fcm_token,
            notification: {
              title: localized.title,
              body: localized.body,
            },
            data: {
              type: typeKey,
              order_id: orderId,
              order_number: orderNumber,
            },
            android: {
              priority: 'high',
              notification: { channel_id: 'delivery_alerts', sound: 'default' }
            },
            apns: { payload: { aps: { sound: 'default', badge: 1 } } }
          }
        })
      })
    })

    await Promise.all(sendPromises)

    return new Response(JSON.stringify({
      success: true,
      type: isAssignment ? 'delivery_assignment' : 'ready_broadcast',
      sent_count: recipients.length
    }), { status: 200 })

  } catch (error) {
    console.error('Edge Function Error:', error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
