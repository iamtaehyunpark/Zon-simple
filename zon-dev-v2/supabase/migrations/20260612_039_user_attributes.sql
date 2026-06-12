-- ============================================================
-- 039 — User attributes (segmentation dimension for "behavior by user type").
--
-- profiles holds only username/bio — there is no dimension to pivot behavior on.
-- This table is that dimension. Per owner decision (2026-06-12), attributes are
-- intended to be populated by IMPLICIT INFERENCE jobs (not user-entered forms),
-- so every column is nullable and carries a `*_source` + `confidence`.
--
-- ⚠ COMPLIANCE NOTE: inferring age/gender/home/work without the user's awareness
-- is personal data under PIPA/GDPR and special-category-adjacent. Population of
-- these columns is gated on data_consents.bm_data_use at JOB time (see 036). The
-- table is built; the inference jobs are a later, separate workstream.
-- ============================================================

create table public.user_attributes (
  user_id           uuid primary key references public.profiles(id) on delete cascade,

  -- declared OR inferred demographics (coarse buckets, never raw)
  age_band          text,              -- '13-17','18-24','25-34','35-44','45-54','55+'
  age_source        text,              -- 'declared' | 'inferred'
  gender            text,
  gender_source     text,

  -- inferred coarse anchors (geohash precision 6 ≈ 1.2km — never exact address)
  home_geohash      text,
  work_geohash      text,
  home_region       text,              -- human-readable coarse region (district/city)

  -- low-sensitivity context
  locale            text,
  primary_language  text,

  -- pure behavioral derivation (no PII input)
  segments          text[] not null default '{}',   -- 'nightlife','cafe_hopper','nature','tourist',...

  confidence        real,              -- overall confidence of the inferred profile
  source            text not null default 'inferred',
  updated_at        timestamptz not null default now()
);

alter table public.user_attributes enable row level security;
-- Transparency: a user may SEE what's been inferred about them (supports a future
-- data-access/"why am I seeing this" screen). Writes are inference-job only
-- (service role) — no insert/update policy for users.
create policy "Users view own attributes" on public.user_attributes
  for select using ((select auth.uid()) = user_id);

create index user_attributes_age_idx      on public.user_attributes(age_band);
create index user_attributes_gender_idx   on public.user_attributes(gender);
create index user_attributes_home_idx     on public.user_attributes(home_geohash);
create index user_attributes_segments_idx on public.user_attributes using gin(segments);

-- Seed empty rows so inference jobs UPDATE rather than UPSERT.
insert into public.user_attributes (user_id)
  select id from public.profiles
  on conflict (user_id) do nothing;
