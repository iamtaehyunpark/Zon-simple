create table public.saved_places (
  user_id           uuid references public.profiles(id) on delete cascade,
  external_place_id text not null,
  place_name        text not null,
  lat               double precision not null,
  lng               double precision not null,
  external_source   text,
  saved_at          timestamptz not null default now(),
  primary key (user_id, external_place_id)
);

alter table public.saved_places enable row level security;

create policy "Users manage own saved places" on public.saved_places
  for all using ((select auth.uid()) = user_id);
