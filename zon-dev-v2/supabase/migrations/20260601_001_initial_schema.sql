-- ============================================================
-- ZON v2.0 — Full Initial Schema
-- Applied via MCP on 2026-06-01
-- ============================================================

-- Extensions
create extension if not exists "uuid-ossp";
create extension if not exists "postgis";

-- Enums
create type location_source as enum ('gps', 'exif', 'cell_tower');
create type stamp_visibility as enum ('private', 'public');

-- ============================================================
-- PROFILES
-- ============================================================
create table public.profiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  username         text unique not null,
  display_name     text,
  avatar_url       text,
  bio              text,
  stamp_count      int not null default 0,
  public_stamp_count int not null default 0,
  follower_count   int not null default 0,
  following_count  int not null default 0,
  country_count    int not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

alter table public.profiles enable row level security;
create policy "Public profiles viewable by everyone" on public.profiles for select using (true);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

-- ============================================================
-- RAW LOCATION EVENTS
-- ============================================================
create table public.raw_location_events (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  lat             double precision not null,
  lng             double precision not null,
  accuracy_m      float,
  altitude_m      float,
  source          location_source not null,
  captured_at     timestamptz not null,
  received_at     timestamptz not null default now(),
  photo_id        uuid,
  stamp_id        uuid,
  geocoded_name   text,
  geo             geometry(Point, 4326)
);

create or replace function sync_raw_event_geo()
returns trigger language plpgsql as $$
begin
  NEW.geo := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326);
  return NEW;
end;
$$;

create trigger raw_event_geo_trigger
before insert or update on public.raw_location_events
for each row execute function sync_raw_event_geo();

create index raw_events_user_time_idx on public.raw_location_events(user_id, captured_at desc);
create index raw_events_geo_idx on public.raw_location_events using gist(geo);
create index raw_events_stamp_id_idx on public.raw_location_events(stamp_id) where stamp_id is not null;

alter table public.raw_location_events enable row level security;
create policy "Users can view own events only" on public.raw_location_events for select using (auth.uid() = user_id);
create policy "Users can insert own events" on public.raw_location_events for insert with check (auth.uid() = user_id);
create policy "Users can update own events" on public.raw_location_events for update using (auth.uid() = user_id);
create policy "Users can delete own events" on public.raw_location_events for delete using (auth.uid() = user_id);

-- ============================================================
-- STAMPS
-- ============================================================
create table public.stamps (
  id                    uuid primary key default uuid_generate_v4(),
  user_id               uuid not null references public.profiles(id) on delete cascade,
  place_name            text not null,
  normalized_place_name text,
  lat                   double precision not null,
  lng                   double precision not null,
  geo                   geometry(Point, 4326),
  external_place_id     text,
  external_source       text,
  visibility            stamp_visibility not null default 'private',
  cover_photo_url       text,
  caption               text,
  sensory_tags          text[] not null default '{}',
  tagged_user_ids       uuid[] not null default '{}',
  visited_at            timestamptz not null,
  like_count            int not null default 0,
  comment_count         int not null default 0,
  save_count            int not null default 0,
  photo_count           int not null default 0,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create or replace function sync_stamp_geo()
returns trigger language plpgsql as $$
begin
  NEW.geo := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326);
  return NEW;
end;
$$;

create trigger stamp_geo_trigger
before insert or update on public.stamps
for each row execute function sync_stamp_geo();

create index stamps_user_id_idx on public.stamps(user_id, visited_at desc);
create index stamps_geo_idx on public.stamps using gist(geo);
create index stamps_public_idx on public.stamps(user_id, visited_at desc) where visibility = 'public';
create index stamps_feed_idx on public.stamps(visited_at desc) where visibility = 'public';
create index stamps_timeline_idx on public.stamps(user_id, visited_at desc);

alter table public.stamps enable row level security;
create policy "Users can view own private stamps" on public.stamps for select using (auth.uid() = user_id and visibility = 'private');
create policy "Public stamps viewable by everyone" on public.stamps for select using (visibility = 'public');
create policy "Tagged users can view stamps" on public.stamps for select using (auth.uid() = any(tagged_user_ids));
create policy "Users can insert own stamps" on public.stamps for insert with check (auth.uid() = user_id);
create policy "Users can update own stamps" on public.stamps for update using (auth.uid() = user_id);
create policy "Users can delete own stamps" on public.stamps for delete using (auth.uid() = user_id);

