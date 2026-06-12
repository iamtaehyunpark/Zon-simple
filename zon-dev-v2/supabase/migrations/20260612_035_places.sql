-- ============================================================
-- 035 — Canonical places + external-id resolution + backfill.
--
-- Introduces a first-class `place` entity. Until now a "place" was only a
-- denormalized triple (external_source, external_place_id, normalized_place_name)
-- copied onto every stamp/check_in. That fragments the same physical place across
-- providers (google/kakao/naver) and across unstable ids, making per-place
-- aggregation (the core BM query) impossible.
--
-- Identity = HYBRID:
--   a point joins an existing place if it shares a known external id,
--   OR it falls within `match_radius_m` (default 25m) of an existing place;
--   otherwise a new place is created.
--
-- external_* columns are KEPT on stamps/check_ins as provenance.
-- ============================================================

create extension if not exists postgis;

-- Coarse, controlled category. Extend the enum as the place graph matures.
create type place_category as enum (
  'food', 'cafe', 'bar', 'shopping', 'culture', 'nature',
  'transit', 'lodging', 'work', 'home', 'service', 'other'
);

-- ── places ───────────────────────────────────────────────────────────────────
create table public.places (
  id              uuid primary key default uuid_generate_v4(),
  canonical_name  text not null,
  normalized_name text,
  category        place_category not null default 'other',
  lat             double precision not null,
  lng             double precision not null,
  geo             geometry(Point, 4326),
  geohash         text,                        -- ST_GeoHash precision 9 (~5m) — place identity key
  visit_count     int not null default 0,      -- maintained by trigger from check_ins
  visitor_count   int not null default 0,      -- distinct visitors; recomputed by job/backfill
  first_seen_at   timestamptz not null default now(),
  last_seen_at    timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create or replace function public.sync_place_geo()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.geo := public.ST_SetSRID(public.ST_MakePoint(new.lng, new.lat), 4326);
  new.geohash := public.ST_GeoHash(new.geo, 9);
  return new;
end;
$$;

create trigger place_geo_trigger before insert or update on public.places
for each row execute function public.sync_place_geo();

create index places_geo_idx on public.places using gist(geo);
create index places_geohash_idx on public.places(geohash);
create index places_normalized_name_idx on public.places(normalized_name);

-- ── external-id resolution (one place ← many provider ids) ────────────────────
create table public.place_external_ids (
  place_id        uuid not null references public.places(id) on delete cascade,
  external_source text not null,              -- 'google_places' | 'kakao' | 'naver' | ...
  external_id     text not null,
  raw_name        text,
  created_at      timestamptz not null default now(),
  primary key (external_source, external_id)
);
create index place_external_ids_place_idx on public.place_external_ids(place_id);

-- ── RLS: canonical shared data — readable by all, writable only via SECURITY
--    DEFINER resolver (no user-facing insert/update/delete policy) ─────────────
alter table public.places enable row level security;
alter table public.place_external_ids enable row level security;
grant select on public.places to authenticated;
grant select on public.place_external_ids to authenticated;
create policy "places readable by authenticated"
  on public.places for select to authenticated using (true);
create policy "place ext ids readable by authenticated"
  on public.place_external_ids for select to authenticated using (true);

-- ── place_id foreign keys on the trace layers (external_* kept as provenance) ──
alter table public.stamps              add column place_id uuid references public.places(id) on delete set null;
alter table public.check_ins           add column place_id uuid references public.places(id) on delete set null;
alter table public.raw_location_events add column place_id uuid references public.places(id) on delete set null;
create index stamps_place_id_idx     on public.stamps(place_id)              where place_id is not null;
create index check_ins_place_id_idx  on public.check_ins(place_id)           where place_id is not null;
create index raw_events_place_id_idx on public.raw_location_events(place_id)  where place_id is not null;

-- ── resolve_place: the hybrid matcher. Creates/dedups and records provenance.
--    SECURITY DEFINER so it may insert into the RLS-protected place tables.
--    Callable by the app (and triggers) when creating a check-in/stamp. ────────
create or replace function public.resolve_place(
  p_name           text,
  p_lat            double precision,
  p_lng            double precision,
  p_source         text default null,
  p_external_id    text default null,
  p_match_radius_m double precision default 25
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_place_id uuid;
  v_pt       public.geometry;
begin
  v_pt := public.ST_SetSRID(public.ST_MakePoint(p_lng, p_lat), 4326);

  -- 1) exact external-id match
  if p_source is not null and p_external_id is not null then
    select place_id into v_place_id
      from public.place_external_ids
     where external_source = p_source and external_id = p_external_id;
    if v_place_id is not null then
      return v_place_id;
    end if;
  end if;

  -- 2) spatial match: nearest existing place within radius
  select id into v_place_id
    from public.places
   where public.ST_DWithin(geo::public.geography, v_pt::public.geography, p_match_radius_m)
   order by public.ST_Distance(geo::public.geography, v_pt::public.geography)
   limit 1;

  -- 3) otherwise create a new place
  if v_place_id is null then
    insert into public.places (canonical_name, normalized_name, lat, lng, last_seen_at)
    values (p_name, lower(trim(p_name)), p_lat, p_lng, now())
    returning id into v_place_id;
  end if;

  -- 4) record provider id → place mapping (idempotent)
  if p_source is not null and p_external_id is not null then
    insert into public.place_external_ids (place_id, external_source, external_id, raw_name)
    values (v_place_id, p_source, p_external_id, p_name)
    on conflict (external_source, external_id) do nothing;
  end if;

  return v_place_id;
