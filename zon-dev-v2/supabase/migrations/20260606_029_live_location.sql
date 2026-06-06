-- Ghost Mode toggle on profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_ghost_mode boolean NOT NULL DEFAULT false;

-- Live location table (one row per user, upserted on each GPS update)
CREATE TABLE IF NOT EXISTS public.user_locations (
  user_id    uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  lat        double precision NOT NULL,
  lng        double precision NOT NULL,
  accuracy   real,
  heading    real,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Per-friend visibility blocklist:
-- "user_id has hidden their location from hidden_from_id"
CREATE TABLE IF NOT EXISTS public.location_hidden_from (
  user_id        uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  hidden_from_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, hidden_from_id)
);

-- Enable Realtime so friends receive live position updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_locations;

-- ── RLS ────────────────────────────────────────────────────────────────────
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_hidden_from ENABLE ROW LEVEL SECURITY;

-- Own location: full CRUD
CREATE POLICY "own location" ON public.user_locations
  FOR ALL USING (user_id = (SELECT auth.uid()));

-- Mutual friends can view if: not ghost mode + mutual friendship + not hidden from viewer
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
    AND NOT EXISTS (
      SELECT 1 FROM public.location_hidden_from lh
      WHERE lh.user_id = user_locations.user_id
        AND lh.hidden_from_id = (SELECT auth.uid())
    )
  );

-- Own hidden-list: full CRUD
CREATE POLICY "own hidden list" ON public.location_hidden_from
  FOR ALL USING (user_id = (SELECT auth.uid()));

-- Revoke direct access from anonymous
REVOKE ALL ON public.user_locations FROM anon;
REVOKE ALL ON public.location_hidden_from FROM anon;
