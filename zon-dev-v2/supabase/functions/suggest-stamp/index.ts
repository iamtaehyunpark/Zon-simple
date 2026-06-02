import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { reverseGeocode } from '../_shared/geocoding.ts'
import { sendFcmNotification } from '../_shared/fcm.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return new Response('Unauthorized', { status: 401 })

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) return new Response('Unauthorized', { status: 401 })

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { lat, lng } = await req.json()
    if (!lat || !lng) return new Response('Missing lat/lng', { status: 400 })

    // Privacy check
    const { data: privacy } = await supabaseAdmin
      .from('user_privacy')
      .select('significant_change_enabled')
      .eq('user_id', user.id)
      .single()

    if (!privacy?.significant_change_enabled) {
      return new Response(JSON.stringify({ skipped: 'disabled' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Rate limit: 30 min cooldown
    const { data: canSend } = await supabaseAdmin.rpc('can_send_notification', {
      p_user_id: user.id,
      p_type: 'significant_change_nudge',
      cooldown_minutes: 30,
    })
    if (!canSend) {
      return new Response(JSON.stringify({ skipped: 'rate_limited' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Max 2 per hour
    const { count } = await supabaseAdmin
      .from('notification_log')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id)
      .eq('type', 'significant_change_nudge')
      .gte('sent_at', new Date(Date.now() - 60 * 60 * 1000).toISOString())

    if ((count ?? 0) >= 2) {
      return new Response(JSON.stringify({ skipped: 'hourly_limit' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Geocode server-side: Naver for Korea, Mapbox globally
    const placeName = await reverseGeocode(lat, lng)

    const message = placeName
      ? `${placeName}에 도착한 것 같아요. 스탬프를 남길까요?`
      : '새로운 장소에 도착했어요. 스탬프를 남길까요?'

    // Store cell-tower event
    await supabase.from('raw_location_events').insert({
      user_id: user.id,
      lat,
      lng,
      source: 'cell_tower',
      captured_at: new Date().toISOString(),
      geocoded_name: placeName,
    })

    // Log notification
    await supabaseAdmin.from('notification_log').insert({
      user_id: user.id,
      type: 'significant_change_nudge',
      payload: { lat, lng, geocoded_name: placeName, message },
    })

    // Send via FCM HTTP v1
    const { data: tokens } = await supabaseAdmin
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', user.id)

    let sentCount = 0
    for (const { token } of tokens ?? []) {
      const ok = await sendFcmNotification(token, {
        title: '새로운 장소',
        body: message,
        data: {
          type: 'significant_change_nudge',
          lat: String(lat),
          lng: String(lng),
        },
      })
      if (ok) sentCount++
    }

    return new Response(
      JSON.stringify({ sent: sentCount, message, placeName }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    console.error(err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
