-- ============================================================
-- 036 — Consent + anonymization layer for secondary (big-data) use.
--
-- POSTURE (per owner decision 2026-06-12): OPT-OUT — trace data is INCLUDED in
-- the BM aggregate by default; users can switch it off.
--
-- ⚠ COMPLIANCE NOTE (kept in-schema deliberately):
--   Opt-out + covert inference + third-party data licensing is the highest-risk
--   posture and is NOT compliant with Korea PIPA (opt-in required, separate
--   consent for third-party provision) or GDPR, and risks App Store 5.1.1/5.1.2
--   rejection. This schema therefore records consent PER USER and PER
--   JURISDICTION so the default can be flipped to opt-in where required WITHOUT
--   another migration. `jurisdiction` is the switch.
-- ============================================================

-- ── data_consents: auditable, versioned consent state ─────────────────────────
create table public.data_consents (
  user_id           uuid primary key references public.profiles(id) on delete cascade,
  bm_data_use       boolean not null default true,   -- opt-out default: included
  third_party_share boolean not null default true,   -- opt-out default: included
  consent_version   text,                             -- which disclosure text they saw
  jurisdiction      text,                             -- 'KR'|'EU'|'US'|... drives required posture
  decided_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

alter table public.data_consents enable row level security;
create policy "Users view own consent"   on public.data_consents
  for select using ((select auth.uid()) = user_id);
create policy "Users update own consent" on public.data_consents
  for update using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
-- INSERT happens via handle_new_user (below) / backfill — service-side only.

-- Seed existing users (opt-out default).
insert into public.data_consents (user_id)
  select id from public.profiles
  on conflict (user_id) do nothing;

-- New users get a consent row at signup. Extend the existing handler.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_username text;
begin
  v_username := coalesce(
    new.raw_user_meta_data->>'preferred_username',
    new.raw_user_meta_data->>'user_name',
    split_part(new.email, '@', 1),
    'user_' || substr(new.id::text, 1, 8));
  while exists (select 1 from public.profiles where username = v_username) loop
    v_username := v_username || '_' || floor(random() * 1000)::text;
  end loop;
  insert into public.profiles (id, username, display_name, avatar_url)
  values (new.id, v_username,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    new.raw_user_meta_data->>'avatar_url');
  insert into public.user_privacy (user_id) values (new.id);
  insert into public.data_consents (user_id) values (new.id);
  return new;
end;
$$;

-- ── Anonymization keys: coarse geohash bins on the trace layers ───────────────
-- Aggregation/licensing must use these binned columns, NEVER raw lat/lng.
-- precision 7 ≈ 150m cell. Maintained by trigger alongside geo.
alter table public.raw_location_events add column geohash7 text;
alter table public.check_ins           add column geohash7 text;

create or replace function public.sync_raw_event_geo()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.geo := public.ST_SetSRID(public.ST_MakePoint(new.lng, new.lat), 4326);
  new.geohash7 := public.ST_GeoHash(new.geo, 7);
  return new;
end;
$$;

create or replace function public.sync_checkin_geo()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.geo := public.ST_SetSRID(public.ST_MakePoint(new.lng, new.lat), 4326);
  new.geohash7 := public.ST_GeoHash(new.geo, 7);
  return new;
end;
$$;

-- Backfill the bins on existing rows.
update public.raw_location_events
   set geohash7 = public.ST_GeoHash(geo, 7) where geo is not null;
update public.check_ins
   set geohash7 = public.ST_GeoHash(geo, 7) where geo is not null;

create index raw_events_geohash7_idx on public.raw_location_events(geohash7);
create index check_ins_geohash7_idx  on public.check_ins(geohash7);

-- ── Consent-filtered aggregate (SECURITY DEFINER, no raw rows leak) ───────────
-- The ONLY sanctioned read path for the BM: per-place visit aggregates that
-- (a) exclude users who opted out, and (b) suppress small cells (k-anonymity,
-- k>=5 distinct visitors) so individuals can't be re-identified.
create or replace function public.bm_place_aggregates(p_min_visitors int default 5)
returns table (
  place_id      uuid,
  geohash7      text,
  category      public.place_category,
  visit_count   bigint,
  visitor_count bigint,
  last_visit    timestamptz
)
language sql
security definer
set search_path = ''
as $$
  select c.place_id,
         public.ST_GeoHash(pl.geo, 7) as geohash7,
         pl.category,
         count(*)                      as visit_count,
         count(distinct c.user_id)     as visitor_count,
         max(c.visited_at)             as last_visit
    from public.check_ins c
    join public.places pl on pl.id = c.place_id
    join public.data_consents dc on dc.user_id = c.user_id
   where c.place_id is not null
     and dc.bm_data_use = true
   group by c.place_id, pl.geo, pl.category
  having count(distinct c.user_id) >= p_min_visitors;
$$;

-- Locked down: the BM aggregate is a service/analytics-role read, not user-facing.
revoke all on function public.bm_place_aggregates(int) from public, anon, authenticated;
