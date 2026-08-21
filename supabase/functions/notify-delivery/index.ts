import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { JWT } from "https://esm.sh/google-auth-library@8.7.0"

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  record: any;
  old_record: any;
  schema: string;
}

serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json()
    const { record, old_record } = payload

    // 1. Validation Logic
    // Only proceed if status is now 'ready' and it wasn't 'ready' before
    const newStatus = record?.status
    const oldStatus = old_record?.status

    if (newStatus !== 'ready' || oldStatus === 'ready') {
      return new Response(JSON.stringify({
        message: `Ignore: Status changed from ${oldStatus} to ${newStatus}`
      }), { status: 200 })
    }

    const orderId = record.id
    // Matches Flutter logic: SNK- + first 4 chars of UUID
    const orderNumber = `SNK-${orderId.substring(0, 4).toUpperCase()}`

    // 2. Initialize Supabase Admin Client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 3. Find Delivery Users from Profiles
    // Single source of truth: profiles.fcm_token
    const { data: deliveryUsers, error: profileError } = await supabase
      .from('profiles')
      .select('id, fcm_token')
      .eq('role', 'delivery')
      .not('fcm_token', 'is', null)
      .neq('fcm_token', '')

    if (profileError || !deliveryUsers || deliveryUsers.length === 0) {
      return new Response(JSON.stringify({ message: 'No delivery staff with FCM tokens found' }), { status: 200 })
    }

    // 4. Get Google Auth Token for FCM v1
    const client = new JWT({
      email: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
      key: Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    const gTokens = await client.authorize()
    const accessToken = gTokens.access_token

    // 5. Send notifications via FCM v1 API
    const project_id = Deno.env.get('FIREBASE_PROJECT_ID')
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${project_id}/messages:send`

    const sendPromises = deliveryUsers.map(user => {
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
              title: '🛵 New Sangak Order!',
              body: `Order #${orderNumber} is ready!`,
            },
            data: {
              type: 'new_delivery_order',
              order_id: orderId,
              status: 'ready',
              order_number: orderNumber,
            },
            fcm_options: {
              analytics_label: 'delivery_new_order',
            },
            android: {
              priority: 'high',
              notification: {
                channel_id: 'delivery_alerts',
                sound: 'default',
              }
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                }
              }
            }
          }
        })
      })
    })

    await Promise.all(sendPromises)

    return new Response(JSON.stringify({
      success: true,
      sent_count: deliveryUsers.length,
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
