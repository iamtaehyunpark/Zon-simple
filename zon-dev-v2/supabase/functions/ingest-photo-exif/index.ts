import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface PhotoExifPayload {
  storage_url: string
  thumbnail_url?: string
  width?: number
  height?: number
  exif_lat?: number
  exif_lng?: number
  exif_taken_at?: string // ISO8601
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

    const payload: PhotoExifPayload = await req.json()

    // Insert photo record
    const { data: photo, error: photoError } = await supabase
      .from('photos')
      .insert({
        user_id: user.id,
        storage_url: payload.storage_url,
        thumbnail_url: payload.thumbnail_url,
        width: payload.width,
        height: payload.height,
        exif_lat: payload.exif_lat,
        exif_lng: payload.exif_lng,
        exif_taken_at: payload.exif_taken_at,
      })
      .select()
      .single()

    if (photoError) throw photoError

    // Also insert a raw location event if EXIF coords present
    if (payload.exif_lat && payload.exif_lng && payload.exif_taken_at) {
      await supabase.from('raw_location_events').insert({
        user_id: user.id,
        lat: payload.exif_lat,
        lng: payload.exif_lng,
        source: 'exif',
        captured_at: payload.exif_taken_at,
        photo_id: photo.id,
      })

      // Check if a nearby stamp exists (within 50m) to auto-link
      const { data: nearbyStamps } = await supabase.rpc('stamps_within_radius', {
        p_user_id: user.id,
        user_lat: payload.exif_lat,
        user_lng: payload.exif_lng,
        radius_m: 50,
      })

      if (nearbyStamps && nearbyStamps.length > 0) {
        await supabase
          .from('photos')
          .update({ stamp_id: nearbyStamps[0].id })
          .eq('id', photo.id)
      }
    }

    return new Response(JSON.stringify({ photo_id: photo.id }), {
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
