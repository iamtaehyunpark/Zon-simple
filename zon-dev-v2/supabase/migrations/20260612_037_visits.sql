-- ============================================================
-- 037 — Stay-point visits derived from raw_location_events.
--
-- check_ins are sparse and user-initiated. The real visit-log product is the
-- DERIVED dwell: segment the raw GPS/EXIF trail into "user stayed within R
-- metres for >= T minutes" episodes, then attach each to a canonical place.
--
-- Derivation is idempotent per (user, day): re-running replaces that day's
-- derived visits. Schedule with pg_cron (see note at bottom).
-- ============================================================

create table public.visits (
  id           uuid primary key default uuid_generate_v4(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  place_id     uuid references public.places(id) on delete set null,
  arrived_at   timestamptz not null,
  departed_at  timestamptz,
  dwell_min    int,
  point_count  int not null default 0,
  lat          double precision not null,
  lng          double precision not null,
  geo          geometry(Point, 4326),
  geohash7     text,
  source       text not null default 'derived',     -- 'derived' | 'checkin'
  created_at   timestamptz not null default now()
);

create or replace function public.sync_visit_geo()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.geo := public.ST_SetSRID(public.ST_MakePoint(new.lng, new.lat), 4326);
  new.geohash7 := public.ST_GeoHash(new.geo, 7);
  return new;
end;
$$;
create trigger visit_geo_trigger before insert or update on public.visits
for each row execute function public.sync_visit_geo();

create index visits_user_time_idx on public.visits(user_id, arrived_at desc);
create index visits_place_idx     on public.visits(place_id) where place_id is not null;
create index visits_geo_idx       on public.visits using gist(geo);

alter table public.visits enable row level security;
create policy "Users manage own visits" on public.visits
  for all using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- ── Stay-point derivation ─────────────────────────────────────────────────────
-- Greedy single-pass clustering of one user's events for one local day:
--   • start a cluster at the first point;
--   • keep adding points while they are within `p_radius_m` of the cluster's
--     centroid AND within `p_max_gap_min` of the previous point;
--   • when a point breaks either rule, flush the cluster as a visit if its dwell
--     spans >= `p_min_dwell_min`, then start a new cluster.
-- Re-runnable: deletes that day's derived visits first.
create or replace function public.derive_visits(
  p_user_id       uuid,
  p_date          date,
  p_radius_m      double precision default 60,
  p_min_dwell_min int default 10,
  p_max_gap_min   int default 30
)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  r            record;
  c_lat        double precision;
  c_lng        double precision;
  c_n          int;
  c_start      timestamptz;
  c_end        timestamptz;
  c_prev       timestamptz;
  v_inserted   int := 0;
begin
  -- clear previously-derived visits for this user/day (idempotent)
  delete from public.visits
   where user_id = p_user_id and source = 'derived'
     and (arrived_at at time zone 'UTC')::date = p_date;

  c_n := 0;

  for r in
    select lat, lng, captured_at,
           public.ST_SetSRID(public.ST_MakePoint(lng, lat), 4326) as pt
      from public.raw_location_events
     where user_id = p_user_id
       and captured_at >= p_date::timestamptz
       and captured_at <  (p_date + interval '1 day')::timestamptz
     order by captured_at asc
  loop
    if c_n = 0 then
      c_lat := r.lat; c_lng := r.lng; c_n := 1;
      c_start := r.captured_at; c_end := r.captured_at; c_prev := r.captured_at;
      continue;
    end if;

    -- within radius of running centroid AND not gapped out?
    if public.ST_DWithin(
         public.ST_SetSRID(public.ST_MakePoint(c_lng, c_lat), 4326)::public.geography,
         r.pt::public.geography, p_radius_m)
       and r.captured_at <= c_prev + make_interval(mins => p_max_gap_min)
    then
      -- extend cluster (running mean centroid)
      c_lat := (c_lat * c_n + r.lat) / (c_n + 1);
      c_lng := (c_lng * c_n + r.lng) / (c_n + 1);
      c_n   := c_n + 1;
      c_end := r.captured_at;
      c_prev := r.captured_at;
    else
      -- flush current cluster as a visit if it dwelled long enough
      if extract(epoch from (c_end - c_start)) / 60.0 >= p_min_dwell_min then
        insert into public.visits
          (user_id, place_id, arrived_at, departed_at, dwell_min, point_count, lat, lng)
        values (
          p_user_id,
          public.resolve_place('Unknown', c_lat, c_lng, null, null, p_radius_m),
          c_start, c_end,
          floor(extract(epoch from (c_end - c_start)) / 60.0)::int,
          c_n, c_lat, c_lng);
        v_inserted := v_inserted + 1;
      end if;
      -- start fresh cluster at this point
      c_lat := r.lat; c_lng := r.lng; c_n := 1;
      c_start := r.captured_at; c_end := r.captured_at; c_prev := r.captured_at;
    end if;
  end loop;

  -- flush trailing cluster
  if c_n > 0 and extract(epoch from (c_end - c_start)) / 60.0 >= p_min_dwell_min then
    insert into public.visits
      (user_id, place_id, arrived_at, departed_at, dwell_min, point_count, lat, lng)
    values (
      p_user_id,
      public.resolve_place('Unknown', c_lat, c_lng, null, null, p_radius_m),
      c_start, c_end,
      floor(extract(epoch from (c_end - c_start)) / 60.0)::int,
      c_n, c_lat, c_lng);
    v_inserted := v_inserted + 1;
  end if;

  return v_inserted;
end;
$$;

revoke all on function public.derive_visits(uuid, date, double precision, int, int)
  from public, anon, authenticated;

-- ── Scheduling note ───────────────────────────────────────────────────────────
-- pg_cron is available. To derive yesterday's visits for all users nightly:
--   select cron.schedule('derive-visits-nightly', '30 3 * * *', $cron$
--     do $$ declare u uuid; begin
--       for u in select id from public.profiles loop
--         perform public.derive_visits(u, (now() - interval '1 day')::date);
--       end loop; end $$;
--   $cron$);
-- Left commented — enable once derivation params are tuned on real data.
