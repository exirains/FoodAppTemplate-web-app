import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { JWT } from "https://esm.sh/google-auth-library@8.7.0"

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  record: any;
  schema: string;
}

const LOCALIZED_MESSAGES: Record<string, { title: string, body: (num: string) => string }> = {
  'en': {
    title: '👨‍🍳 New Order Received!',
    body: (num) => `Order #${num} needs baking.`,
  },
  'tr': {
    title: '👨‍🍳 Yeni Sipariş Alındı!',
    body: (num) => `Sipariş #${num} pişirilmeyi bekliyor.`,
  },
  'fa': {
    title: '👨‍🍳 سفارش جدید دریافت شد!',
    body: (num) => `سفارش #${num} نیاز به پخت دارد.`,
  }
}

serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json()
    const { record, type } = payload

    // Only handle INSERTs as per trigger
    if (type !== 'INSERT') {
       return new Response(JSON.stringify({ message: 'Ignore: Only INSERTs are handled' }), { status: 200 })
    }

    const orderId = record.id
    const orderNumber = record.order_number || `SNK-${orderId.substring(0, 4).toUpperCase()}`

    // 1. Initialize Supabase Admin Client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 2. Find Admin and Staff Users from Profiles
    // Must have FCM token AND notifications enabled
    const { data: staffUsers, error: profileError } = await supabase
      .from('profiles')
      .select('id, fcm_token, preferred_language, role')
      .in('role', ['admin', 'staff'])
      .eq('notifications_new_order_enabled', true)
      .not('fcm_token', 'is', null)
      .neq('fcm_token', '')

    if (profileError || !staffUsers || staffUsers.length === 0) {
      console.log('No eligible staff/admin with FCM tokens found or notifications disabled');
      return new Response(JSON.stringify({ message: 'No eligible recipients found' }), { status: 200 })
    }

    // 3. Get Google Auth Token for FCM v1
    const client = new JWT({
      email: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
      key: Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    const gTokens = await client.authorize()
    const accessToken = gTokens.access_token

    // 4. Send notifications via FCM v1 API
    const project_id = Deno.env.get('FIREBASE_PROJECT_ID')
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${project_id}/messages:send`

    const sendPromises = staffUsers.map(user => {
      const lang = user.preferred_language || 'en'
      const message = LOCALIZED_MESSAGES[lang] || LOCALIZED_MESSAGES['en']

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
              title: message.title,
              body: message.body(orderNumber),
            },
            data: {
              type: 'new_order',
              order_id: orderId,
              order_number: orderNumber,
              role: user.role, // Pass role for easier navigation logic in Flutter if needed
            },
            fcm_options: {
              analytics_label: 'staff_new_order',
            },
            android: {
              priority: 'high',
              notification: {
                channel_id: 'staff_alerts',
                sound: 'default',
              }
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                  'mutable-content': 1
                }
              }
            }
          }
        })
      })
    })

    const results = await Promise.all(sendPromises)
    const successCount = results.filter(r => r.ok).length

    return new Response(JSON.stringify({
      success: true,
      sent_count: successCount,
      recipient_count: staffUsers.length,
      order: orderNumber
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Edge Function Error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
