import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { reverseGeocode } from '../_shared/geocoding.ts'

// Lightweight endpoint: takes lat/lng, returns a place name.
// Used by the Flutter app before displaying location-based UI.
// Also backfills geocoded_name on raw_location_events lazily.
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

    const { lat, lng, event_id } = await req.json()
    if (!lat || !lng) return new Response('Missing lat/lng', { status: 400 })

    const placeName = await reverseGeocode(lat, lng)

    // Optionally backfill geocoded_name on a specific raw_location_event
    if (event_id && placeName) {
      await supabase
        .from('raw_location_events')
        .update({ geocoded_name: placeName })
        .eq('id', event_id)
        .eq('user_id', user.id)
    }

    return new Response(JSON.stringify({ place_name: placeName }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error(err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
