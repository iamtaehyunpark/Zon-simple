-- 019 — Drop vestigial tz_offset_min. Applied via MCP 2026-06-04.
-- Day bucketing uses the stored wall date directly (visited_at is stored as
-- local-wall-clock-as-UTC), so the captured offset is never read.
alter table public.check_ins drop column if exists tz_offset_min;
alter table public.stamps    drop column if exists tz_offset_min;
