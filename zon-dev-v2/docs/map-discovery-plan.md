# ZON — Map Discovery Plan (Next Major Version) 

> Written 2026-06-07. Simple plan for turning ZON's map into a social place-discovery layer
> (Naver Map-style). Every pipeline, table, and abstraction is designed to make the
> **external API → own places DB** transition a single swap, not a rewrite.

---

## Goal

Turn the map from a personal trace viewer into a **social discovery layer**: nearby hot places
surfaced by ZON stamp density, searchable by name/category, place detail pages backed by
user-generated stamps as reviews.

---

## Core principle: accumulate now, own later

We depend on Kakao (Korea) and Google Places (worldwide) today, but will eventually maintain
our own `places` table. The strategy is to **write through to the DB on every external API
interaction** so that by the time we switch, we already have rich, battle-tested place data
accumulated organically from real user activity — no scraping, no cold-start problem.

The code never talks directly to Kakao/Google. It always goes through a `PlaceRepository`
interface whose backing implementation swaps from "external API + write-through" to
"own DB + external fallback" without touching call sites.

---

## 1. Data model — design it now, populate it incrementally

### `places` table (new migration)

```sql
create table public.places (
  id                uuid primary key default gen_random_uuid(),

  -- External identity (null once we own the record fully)
  external_id       text,
  external_source   text,   -- 'kakao' | 'google' | 'zon'
  unique (external_id, external_source),

  -- Core fields
  name              text not null,
  normalized_name   text not null generated always as (lower(trim(name))) stored,
  lat               float8 not null,
  lng               float8 not null,
  category          text,   -- normalized slug: 'cafe' | 'restaurant' | 'culture' | 'outdoor' | 'shopping'
  address           text,
  phone             text,
  hours             jsonb,  -- lazy-populated from external API on first place-detail view

  -- ZON social stats (updated by trigger from check_ins + stamps)
  zon_stamp_count   int not null default 0,
  zon_visitor_count int not null default 0,
  last_visited_at   timestamptz,

  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

-- Geo index for nearby queries
create index places_geo_idx on public.places using gist (
  ll_to_earth(lat, lng)
);

-- Popularity index for hot-places ranking
create index places_popularity_idx on public.places (zon_visitor_count desc, last_visited_at desc);
```

### `check_ins` and `stamps` — add FK when ready

`check_ins` already has `external_place_id` / `external_source`. Add `place_id uuid references places(id)` as a **nullable** column now. Populate it via the write-through upsert on every check-in creation. When we own the DB fully, make it non-nullable.

### `place_stats` view (feeds discovery layer)

```sql
create or replace view public.place_stats as
select
  p.id,
  p.name,
  p.lat,
  p.lng,
  p.category,
  p.address,
  count(distinct s.id) filter (where s.visibility = 'public') as public_stamp_count,
  count(distinct c.user_id) as unique_visitors,
  max(greatest(c.visited_at, s.visited_at)) as last_visited_at,
  -- Recency-weighted hot score
  (count(distinct c.user_id) * 2 + count(distinct s.id))::float
    / nullif(extract(epoch from (now() - max(greatest(c.visited_at, s.visited_at)))) / 86400 + 1, 0)
    as hot_score
from public.places p
left join public.check_ins c on c.place_id = p.id
left join public.stamps    s on s.place_id = p.id
group by p.id;
```

---

## 2. Service abstraction — the swap seam

### Current structure

```
PlaceService (interface: nearby, search)
  ├── KakaoPlaceService   (Korea)
  └── GooglePlaceService  (worldwide)
```

`placeServiceForProvider(lat, lng)` routes to the right one.

### Target structure (no call-site changes)

```
PlaceRepository (interface: nearby, search, resolve, get)
  └── ExternalPlaceRepository        ← current behaviour + write-through upsert
        ├── KakaoPlaceService
        └── GooglePlaceService
  └── OwnPlaceRepository             ← future: own DB first, external fallback for unknowns
```

**Write-through upsert** (add to `ExternalPlaceRepository` now):

Every result from `nearby()` or `search()` is upserted into `places` with
`on conflict (external_id, external_source) do update set name=…, lat=…, updated_at=now()`.
This is a fire-and-forget background write — it never blocks the UI.

