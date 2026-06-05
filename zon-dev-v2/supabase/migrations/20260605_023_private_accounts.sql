-- ============================================================
-- 023 — Private accounts + follow requests. Applied via MCP 2026-06-05.
--
-- Adds account privacy, a pending/accepted follow status with an
-- approval flow, privacy-aware stamp visibility, and server-enforced
-- status so the approval gate can't be bypassed from the client.
-- Public check-ins will reuse can_view_user() in a follow-up.
-- ============================================================

-- 1. Schema -------------------------------------------------------
alter table public.profiles
  add column if not exists is_private boolean not null default false;

alter table public.follows
  add column if not exists status text not null default 'accepted'
  check (status in ('pending', 'accepted'));
-- Existing follows are already real follows → keep them 'accepted' (the default).

-- 2. Server-enforced follow status -------------------------------
-- The target's privacy — not the client — decides pending vs accepted on insert.
create or replace function public.enforce_follow_status()
returns trigger language plpgsql security definer set search_path = '' as $$
declare target_private boolean;
begin
  select is_private into target_private from public.profiles where id = NEW.following_id;
  NEW.status := case when coalesce(target_private, false) then 'pending' else 'accepted' end;
  return NEW;
end; $$;

drop trigger if exists enforce_follow_status_trigger on public.follows;
create trigger enforce_follow_status_trigger before insert on public.follows
for each row execute function public.enforce_follow_status();

-- 3. Counts: only accepted edges count ---------------------------
create or replace function public.update_follow_counts()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if TG_OP = 'INSERT' then
    if NEW.status = 'accepted' then
      update public.profiles set following_count = following_count + 1 where id = NEW.follower_id;
      update public.profiles set follower_count = follower_count + 1 where id = NEW.following_id;
    end if;
  elsif TG_OP = 'DELETE' then
    if OLD.status = 'accepted' then
      update public.profiles set following_count = following_count - 1 where id = OLD.follower_id;
      update public.profiles set follower_count = follower_count - 1 where id = OLD.following_id;
    end if;
  elsif TG_OP = 'UPDATE' and OLD.status is distinct from NEW.status then
    if NEW.status = 'accepted' then
      update public.profiles set following_count = following_count + 1 where id = NEW.follower_id;
      update public.profiles set follower_count = follower_count + 1 where id = NEW.following_id;
    else
      update public.profiles set following_count = following_count - 1 where id = NEW.follower_id;
      update public.profiles set follower_count = follower_count - 1 where id = NEW.following_id;
    end if;
  end if;
  return null;
end; $$;

drop trigger if exists follow_count_trigger on public.follows;
create trigger follow_count_trigger after insert or update or delete on public.follows
for each row execute function public.update_follow_counts();

-- 4. Notifications: only when a follow is actually established ----
-- Public follow → notify the target. Request accepted → notify the requester.
create or replace function public.notify_on_follow()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if TG_OP = 'INSERT' and NEW.status = 'accepted' then
    insert into public.notification_log(user_id, type, payload)
    values (NEW.following_id, 'follow', jsonb_build_object('actor_id', NEW.follower_id));
  elsif TG_OP = 'UPDATE' and OLD.status = 'pending' and NEW.status = 'accepted' then
    insert into public.notification_log(user_id, type, payload)
    values (NEW.follower_id, 'follow_accepted', jsonb_build_object('actor_id', NEW.following_id));
  end if;
  return null;
end; $$;

drop trigger if exists notify_follow_trigger on public.follows;
create trigger notify_follow_trigger after insert or update on public.follows
for each row execute function public.notify_on_follow();

-- 5. Follows RLS: follower may insert/cancel; only target may approve ----
drop policy if exists "Users manage own follows" on public.follows;
create policy "Followers insert own follows" on public.follows
  for insert with check ((select auth.uid()) = follower_id);
create policy "Followers delete own follows" on public.follows
  for delete using ((select auth.uid()) = follower_id);
create policy "Targets approve incoming follows" on public.follows
  for update using ((select auth.uid()) = following_id)
  with check ((select auth.uid()) = following_id);
create policy "Targets deny incoming follows" on public.follows
  for delete using ((select auth.uid()) = following_id);
-- "Follows viewable by everyone" (select using true) is left in place.

-- 6. Privacy-aware content visibility ----------------------------
-- True when the viewer may see [p_owner]'s would-be-public content: it's their
-- own, the owner is public, or the viewer is an accepted follower.
create or replace function public.can_view_user(p_owner uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce(p_owner = (select auth.uid()), false)
    or exists (select 1 from public.profiles pr
               where pr.id = p_owner and pr.is_private = false)
    or exists (select 1 from public.follows f
               where f.following_id = p_owner
                 and f.follower_id = (select auth.uid())
                 and f.status = 'accepted');
$$;
revoke all on function public.can_view_user(uuid) from public;
grant execute on function public.can_view_user(uuid) to authenticated;

drop policy if exists "Public stamps viewable by everyone" on public.stamps;
create policy "Public stamps viewable by allowed" on public.stamps
  for select using (visibility = 'public' and public.can_view_user(user_id));
