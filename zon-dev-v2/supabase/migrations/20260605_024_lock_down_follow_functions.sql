-- ============================================================
-- 024 — Lock down SECURITY DEFINER functions from migration 023.
-- Trigger functions fire under the table owner regardless of EXECUTE
-- grants, so no role needs to call them via the REST API. can_view_user
-- is referenced by the stamps RLS policy, so authenticated must keep
-- EXECUTE — but anon never should.
-- ============================================================

revoke all on function public.can_view_user(uuid) from anon;

revoke all on function public.enforce_follow_status() from public, anon, authenticated;
revoke all on function public.update_follow_counts() from public, anon, authenticated;
revoke all on function public.notify_on_follow() from public, anon, authenticated;
