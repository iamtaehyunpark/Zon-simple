-- 011 — Followed-users' shared check-ins for a day. Applied via MCP 2026-06-04.
-- NOTE: superseded by 013, which drops the spoofable p_viewer param in favour
-- of auth.uid(). Kept here for migration history.
create or replace function public.shared_check_ins_for_day(p_viewer uuid, p_date date)
returns setof public.check_ins language sql stable security definer
set search_path = ''
as $$
  select c.*
  from public.check_ins c
  join public.follows f
    on f.following_id = c.user_id and f.follower_id = p_viewer
  join public.user_privacy up
    on up.user_id = c.user_id and up.location_sharing_enabled = true
  where c.visited_at >= p_date::timestamptz
    and c.visited_at < (p_date + interval '1 day')::timestamptz;
$$;
