-- Reciprocal per-friend location hiding.
--
-- Previously `location_hidden_from (user_id, hidden_from_id)` was one-directional:
-- if A hid from B, B could no longer see A — but A could still see B.
--
-- This mirrors Ghost Mode's "if you don't share, you don't see" principle at the
-- per-friend level: if A hides their location from B, then A also loses sight of
-- B's location. The block becomes symmetric regardless of which side set it.
--
-- Enforced by adding a second NOT EXISTS clause to the friend SELECT policy:
-- deny when the *viewer* (auth.uid) has hidden the *owner* of the row.

DROP POLICY IF EXISTS "friend live locations" ON public.user_locations;

CREATE POLICY "friend live locations" ON public.user_locations
  FOR SELECT USING (
    user_id <> (SELECT auth.uid())
    AND NOT (
      SELECT p.is_ghost_mode FROM public.profiles p WHERE p.id = user_id
    )
    AND EXISTS (
      SELECT 1 FROM public.friendships f
      WHERE f.status = 'accepted'
        AND (
          (f.user_a = (SELECT auth.uid()) AND f.user_b = user_locations.user_id)
          OR
          (f.user_b = (SELECT auth.uid()) AND f.user_a = user_locations.user_id)
        )
    )
    -- Owner hid their location from the viewer (original direction)
    AND NOT EXISTS (
      SELECT 1 FROM public.location_hidden_from lh
      WHERE lh.user_id = user_locations.user_id
        AND lh.hidden_from_id = (SELECT auth.uid())
    )
    -- Viewer hid their location from the owner → reciprocal: viewer loses sight too
    AND NOT EXISTS (
      SELECT 1 FROM public.location_hidden_from lh
      WHERE lh.user_id = (SELECT auth.uid())
        AND lh.hidden_from_id = user_locations.user_id
    )
  );
