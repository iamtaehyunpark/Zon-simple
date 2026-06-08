-- Enable RLS on friendships
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- Grant permissions to authenticated and service_role to ensure API is exposed (prevents 404)
GRANT ALL ON public.friendships TO authenticated;
GRANT ALL ON public.friendships TO service_role;
GRANT SELECT ON public.friendships TO anon;

-- Drop existing policies if they exist to prevent conflicts
DROP POLICY IF EXISTS "Friendships viewable by involved users" ON public.friendships;
DROP POLICY IF EXISTS "Users can insert own friendship requests" ON public.friendships;
DROP POLICY IF EXISTS "Users can update own friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can delete own friendships" ON public.friendships;

-- 1. SELECT policy: Users can view friendships they are part of
CREATE POLICY "Friendships viewable by involved users" ON public.friendships
  FOR SELECT USING (
    auth.uid() = user_a OR auth.uid() = user_b
  );

-- 2. INSERT policy: Users can insert a friendship request where they are a party and the requester
CREATE POLICY "Users can insert own friendship requests" ON public.friendships
  FOR INSERT WITH CHECK (
    (auth.uid() = user_a OR auth.uid() = user_b)
    AND auth.uid() = requested_by
    AND status = 'pending'
  );

-- 3. UPDATE policy: Target user can update the friendship request (e.g. status='accepted')
CREATE POLICY "Users can update own friendships" ON public.friendships
  FOR UPDATE USING (
    (auth.uid() = user_a OR auth.uid() = user_b)
    AND auth.uid() != requested_by
  ) WITH CHECK (
    status = 'accepted'
  );

-- 4. DELETE policy: Either involved user can delete the friendship row (unsend request, reject, or unfriend)
CREATE POLICY "Users can delete own friendships" ON public.friendships
  FOR DELETE USING (
    auth.uid() = user_a OR auth.uid() = user_b
  );

-- Fix notify_on_friend_request trigger function to reference public.notification_log (instead of non-existent public.notifications)
CREATE OR REPLACE FUNCTION public.notify_on_friend_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
declare
  v_recipient uuid;
  v_actor     uuid;
begin
  if TG_OP = 'INSERT' and NEW.status = 'pending' then
    v_recipient := case when NEW.requested_by = NEW.user_a then NEW.user_b else NEW.user_a end;
    v_actor     := NEW.requested_by;
    insert into public.notification_log (user_id, type, payload)
    values (v_recipient, 'friend_request', jsonb_build_object('actor_id', v_actor));
  elsif TG_OP = 'UPDATE' and OLD.status = 'pending' and NEW.status = 'accepted' then
    v_recipient := NEW.requested_by;
    v_actor     := case when NEW.requested_by = NEW.user_a then NEW.user_b else NEW.user_a end;
    insert into public.notification_log (user_id, type, payload)
    values (v_recipient, 'friend_accepted', jsonb_build_object('actor_id', v_actor));
  end if;
  return NEW;
end;
$$;
