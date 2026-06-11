-- 034 — Voice memos on the timeline.
--
-- A voice memo is a timeline_note that additionally carries an audio recording.
-- The transcribed speech is stored in `body` (so it renders exactly like a text
-- memo node) and the recording itself is referenced by `audio_url`, surfaced as
-- a playable bar beneath the transcript.

alter table public.timeline_notes
  add column if not exists audio_url text,
  add column if not exists audio_duration_ms integer;

-- ── Storage bucket for the recordings ────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('voice-memos', 'voice-memos', true)
on conflict (id) do nothing;

-- Owner-scoped CRUD: files are namespaced under the user's id ("<uid>/<file>"),
-- mirroring the photos bucket convention.
drop policy if exists "voice memos: owner insert" on storage.objects;
create policy "voice memos: owner insert"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'voice-memos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "voice memos: owner update" on storage.objects;
create policy "voice memos: owner update"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'voice-memos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "voice memos: owner delete" on storage.objects;
create policy "voice memos: owner delete"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'voice-memos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Public read (bucket is public so playback URLs resolve without signing).
drop policy if exists "voice memos: public read" on storage.objects;
create policy "voice memos: public read"
  on storage.objects for select to public
  using (bucket_id = 'voice-memos');
