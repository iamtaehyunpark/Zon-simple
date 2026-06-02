// Shared geocoding utility for all edge functions.
// Auto-selects provider by region: Naver for Korea, Mapbox globally.

export function isKorea(lat: number, lng: number): boolean {
  return lat >= 33.0 && lat <= 38.9 && lng >= 124.0 && lng <= 132.0
}

/**
 * Reverse geocode coordinates to a human-readable place name.
 * Returns null if the call fails — callers must handle gracefully.
 */
export async function reverseGeocode(
  lat: number,
  lng: number
): Promise<string | null> {
  if (isKorea(lat, lng)) {
    return reverseGeocodeNaver(lat, lng)
  }
  return reverseGeocodeMapbox(lat, lng)
}

// ── Naver Reverse Geocoding (Korea) ────────────────────────────────────────
// API: https://naveropenapi.apigw.naver.com/map-reversegeocode/v2/gc
// Credentials: NCP (Naver Cloud Platform) — different from Search API creds.
// Note: coords param is lng,lat order.
async function reverseGeocodeNaver(
  lat: number,
  lng: number
): Promise<string | null> {
  const keyId = Deno.env.get('NAVER_MAP_CLIENT_ID')
  const key = Deno.env.get('NAVER_MAP_CLIENT_SECRET')
  if (!keyId || !key) return null

  try {
    const url =
      `https://naveropenapi.apigw.naver.com/map-reversegeocode/v2/gc` +
      `?coords=${lng},${lat}&sourcecrs=epsg:4326&output=json&orders=roadaddr,addr`

    const res = await fetch(url, {
      headers: {
        'X-NCP-APIGW-API-KEY-ID': keyId,
        'X-NCP-APIGW-API-KEY': key,
      },
    })

    if (!res.ok) return null
    const data = await res.json()
    const results: any[] = data.results ?? []
    if (results.length === 0) return null

    // Prefer road address (도로명주소), fall back to land-lot (지번주소)
    const r = results.find((x: any) => x.name === 'roadaddr') ?? results[0]

    const region = r.region ?? {}
    const area1 = region.area1?.name ?? ''  // 시/도  e.g. "서울특별시"
    const area2 = region.area2?.name ?? ''  // 구/군  e.g. "강남구"
    const area3 = region.area3?.name ?? ''  // 동     e.g. "역삼동"
    const road = r.land?.name ?? ''          // 도로명 e.g. "테헤란로"
    const number = [r.land?.number1, r.land?.number2]
      .filter(Boolean)
      .join('-')

    if (road) {
      // Road address: "강남구 테헤란로 123"
      return [area2, road, number].filter(Boolean).join(' ')
    }
    // Land-lot address: "강남구 역삼동"
    return [area2, area3].filter(Boolean).join(' ') || area1 || null
  } catch {
    return null
  }
}

// ── Mapbox Geocoding (global fallback) ─────────────────────────────────────
async function reverseGeocodeMapbox(
  lat: number,
  lng: number
): Promise<string | null> {
  const token = Deno.env.get('MAPBOX_TOKEN')
  if (!token) return null

  try {
    const url =
      `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json` +
      `?types=poi,address,neighborhood,locality&limit=1&access_token=${token}`

    const res = await fetch(url)
    if (!res.ok) return null
    const data = await res.json()
    return data.features?.[0]?.place_name ?? null
  } catch {
    return null
  }
}
