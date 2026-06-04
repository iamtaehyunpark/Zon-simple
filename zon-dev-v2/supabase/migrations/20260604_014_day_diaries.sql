-- 014 — Per-day free-text diary ("write about your day"). Applied via MCP 2026-06-04.
create table public.day_diaries (
  user_id    uuid not null references public.profiles(id) on delete cascade,
  date       date not null,
  body       text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, date)
);
alter table public.day_diaries enable row level security;
create policy "Users manage own diaries" on public.day_diaries
  for all using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
