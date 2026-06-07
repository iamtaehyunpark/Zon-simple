-- 013 — Security hardening (from get_advisors). Applied via MCP 2026-06-04.

-- Use the caller's identity (not a spoofable param) for shared check-ins,
-- otherwise any caller could pass another user's id and read their shared trace.
drop function if exists public.shared_check_ins_for_day(uuid, date);

create or replace function public.shared_check_ins_for_day(p_date date)
returns setof public.check_ins language sql stable security definer
set search_path = '' as $$
  select c.*
  from public.check_ins c
  join public.follows f
    on f.following_id = c.user_id and f.follower_id = (select auth.uid())
  join public.user_privacy up
    on up.user_id = c.user_id and up.location_sharing_enabled = true
  where c.visited_at >= p_date::timestamptz
    and c.visited_at < (p_date + interval '1 day')::timestamptz;
$$;

-- Trigger functions run as the table owner via triggers; not REST-callable.
revoke all on function public.notify_on_like() from public;
revoke all on function public.notify_on_comment() from public;
revoke all on function public.notify_on_follow() from public;
revoke all on function public.notify_on_stamp_tags() from public;

-- RPCs: signed-in users only.
revoke all on function public.create_mention_notification(uuid, uuid, uuid) from public;
grant execute on function public.create_mention_notification(uuid, uuid, uuid) to authenticated;
revoke all on function public.shared_check_ins_for_day(date) from public;
grant execute on function public.shared_check_ins_for_day(date) to authenticated;
