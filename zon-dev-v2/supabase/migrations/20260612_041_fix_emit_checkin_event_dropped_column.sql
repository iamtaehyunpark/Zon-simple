-- ============================================================
-- 041 — HOTFIX. emit_checkin_event (038) referenced check_ins.tz_offset_min,
-- which was dropped in migration 019 (drop_unused_tz_offset). The AFTER INSERT
-- trigger therefore aborted every check_ins insert. Remove the dead reference.
--
-- (Reconstructed from the remote migration history — was originally applied via
--  MCP without a local file. Matches version 20260612043355.)
-- ============================================================
create or replace function public.emit_checkin_event()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform public.emit_event(
    new.user_id, 'checkin_created', 'check_in', new.id, new.place_id,
    jsonb_build_object(
      'source', new.source, 'visibility', new.visibility,
      'visited_at', new.visited_at, 'geohash7', new.geohash7));
  return null;
end;
$$;
revoke all on function public.emit_checkin_event() from public, anon, authenticated;