create or replace function update_profile_stamp_counts()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'INSERT' then
    update public.profiles set stamp_count = stamp_count + 1,
      public_stamp_count = public_stamp_count + case when NEW.visibility = 'public' then 1 else 0 end
    where id = NEW.user_id;
  elsif TG_OP = 'DELETE' then
    update public.profiles set stamp_count = stamp_count - 1,
      public_stamp_count = public_stamp_count - case when OLD.visibility = 'public' then 1 else 0 end
    where id = OLD.user_id;
  elsif TG_OP = 'UPDATE' and OLD.visibility != NEW.visibility then
    update public.profiles set public_stamp_count = public_stamp_count
      + case when NEW.visibility = 'public' then 1 else -1 end
    where id = NEW.user_id;
  end if;
  return null;
end;
$$;

create trigger stamp_count_trigger after insert or update or delete on public.stamps
for each row execute function update_profile_stamp_counts();

-- ============================================================
-- PHOTOS
-- ============================================================
create table public.photos (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  stamp_id        uuid references public.stamps(id) on delete set null,
  storage_url     text not null,
  thumbnail_url   text,
  width           int,
  height          int,
  exif_lat        double precision,
  exif_lng        double precision,
  exif_taken_at   timestamptz,
  exif_geo        geometry(Point, 4326),
  raw_event_id    uuid references public.raw_location_events(id) on delete set null,
  created_at      timestamptz not null default now()
);

create or replace function sync_photo_exif_geo()
returns trigger language plpgsql as $$
begin
  if NEW.exif_lat is not null and NEW.exif_lng is not null then
    NEW.exif_geo := ST_SetSRID(ST_MakePoint(NEW.exif_lng, NEW.exif_lat), 4326);
  else
    NEW.exif_geo := null;
  end if;
  return NEW;
end;
$$;

create trigger photo_exif_geo_trigger before insert or update on public.photos
for each row execute function sync_photo_exif_geo();

create index photos_user_id_idx on public.photos(user_id, created_at desc);
create index photos_stamp_id_idx on public.photos(stamp_id) where stamp_id is not null;
create index photos_unlinked_idx on public.photos(user_id, exif_taken_at desc) where stamp_id is null and exif_lat is not null;
create index photos_exif_geo_idx on public.photos using gist(exif_geo) where exif_geo is not null;

alter table public.photos enable row level security;
create policy "Users can view own photos" on public.photos for select using (auth.uid() = user_id);
create policy "Public stamp photos viewable by everyone" on public.photos for select using (
  stamp_id is not null and exists (select 1 from public.stamps s where s.id = stamp_id and s.visibility = 'public')
);
create policy "Users can insert own photos" on public.photos for insert with check (auth.uid() = user_id);
create policy "Users can update own photos" on public.photos for update using (auth.uid() = user_id);
create policy "Users can delete own photos" on public.photos for delete using (auth.uid() = user_id);

create or replace function update_stamp_photo_count()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'INSERT' and NEW.stamp_id is not null then
    update public.stamps set photo_count = photo_count + 1 where id = NEW.stamp_id;
  elsif TG_OP = 'DELETE' and OLD.stamp_id is not null then
    update public.stamps set photo_count = photo_count - 1 where id = OLD.stamp_id;
  elsif TG_OP = 'UPDATE' then
    if OLD.stamp_id is not null then update public.stamps set photo_count = photo_count - 1 where id = OLD.stamp_id; end if;
    if NEW.stamp_id is not null then update public.stamps set photo_count = photo_count + 1 where id = NEW.stamp_id; end if;
  end if;
  return null;
end;
$$;

create trigger photo_count_trigger after insert or update or delete on public.photos
for each row execute function update_stamp_photo_count();

alter table public.raw_location_events
  add constraint fk_raw_events_photo foreign key (photo_id) references public.photos(id) on delete set null,
  add constraint fk_raw_events_stamp foreign key (stamp_id) references public.stamps(id) on delete set null;

