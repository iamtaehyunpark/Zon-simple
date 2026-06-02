import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface LocationEvent {
  lat: number
  lng: number
  accuracy_m?: number
  altitude_m?: number
  source: 'gps' | 'exif' | 'cell_tower'
  captured_at: string // ISO8601
}

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

    const body = await req.json()
    const events: LocationEvent[] = Array.isArray(body) ? body : [body]

    if (events.length === 0) {
      return new Response(JSON.stringify({ inserted: 0 }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    if (events.length > 500) {
      return new Response('Too many events (max 500)', { status: 400 })
    }

    const rows = events.map((e) => ({
      user_id: user.id,
      lat: e.lat,
      lng: e.lng,
      accuracy_m: e.accuracy_m,
      altitude_m: e.altitude_m,
      source: e.source,
      captured_at: e.captured_at,
    }))

    const { error } = await supabase.from('raw_location_events').insert(rows)
    if (error) throw error

    return new Response(JSON.stringify({ inserted: rows.length }), {
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
