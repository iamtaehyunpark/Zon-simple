-- ============================================================
-- 042 — Make the consent posture actually compliant.
--
-- (Numbered 042: remote already carries MCP-applied 040_revoke_rpc_on_internal_
-- functions and 041_fix_emit_checkin_event_dropped_column, which have no local
-- files — same pattern as historical 026/028.)
--
-- 036 seeded EVERY existing user with bm_data_use = true (opt-out default) and
-- consent_version = null. For opt-in jurisdictions (KR PIPA / EU GDPR) that
-- pre-checked default is the violation: their data would flow into the BM
-- aggregate before they ever made a choice.
--
-- FIX (app + DB together):
--   • The app resolves consent on first foreground after login:
--       - opt-out jurisdiction  → auto-records opt-out defaults + a consent_version
--       - opt-in  jurisdiction  → BLOCKING gate; nothing is recorded until the
--                                 user explicitly decides (toggles default OFF)
--   • This migration makes the DB enforce the invariant regardless of app timing:
--       a user is included in any secondary-use aggregate ONLY IF they have been
--       actively resolved (consent_version IS NOT NULL) AND bm_data_use = true.
--     So a seeded-but-unresolved user (consent_version null) is excluded even
--     though their seeded bm_data_use is still true. Resolution is the gate.
--
-- Posture summary (per owner decision 2026-06-12):
--   opt-out where the law allows it; opt-in (blocking) for KR + EU/EEA.
--   `jurisdiction` is recorded per user; the app decides the posture from locale.
-- ============================================================

-- ── helper: is this user actively resolved for secondary use? ─────────────────
-- "Resolved" = the app (or the user) has written a consent decision. Until then
-- the seeded opt-out default must NOT be treated as consent.
create or replace function public.has_bm_consent(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select dc.bm_data_use and dc.consent_version is not null
       from public.data_consents dc
      where dc.user_id = p_user_id),
    false);
$$;
-- Internal gate for service-role jobs only — clients read data_consents via RLS,
-- never this. Locked down so a signed-in user can't probe others' consent state.
revoke all on function public.has_bm_consent(uuid) from public, anon, authenticated;

-- ── tighten the sanctioned aggregate to require active resolution ─────────────
-- (replaces the 036 definition; adds `dc.consent_version is not null`.)
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
     and dc.consent_version is not null   -- ← only actively-resolved users
   group by c.place_id, pl.geo, pl.category
  having count(distinct c.user_id) >= p_min_visitors;
$$;
revoke all on function public.bm_place_aggregates(int) from public, anon, authenticated;

-- ── third-party provision gate (KR PIPA requires SEPARATE consent for this) ───
-- No third-party export consumer exists yet. When one is built it MUST filter on
-- this function, never on bm_data_use alone: third-party sharing is a distinct,
-- separately-consented purpose. Also note: a fully-compliant KR export still
-- needs per-recipient disclosure (recipient, purpose, items, retention) — record
-- that at export time once recipients are defined.
create or replace function public.has_third_party_consent(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select dc.third_party_share and dc.consent_version is not null
       from public.data_consents dc
      where dc.user_id = p_user_id),
    false);
$$;
revoke all on function public.has_third_party_consent(uuid) from public, anon, authenticated;
