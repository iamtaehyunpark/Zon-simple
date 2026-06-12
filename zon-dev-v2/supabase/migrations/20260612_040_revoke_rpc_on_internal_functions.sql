-- ============================================================
-- 040 — Harden: revoke PostgREST RPC access on internal trigger/helper functions
-- introduced in 035–038. These are trigger bodies or service-only helpers and
-- must never be callable via /rest/v1/rpc. resolve_place stays granted to
-- authenticated (intended app entry point); derive_visits/bm_place_aggregates
-- were already revoked in their own migrations.
--
-- (Reconstructed from the remote migration history — was originally applied via
--  MCP without a local file. Matches version 20260612041350.)
-- ============================================================

revoke all on function public.emit_event(uuid, text, text, uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.emit_checkin_event()  from public, anon, authenticated;
revoke all on function public.emit_stamp_event()    from public, anon, authenticated;
revoke all on function public.emit_visit_event()    from public, anon, authenticated;
revoke all on function public.update_place_visit_count() from public, anon, authenticated;
revoke all on function public.set_checkin_place()   from public, anon, authenticated;
revoke all on function public.set_stamp_place()     from public, anon, authenticated;
revoke all on function public.sync_place_geo()      from public, anon, authenticated;
revoke all on function public.sync_visit_geo()      from public, anon, authenticated;
revoke all on function public.sync_raw_event_geo()  from public, anon, authenticated;
revoke all on function public.sync_checkin_geo()    from public, anon, authenticated;
