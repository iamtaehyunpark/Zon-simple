-- ============================================================
-- 025 — Public check-ins (feed "stories"). Applied via MCP 2026-06-06.
--
-- Check-ins default private (trace layer). A user may mark one public; public
-- check-ins are visible to everyone unless the owner is private, in which case
-- only accepted followers see them — reusing can_view_user() from migration 023.
-- ============================================================

alter table public.check_ins
  add column if not exists visibility text not null default 'private'
  check (visibility in ('private', 'public'));

create index if not exists check_ins_public_recent_idx
  on public.check_ins(visited_at desc) where visibility = 'public';

create policy "Public check-ins viewable by allowed" on public.check_ins
  for select using (visibility = 'public' and public.can_view_user(user_id));