end;
$$;

revoke all on function public.resolve_place(text, double precision, double precision, text, text, double precision) from public, anon;
grant execute on function public.resolve_place(text, double precision, double precision, text, text, double precision) to authenticated;

-- ── auto-resolve place_id on insert ───────────────────────────────────────────
create or replace function public.set_checkin_place()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.place_id is null then
    new.place_id := public.resolve_place(
      new.place_name, new.lat, new.lng, new.external_source, new.external_place_id);
  end if;
  return new;
end;
$$;
create trigger checkin_place_trigger before insert on public.check_ins
for each row execute function public.set_checkin_place();

create or replace function public.set_stamp_place()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.place_id is null then
    if new.check_in_id is not null then
      select place_id into new.place_id from public.check_ins where id = new.check_in_id;
    end if;
    if new.place_id is null then
      new.place_id := public.resolve_place(
        new.place_name, new.lat, new.lng, new.external_source, new.external_place_id);
    end if;
  end if;
  return new;
end;
$$;
create trigger stamp_place_trigger before insert on public.stamps
for each row execute function public.set_stamp_place();

-- ── places.visit_count maintenance (DEFINER: writes RLS-protected places) ──────
create or replace function public.update_place_visit_count()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' and new.place_id is not null then
    update public.places
       set visit_count = visit_count + 1,
           last_seen_at = greatest(coalesce(last_seen_at, new.visited_at), new.visited_at)
     where id = new.place_id;
  elsif tg_op = 'DELETE' and old.place_id is not null then
    update public.places set visit_count = greatest(visit_count - 1, 0) where id = old.place_id;
  elsif tg_op = 'UPDATE' and old.place_id is distinct from new.place_id then
    if old.place_id is not null then
      update public.places set visit_count = greatest(visit_count - 1, 0) where id = old.place_id;
    end if;
    if new.place_id is not null then
      update public.places set visit_count = visit_count + 1 where id = new.place_id;
    end if;
  end if;
  return null;
end;
$$;
create trigger checkin_place_count_trigger after insert or update or delete on public.check_ins
for each row execute function public.update_place_visit_count();

-- ============================================================
-- BACKFILL — repoint existing rows into canonical places.
-- Chronological order so the 25m dedup builds places oldest-first.
-- (check_ins UPDATE fires update_place_visit_count → visit_count is built here.)
-- ============================================================
do $$
declare r record;
begin
  for r in
    select id, place_name, lat, lng, external_source, external_place_id
      from public.check_ins order by visited_at asc
  loop
    update public.check_ins
       set place_id = public.resolve_place(r.place_name, r.lat, r.lng,
                                            r.external_source, r.external_place_id)
     where id = r.id;
  end loop;
end $$;

do $$
declare r record;
begin
  for r in
    select id, check_in_id, place_name, lat, lng, external_source, external_place_id
      from public.stamps order by visited_at asc
  loop
    update public.stamps
       set place_id = coalesce(
             (select place_id from public.check_ins where id = r.check_in_id),
             public.resolve_place(r.place_name, r.lat, r.lng,
                                  r.external_source, r.external_place_id))
     where id = r.id;
  end loop;
end $$;

-- Link existing raw GPS/EXIF points to the nearest place within 30m
-- (do NOT create places from noisy raw points — link only).
update public.raw_location_events e
   set place_id = (
     select pl.id from public.places pl
      where public.ST_DWithin(pl.geo::geography, e.geo::geography, 30)
      order by public.ST_Distance(pl.geo::geography, e.geo::geography)
      limit 1)
 where e.place_id is null and e.geo is not null;

-- Recompute distinct-visitor counts after backfill.
update public.places p
   set visitor_count = sub.c
  from (select place_id, count(distinct user_id) c
          from public.check_ins where place_id is not null group by place_id) sub
 where p.id = sub.place_id;