When a check-in is created with a place selected from the dropdown, the resolved `places.id`
is written to `check_ins.place_id`.

**Switching to own DB later:**

1. Swap `ExternalPlaceRepository` for `OwnPlaceRepository` in the provider.
2. `OwnPlaceRepository.nearby(lat, lng)` queries `places` table via PostGIS `earth_distance`.
3. For unknown places (not yet in our DB), falls back to external API + write-through.
4. Zero changes to `PlaceSearchField`, `CheckInEditorBody`, or any feature screen.

---

## 3. Phased feature rollout

### Phase A — Map search bar

**Search for a specific place directly on the map.**

- Floating search field at top of `MapScreen`
- Calls `PlaceRepository.search(query, currentLat, currentLng)`
- Results appear as temporary "search result" pins (distinct style from social pins)
- Tap → place preview card: name, category, distance, ZON stamp count
- "Check in here" shortcut pre-fills the check-in editor
- Every search result upserted into `places` (write-through)

### Phase B — Category filter

**Filter map content by place type.**

- Replace time-range filter chips with dual-layer: **category chips** (Cafe / Food / Culture /
  Outdoor / Shopping) + **time toggle**
- Category derived from Kakao/Google `category_group_code` → normalized to our slug
- Applies to: search results, hot-places layer, nearby list
- Category stored on `places.category` via write-through

### Phase C — Hot places discovery layer

**Show popular ZON spots as a density layer on the map.**

- Query `place_stats` view ordered by `hot_score` within the current map viewport (bounding box)
- Render as sized circles: circle radius ∝ `log(hot_score)`; color by category
- Client-side via Mapbox `GeoJsonSource` (same pattern as existing pin layers)
- Tap cluster → expands; tap single place → place preview card
- Applies only to places with `zon_stamp_count > 0` (places with real ZON activity)

### Phase D — Place detail page

**A review page per place, backed by stamps.**

- Route `/place/:placeId` (using `places.id` as key)
- Header: name, address, category, hours/phone (from `places`, lazy-filled from external API)
- ZON stats: stamp count, unique visitor count, last visited
- Photo grid: cover photos from public stamps at this place
- Stamp cards: public stamps at this place ordered by recency (existing `StampCard` widget)
- "Check in here" CTA → `/checkin?placeId=<id>` pre-fills everything
- Friends-been-here indicator: avatar row of followed users who checked in

### Phase E — Nearby hot list

**Discovery without panning the map.**

- Bottom snap panel on the map (same `DraggableScrollableSheet` pattern as timeline)
- Ranked list: `place_stats.hot_score` within N km of current location
- Category filter applies
- Each row: place name, category icon, distance, stamp count, friend indicator
- Tap row → place detail page

---

## 4. Hot score formula

```
hot_score = (unique_visitors × 2 + public_stamp_count) / (days_since_last_visit + 1)^0.5
```

- Favors **active + social** places over stale ones with old high counts
- Unique visitors weighted 2× because a place is more "hot" when many different people go
- `days_since_last_visit + 1` in the denominator means a place visited today scores much higher
  than one last visited a month ago

Tunable — expose the weights as DB config if needed later.

---

## 5. Migration path: external API → own DB

| Stage                    | State                                         | What backs place data                                                 |
| ------------------------ | --------------------------------------------- | --------------------------------------------------------------------- |
| **Now**            | No `places` table                           | Kakao/Google API calls, no persistence                                |
| **Phase A–B**     | `places` table exists, write-through active | Kakao/Google API + organic accumulation                               |
| **Phase C–E**     | `places` populated for active areas         | Discovery layer uses own DB; API fills gaps                           |
| **Own DB**         | `places` has critical mass                  | `OwnPlaceRepository` primary; external = fallback only for unknowns |
| **Full ownership** | Own editorial/curation                        | External APIs optional; we enrich with our own data                   |

No feature code changes are needed at each stage boundary — only the repository implementation
and the Riverpod provider swap.

---

## 6. Out of scope for this version

- User-written text reviews (separate from stamps — stamps serve this role for now)
- Star ratings
- Business owner claiming / verification
- Opening hours editing by users
- Navigation / turn-by-turn directions
- Paid promoted places
