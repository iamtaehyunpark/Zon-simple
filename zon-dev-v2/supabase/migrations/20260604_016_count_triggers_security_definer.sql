-- 016 — Count triggers as SECURITY DEFINER. Applied via MCP 2026-06-04.
-- Without this they run as the calling user and RLS blocks updates to OTHER
-- users' rows (followed user's follower_count; others' stamp like/comment/save).

create or replace function public.update_follow_counts()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if TG_OP = 'INSERT' then
    update public.profiles set following_count = following_count + 1 where id = NEW.follower_id;
    update public.profiles set follower_count = follower_count + 1 where id = NEW.following_id;
  elsif TG_OP = 'DELETE' then
    update public.profiles set following_count = following_count - 1 where id = OLD.follower_id;
    update public.profiles set follower_count = follower_count - 1 where id = OLD.following_id;
  end if;
  return null;
end; $$;

create or replace function public.update_stamp_like_count()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if TG_OP = 'INSERT' then update public.stamps set like_count = like_count + 1 where id = NEW.stamp_id;
  elsif TG_OP = 'DELETE' then update public.stamps set like_count = like_count - 1 where id = OLD.stamp_id; end if;
  return null;
end; $$;

create or replace function public.update_stamp_comment_count()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if TG_OP = 'INSERT' then update public.stamps set comment_count = comment_count + 1 where id = NEW.stamp_id;
  elsif TG_OP = 'DELETE' then update public.stamps set comment_count = comment_count - 1 where id = OLD.stamp_id; end if;
  return null;
end; $$;

create or replace function public.update_stamp_save_count()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if TG_OP = 'INSERT' then update public.stamps set save_count = save_count + 1 where id = NEW.stamp_id;
  elsif TG_OP = 'DELETE' then update public.stamps set save_count = save_count - 1 where id = OLD.stamp_id; end if;
  return null;
end; $$;

revoke all on function public.update_follow_counts() from public;
revoke all on function public.update_stamp_like_count() from public;
revoke all on function public.update_stamp_comment_count() from public;
revoke all on function public.update_stamp_save_count() from public;

update public.profiles p set
  follower_count  = (select count(*) from public.follows f where f.following_id = p.id),
  following_count = (select count(*) from public.follows f where f.follower_id  = p.id);

update public.stamps s set
  like_count    = (select count(*) from public.stamp_likes    l where l.stamp_id = s.id),
  comment_count = (select count(*) from public.stamp_comments c where c.stamp_id = s.id),
  save_count    = (select count(*) from public.stamp_saves    v where v.stamp_id = s.id);
