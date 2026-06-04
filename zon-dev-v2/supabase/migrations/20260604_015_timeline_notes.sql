-- 015 — Timeline note nodes. Applied via MCP 2026-06-04.
-- Free-text notes the user drops into a day between check-ins (by noted_at).
create table public.timeline_notes (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  date       date not null,
  body       text not null,
  noted_at   timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index timeline_notes_user_date_idx on public.timeline_notes(user_id, date);
alter table public.timeline_notes enable row level security;
create policy "Users manage own timeline notes" on public.timeline_notes
  for all using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
