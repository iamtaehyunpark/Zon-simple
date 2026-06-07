-- 020 — Drop confirmed-unused DB objects (no app or edge-function references)
-- and clear the security_definer_view advisor on the feed view.
drop function if exists public.check_ins_for_day(uuid, date);
drop function if exists public.unlinked_photos_for_day(uuid, date);
drop view if exists public.v_timeline_summary;

-- The feed view only exposes public stamps, so run it with the caller's RLS.
alter view public.v_feed_stamps set (security_invoker = true);
