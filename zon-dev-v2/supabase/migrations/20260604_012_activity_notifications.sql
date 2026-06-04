-- 012 — Activity feed. Applied via MCP 2026-06-04.
-- notification_log is populated by SECURITY DEFINER triggers so clients never
-- insert notifications directly (RLS stays select/update-own).

create policy "Users update own notifications" on public.notification_log
  for update using ((select auth.uid()) = user_id);

create or replace function public.notify_on_like()
returns trigger language plpgsql security definer set search_path = '' as $$
declare owner uuid;
begin
  select user_id into owner from public.stamps where id = NEW.stamp_id;
  if owner is not null and owner <> NEW.user_id then
    insert into public.notification_log(user_id, type, payload)
    values (owner, 'like',
      jsonb_build_object('actor_id', NEW.user_id, 'stamp_id', NEW.stamp_id));
  end if;
  return null;
end; $$;
create trigger notify_like_trigger after insert on public.stamp_likes
  for each row execute function public.notify_on_like();

create or replace function public.notify_on_comment()
returns trigger language plpgsql security definer set search_path = '' as $$
declare owner uuid;
begin
  select user_id into owner from public.stamps where id = NEW.stamp_id;
  if owner is not null and owner <> NEW.user_id then
    insert into public.notification_log(user_id, type, payload)
    values (owner, 'comment', jsonb_build_object(
      'actor_id', NEW.user_id, 'stamp_id', NEW.stamp_id, 'comment_id', NEW.id));
  end if;
  return null;
end; $$;
create trigger notify_comment_trigger after insert on public.stamp_comments
  for each row execute function public.notify_on_comment();

create or replace function public.notify_on_follow()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notification_log(user_id, type, payload)
  values (NEW.following_id, 'follow',
    jsonb_build_object('actor_id', NEW.follower_id));
  return null;
end; $$;
create trigger notify_follow_trigger after insert on public.follows
  for each row execute function public.notify_on_follow();

create or replace function public.notify_on_stamp_tags()
returns trigger language plpgsql security definer set search_path = '' as $$
declare uid uuid;
begin
  foreach uid in array NEW.tagged_user_ids loop
    if uid <> NEW.user_id then
      insert into public.notification_log(user_id, type, payload)
      values (uid, 'tag',
        jsonb_build_object('actor_id', NEW.user_id, 'stamp_id', NEW.id));
    end if;
  end loop;
  return null;
end; $$;
create trigger notify_stamp_tags_trigger after insert on public.stamps
  for each row execute function public.notify_on_stamp_tags();

create or replace function public.create_mention_notification(
  p_target uuid, p_stamp uuid, p_comment uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_target = auth.uid() then return; end if;
  insert into public.notification_log(user_id, type, payload)
  values (p_target, 'mention', jsonb_build_object(
    'actor_id', auth.uid(), 'stamp_id', p_stamp, 'comment_id', p_comment));
end; $$;
