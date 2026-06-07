-- ============================================================
-- 010 — Check-in layer + Phase feature columns
-- Applied via MCP on 2026-06-04.
--
-- check_ins = the private visit-log / trace-pin layer.
-- A stamp is promoted from at most one check-in (stamp ⊂ check-in).
-- ============================================================

create type checkin_source as enum ('manual', 'photo', 'auto');

create table public.check_ins (
  id                    uuid primary key default uuid_generate_v4(),
  user_id               uuid not null references public.profiles(id) on delete cascade,
  place_name            text not null,
  normalized_place_name text,
  lat                   double precision not null,
  lng                   double precision not null,
  geo                   geometry(Point, 4326),
  external_place_id     text,
  external_source       text,
  note                  text,
  source                checkin_source not null default 'manual',
  tagged_user_ids       uuid[] not null default '{}',
  photo_count           int not null default 0,
  visited_at            timestamptz not null,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create or replace function public.sync_checkin_geo()
returns trigger language plpgsql
set search_path = ''
as $$
begin
  new.geo := public.ST_SetSRID(public.ST_MakePoint(new.lng, new.lat), 4326);
  return new;
end;
$$;

create trigger checkin_geo_trigger
before insert or update on public.check_ins
for each row execute function public.sync_checkin_geo();

create index check_ins_user_time_idx on public.check_ins(user_id, visited_at desc);
create index check_ins_geo_idx on public.check_ins using gist(geo);

alter table public.check_ins enable row level security;
create policy "Users manage own check-ins" on public.check_ins
  for all using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Tagged users can view check-ins" on public.check_ins
  for select using ((select auth.uid()) = any(tagged_user_ids));

-- stamps ← check_in (promote: 1 check-in → at most 1 stamp)
alter table public.stamps add column check_in_id uuid references public.check_ins(id) on delete set null;
create unique index stamps_check_in_id_key on public.stamps(check_in_id) where check_in_id is not null;

-- photos can belong to a check-in (in addition to / instead of a stamp)
alter table public.photos add column check_in_id uuid references public.check_ins(id) on delete set null;
create index photos_check_in_id_idx on public.photos(check_in_id) where check_in_id is not null;

create or replace function public.update_checkin_photo_count()
returns trigger language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' and new.check_in_id is not null then
    update public.check_ins set photo_count = photo_count + 1 where id = new.check_in_id;
  elsif tg_op = 'DELETE' and old.check_in_id is not null then
    update public.check_ins set photo_count = photo_count - 1 where id = old.check_in_id;
  elsif tg_op = 'UPDATE' and old.check_in_id is distinct from new.check_in_id then
    if old.check_in_id is not null then update public.check_ins set photo_count = photo_count - 1 where id = old.check_in_id; end if;
    if new.check_in_id is not null then update public.check_ins set photo_count = photo_count + 1 where id = new.check_in_id; end if;
  end if;
  return null;
end;
$$;

create trigger checkin_photo_count_trigger after insert or update or delete on public.photos
for each row execute function public.update_checkin_photo_count();

-- Snapchat-style map opt-in (granular audience = later)
alter table public.user_privacy add column location_sharing_enabled bool not null default false;

-- check-ins for a given day (timeline + map)
create or replace function public.check_ins_for_day(p_user_id uuid, p_date date)
returns setof public.check_ins language sql stable
set search_path = ''
as $$
  select * from public.check_ins
  where user_id = p_user_id
    and visited_at >= p_date::timestamptz
    and visited_at < (p_date + interval '1 day')::timestamptz
  order by visited_at asc;
$$;