-- ============================================================
-- SOCIAL TABLES
-- ============================================================
create table public.stamp_likes (
  stamp_id    uuid not null references public.stamps(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (stamp_id, user_id)
);
alter table public.stamp_likes enable row level security;
create policy "Likes viewable by everyone" on public.stamp_likes for select using (true);
create policy "Users manage own likes" on public.stamp_likes for all using (auth.uid() = user_id);

create or replace function update_stamp_like_count()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'INSERT' then update public.stamps set like_count = like_count + 1 where id = NEW.stamp_id;
  elsif TG_OP = 'DELETE' then update public.stamps set like_count = like_count - 1 where id = OLD.stamp_id;
  end if;
  return null;
end;
$$;
create trigger stamp_like_count_trigger after insert or delete on public.stamp_likes for each row execute function update_stamp_like_count();

create table public.stamp_comments (
  id          uuid primary key default uuid_generate_v4(),
  stamp_id    uuid not null references public.stamps(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  parent_id   uuid references public.stamp_comments(id) on delete cascade,
  body        text not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index comments_stamp_id_idx on public.stamp_comments(stamp_id, created_at);
alter table public.stamp_comments enable row level security;
create policy "Comments on public stamps viewable by everyone" on public.stamp_comments for select using (
  exists (select 1 from public.stamps s where s.id = stamp_id and s.visibility = 'public') or auth.uid() = user_id
);
create policy "Authenticated users can comment" on public.stamp_comments for insert with check (auth.uid() = user_id);
create policy "Users update own comments" on public.stamp_comments for update using (auth.uid() = user_id);
create policy "Users delete own comments" on public.stamp_comments for delete using (auth.uid() = user_id);

create or replace function update_stamp_comment_count()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'INSERT' then update public.stamps set comment_count = comment_count + 1 where id = NEW.stamp_id;
  elsif TG_OP = 'DELETE' then update public.stamps set comment_count = comment_count - 1 where id = OLD.stamp_id;
  end if;
  return null;
end;
$$;
create trigger stamp_comment_count_trigger after insert or delete on public.stamp_comments for each row execute function update_stamp_comment_count();

create table public.stamp_saves (
  stamp_id    uuid not null references public.stamps(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (stamp_id, user_id)
);
alter table public.stamp_saves enable row level security;
create policy "Users manage own saves" on public.stamp_saves for all using (auth.uid() = user_id);

create or replace function update_stamp_save_count()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'INSERT' then update public.stamps set save_count = save_count + 1 where id = NEW.stamp_id;
  elsif TG_OP = 'DELETE' then update public.stamps set save_count = save_count - 1 where id = OLD.stamp_id;
  end if;
  return null;
end;
$$;
create trigger stamp_save_count_trigger after insert or delete on public.stamp_saves for each row execute function update_stamp_save_count();

create table public.follows (
  follower_id   uuid not null references public.profiles(id) on delete cascade,
  following_id  uuid not null references public.profiles(id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);
alter table public.follows enable row level security;
create policy "Follows viewable by everyone" on public.follows for select using (true);
create policy "Users manage own follows" on public.follows for all using (auth.uid() = follower_id);

create or replace function update_follow_counts()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'INSERT' then
    update public.profiles set following_count = following_count + 1 where id = NEW.follower_id;
    update public.profiles set follower_count = follower_count + 1 where id = NEW.following_id;
  elsif TG_OP = 'DELETE' then
    update public.profiles set following_count = following_count - 1 where id = OLD.follower_id;
    update public.profiles set follower_count = follower_count - 1 where id = OLD.following_id;
  end if;
  return null;
end;
$$;
create trigger follow_count_trigger after insert or delete on public.follows for each row execute function update_follow_counts();

-- ============================================================
-- COMPANION, NOTIFICATIONS, FCM, PRIVACY
-- ============================================================
create table public.companion_sessions (
  id              uuid primary key default uuid_generate_v4(),
  user_a_id       uuid not null references public.profiles(id) on delete cascade,
  user_b_id       uuid not null references public.profiles(id) on delete cascade,
  started_at      timestamptz not null,
  ended_at        timestamptz,
  duration_min    int,
  distance_m      float,
  check (user_a_id < user_b_id)
);
alter table public.companion_sessions enable row level security;
create policy "Users can view own companion sessions" on public.companion_sessions for select
  using (auth.uid() = user_a_id or auth.uid() = user_b_id);

create table public.notification_log (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  type            text not null,
  payload         jsonb,
  sent_at         timestamptz not null default now(),
  tapped          bool not null default false,
  resulted_in_stamp bool not null default false
);
create index notif_log_user_idx on public.notification_log(user_id, sent_at desc);
alter table public.notification_log enable row level security;
create policy "Users view own notification log" on public.notification_log for select using (auth.uid() = user_id);

create table public.fcm_tokens (
  user_id     uuid not null references public.profiles(id) on delete cascade,
  token       text not null,
  platform    text not null default 'ios',
  updated_at  timestamptz not null default now(),
  primary key (user_id, token)
);
alter table public.fcm_tokens enable row level security;
create policy "Users manage own fcm tokens" on public.fcm_tokens for all using (auth.uid() = user_id);

create table public.user_privacy (
  user_id                   uuid primary key references public.profiles(id) on delete cascade,
  default_stamp_visibility  stamp_visibility not null default 'private',
  significant_change_enabled bool not null default true,
  photo_auto_suggest        bool not null default true,
  evening_summary_enabled   bool not null default true,
  evening_summary_time      time not null default '20:00:00',
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);
alter table public.user_privacy enable row level security;
create policy "Users manage own privacy settings" on public.user_privacy for all using (auth.uid() = user_id);

-- ============================================================
-- FUNCTIONS & VIEWS
-- ============================================================
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
declare
  v_username text;
begin
  v_username := coalesce(
    NEW.raw_user_meta_data->>'preferred_username',
    NEW.raw_user_meta_data->>'user_name',
    split_part(NEW.email, '@', 1),
    'user_' || substr(NEW.id::text, 1, 8)
  );
  while exists (select 1 from public.profiles where username = v_username) loop
    v_username := v_username || '_' || floor(random() * 1000)::text;
  end loop;
  insert into public.profiles (id, username, display_name, avatar_url)
  values (NEW.id, v_username,
    coalesce(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
    NEW.raw_user_meta_data->>'avatar_url');
  insert into public.user_privacy (user_id) values (NEW.id);
  return NEW;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.stamps_within_radius(
  p_user_id uuid, user_lat double precision, user_lng double precision, radius_m double precision default 100
)
returns setof public.stamps language sql stable as $$
  select * from public.stamps
  where user_id = p_user_id
    and ST_DWithin(geo::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_m)
  order by ST_Distance(geo::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography);
$$;

create or replace function public.route_events_for_day(p_user_id uuid, p_date date)
returns setof public.raw_location_events language sql stable as $$
  select * from public.raw_location_events
  where user_id = p_user_id
    and captured_at >= p_date::timestamptz
    and captured_at < (p_date + interval '1 day')::timestamptz
  order by captured_at asc;
$$;

create or replace function public.unlinked_photos_for_day(p_user_id uuid, p_date date)
returns setof public.photos language sql stable as $$
  select * from public.photos
  where user_id = p_user_id and stamp_id is null and exif_lat is not null
    and exif_taken_at >= p_date::timestamptz
    and exif_taken_at < (p_date + interval '1 day')::timestamptz
  order by exif_taken_at asc;
$$;

create or replace function public.can_send_notification(p_user_id uuid, p_type text, cooldown_minutes int default 30)
returns bool language sql stable as $$
  select not exists (
    select 1 from public.notification_log
    where user_id = p_user_id and type = p_type
      and sent_at > now() - (cooldown_minutes || ' minutes')::interval
  );
$$;

create or replace view public.v_feed_stamps as
  select s.*, p.username, p.display_name, p.avatar_url
  from public.stamps s join public.profiles p on p.id = s.user_id
  where s.visibility = 'public';

create or replace view public.v_timeline_summary as
  select user_id, visited_at::date as visit_date, count(*) as stamp_count
  from public.stamps group by user_id, visited_at::date;

-- ============================================================
-- STORAGE POLICIES
-- ============================================================
create policy "Public photo read" on storage.objects for select using (bucket_id = 'photos');
create policy "Users upload own photos" on storage.objects for insert
  with check (bucket_id = 'photos' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Users delete own photos" on storage.objects for delete
  using (bucket_id = 'photos' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Public thumbnail read" on storage.objects for select using (bucket_id = 'thumbnails');
create policy "Users upload own thumbnails" on storage.objects for insert
  with check (bucket_id = 'thumbnails' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Public avatar read" on storage.objects for select using (bucket_id = 'avatars');
create policy "Users upload own avatars" on storage.objects for insert
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Users update own avatars" on storage.objects for update
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
