import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { isKorea } from '../_shared/geocoding.ts'

interface PlaceResult {
  place_id: string
  name: string
  address: string
  lat: number
  lng: number
  types: string[]
  external_source: string
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
    const { lat, lng, query, provider: explicitProvider } = body

    if (!lat || !lng) return new Response('Missing lat/lng', { status: 400 })

    // Auto-detect provider if not explicitly specified
    const provider = explicitProvider ?? (isKorea(lat, lng) ? 'naver' : 'google')

    let results: PlaceResult[] = []

    if (provider === 'naver') {
      results = await searchNaver(lat, lng, query)
    } else {
      results = await searchGoogle(lat, lng, query)
    }

    return new Response(JSON.stringify({ results, provider }), {
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

// ── Naver Local Search ──────────────────────────────────────────────────────

async function searchNaver(
  lat: number,
  lng: number,
  query?: string
): Promise<PlaceResult[]> {
  const clientId = Deno.env.get('NAVER_CLIENT_ID')
  const clientSecret = Deno.env.get('NAVER_CLIENT_SECRET')
  if (!clientId || !clientSecret) return []

  const q = query?.trim() || '음식점' // fallback: "restaurant"
  const url = `https://openapi.naver.com/v1/search/local.json?query=${encodeURIComponent(q)}&display=5&sort=comment`

  const res = await fetch(url, {
    headers: {
      'X-Naver-Client-Id': clientId,
      'X-Naver-Client-Secret': clientSecret,
    },
  })

  if (!res.ok) return []
  const data = await res.json()
  const items: any[] = data.items ?? []

  return items.map((item) => {
    // Naver mapx/mapy: integer representation of decimal degrees * 1e7
    const itemLng = parseInt(item.mapx ?? '0') / 1e7
    const itemLat = parseInt(item.mapy ?? '0') / 1e7
    const name = stripHtml(item.title ?? '')
    const address = (item.roadAddress || item.address) ?? ''
    return {
      place_id: item.link || name,
      name,
      address,
      lat: itemLat,
      lng: itemLng,
      types: [item.category ?? ''].filter(Boolean),
      external_source: 'naver',
    }
  })
}

// ── Google Places ───────────────────────────────────────────────────────────

async function searchGoogle(
  lat: number,
  lng: number,
  query?: string
): Promise<PlaceResult[]> {
  const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY')
  if (!apiKey) return []

  const url = query?.trim()
    ? `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query!)}&location=${lat},${lng}&radius=500&key=${apiKey}`
    : `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&rankby=distance&key=${apiKey}`

  const res = await fetch(url)
  const data = await res.json()

  if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') return []

  return (data.results ?? []).slice(0, 5).map((r: any) => ({
    place_id: r.place_id,
    name: r.name,
    address: r.vicinity ?? r.formatted_address ?? '',
    lat: r.geometry.location.lat,
    lng: r.geometry.location.lng,
    types: r.types ?? [],
    external_source: 'google_places',
  }))
}

function stripHtml(s: string): string {
  return s.replace(/<[^>]*>/g, '')
}
