-- Add per-type notification preference columns to user_privacy.
-- Defaults to true (opt-out model) to preserve existing users' experience.
alter table public.user_privacy
  add column if not exists notify_likes            bool not null default true,
  add column if not exists notify_comments         bool not null default true,
  add column if not exists notify_friend_requests  bool not null default true;
