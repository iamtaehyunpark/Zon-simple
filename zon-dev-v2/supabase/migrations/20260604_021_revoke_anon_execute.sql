-- 021 — Revoke anon EXECUTE on SECURITY DEFINER functions. Applied via MCP 2026-06-04.
-- anon never fires these triggers and shouldn't call them over REST. Triggers
-- still fire regardless of EXECUTE grants; the two RPCs keep `authenticated`.
revoke all on function public.notify_on_like() from anon;
revoke all on function public.notify_on_comment() from anon;
revoke all on function public.notify_on_follow() from anon;
revoke all on function public.notify_on_stamp_tags() from anon;
revoke all on function public.update_follow_counts() from anon;
revoke all on function public.update_stamp_like_count() from anon;
revoke all on function public.update_stamp_comment_count() from anon;
revoke all on function public.update_stamp_save_count() from anon;
revoke all on function public.create_mention_notification(uuid, uuid, uuid) from anon;
revoke all on function public.shared_check_ins_for_day(date) from anon;
