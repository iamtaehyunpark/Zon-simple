-- ============================================================
-- 038 — Append-only behavioral event log (outbox).
--
-- The BM should NOT be computed off mutable OLTP rows (updated_at, trigger
-- counters). This is an immutable fact stream: every meaningful action emits one
-- append-only row. A downstream sink (warehouse / pgmq consumer / logical
-- replication via wal2json — all available on this instance) drains it.
--
-- This migration creates the log + emitters. Wiring it to an external warehouse
-- is a separate infra step (see note at bottom).
-- ============================================================

create table public.event_log (
  id           bigint generated always as identity primary key,
  user_id      uuid references public.profiles(id) on delete set null,
  event_type   text not null,        -- 'checkin_created' | 'stamp_promoted' | 'visit_derived' | ...
  entity_type  text,                 -- 'check_in' | 'stamp' | 'visit' | 'place'
  entity_id    uuid,
  place_id     uuid,
  payload      jsonb,
  occurred_at  timestamptz not null default now()
);

create index event_log_time_idx  on public.event_log(occurred_at);
create index event_log_type_idx  on public.event_log(event_type, occurred_at);
create index event_log_user_idx  on public.event_log(user_id, occurred_at);

-- Append-only & service-only: no user-facing read/write. RLS on with zero
-- policies = authenticated/anon get nothing; emitters are SECURITY DEFINER.
alter table public.event_log enable row level security;
revoke all on public.event_log from anon, authenticated;

-- generic emitter
create or replace function public.emit_event(
  p_user_id uuid, p_type text, p_entity_type text, p_entity_id uuid,
  p_place_id uuid, p_payload jsonb)
returns void language sql security definer set search_path = '' as $$
  insert into public.event_log (user_id, event_type, entity_type, entity_id, place_id, payload)
  values (p_user_id, p_type, p_entity_type, p_entity_id, p_place_id, p_payload);
$$;

-- ── emit on check-in create ───────────────────────────────────────────────────
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
create trigger checkin_emit_trigger after insert on public.check_ins
for each row execute function public.emit_checkin_event();

-- ── emit on stamp create (promotion) ──────────────────────────────────────────
create or replace function public.emit_stamp_event()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform public.emit_event(
    new.user_id, 'stamp_promoted', 'stamp', new.id, new.place_id,
    jsonb_build_object(
      'check_in_id', new.check_in_id, 'visibility', new.visibility,
      'sensory_tags', new.sensory_tags, 'visited_at', new.visited_at));
  return null;
end;
$$;
create trigger stamp_emit_trigger after insert on public.stamps
for each row execute function public.emit_stamp_event();

-- ── emit on visit derivation ──────────────────────────────────────────────────
create or replace function public.emit_visit_event()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform public.emit_event(
    new.user_id, 'visit_derived', 'visit', new.id, new.place_id,
    jsonb_build_object(
      'arrived_at', new.arrived_at, 'dwell_min', new.dwell_min,
      'point_count', new.point_count, 'geohash7', new.geohash7));
  return null;
end;
$$;
create trigger visit_emit_trigger after insert on public.visits
for each row execute function public.emit_visit_event();

-- ── Sink / retention notes ────────────────────────────────────────────────────
-- • pg_partman is available — partition event_log by month once volume grows:
--     select partman.create_parent('public.event_log', 'occurred_at', 'native', 'monthly');
-- • Drain options on this instance: pgmq (queue), wal2json (logical CDC), or a
--   scheduled pg_cron job COPYing new rows to the warehouse.
-- • The BM warehouse target (BigQuery / ClickHouse / etc.) is an infra decision,
--   not modeled here. event_log is the contract boundary.
