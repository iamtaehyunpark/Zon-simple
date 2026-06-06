# ZON — Advanced Features Plan ("Perfecting the MVP")

> Living document. Tracks the multi-phase build-out of the advanced feature set on top
> of the working MVP. Update the **Status** column as work lands. Started 2026-06-04.

## Goal

Take the working MVP (OAuth login, Kakao/Google place search, basic stamps/feed/profile,
Firebase init) and build out the advanced feature set the team listed, cleanly and
one phase at a time.

---

## 1. Core concept — the three-layer trace model

This evolves **beyond** the original `CLAUDE.md`, which had folded "Visit" into
`RawLocationEvent`. We re-introduce a **user-facing visit layer** distinct from both raw
breadcrumbs and stamps.

| Layer | Table | Role | Visibility |
|---|---|---|---|
| **Breadcrumbs** | `raw_location_events` | the continuous GPS route **line** | system, invisible |
| **Check-in** | `check_ins` *(NEW)* | discrete place **visit log** — the **pins** on the route. One-tap, can carry photos + a short note. Created manually, from photo EXIF, or auto-suggested. | always private |
| **Stamp** | `stamps` + `check_in_id` | a check-in **promoted to a post** — caption, vibe tags, public/private, likes/comments/saves. Feed + profile. | private → public |

- `stamp ⊂ check-in`: every stamp has a parent check-in (`stamps.check_in_id`, 1:1).
- You **check in first**, then optionally **promote** one check-in into a stamp.
- Photos attach to `check_ins` and **carry over** to the stamp on promotion.
- Route line = raw events · pins = check-ins · posts = stamps.

---

## 2. Locked decisions (from team Q&A, 2026-06-04)

- **Check-in shape:** always private; `place + time + optional photos + optional short note`;
  editable + deletable. Only becomes visible to others by being promoted to a stamp (or via tagging).
- **Promotion:** 1 check-in → **at most 1** stamp. Photos carry over. Check-in persists as trace.
- **Map (#11):** today-only, Snapchat-style and **social**, gated by a per-user
  **location-sharing toggle** (default OFF). My own content always shows; followed users'
  *today* check-ins/route show only if they've enabled sharing. Their **public stamps** show
  regardless (already public). Granular "who can see me" audience control = **later** (TODO seam).
- **Timeline (#9):** **single-day** view + prev/next-day arrows + calendar **picker**
  (replaces the current List/Calendar tabs + monthly chevrons). Calendar tap → that day (#10).
- **SNS this round (#13):** user search + followers/following lists + activity/notifications
  screen. **Block/report = deferred** past this round.
- **Comments (#14):** **1-level replies** (Instagram-style; replies don't nest deeper) +
  **@mention** with a user picker that **notifies** the mentioned user.
- **Tagging (G7):** tag users on **both stamps and check-ins** (Instagram post/story style);
  tagged users can view + are notified. Collaborative/shared trace = **future**.
- **Profile (#3):** stamps grid (own profile incl. **private**; others = public only).
  Plus an **entry point to my check-in list** (to promote check-ins → stamps).
- **Settings (#2):** edit profile · privacy & location · notification prefs · **delete account**
  (delete uses the existing `delete-account` edge function).
- **Dev bypass:** **removed entirely** — real Supabase session only. No `kDevMockUserId` / `isDevMode`.
- **Photo detection (#5):** build for **all paths**, extensible. Now: in-app on-open scan of
  today's new geotagged photos → dismissible banner atop Feed + local notification. Later seams:
  significant-change background + remote push (once Apple paid lands).
- **Photo import:** imported photos **always become check-ins** (drop the old orphan-photo path).

---

## 3. Audit findings (2026-06-04)

- **Live DB matches schema** (13 tables, RLS on). Real data: 1 profile, 4 stamps, 1 comment, 1 save.
- **`raw_location_events` is empty** — route pipeline is ready but never fed (dev-mock + 5-min
  batch flush meant no real foreground GPS session landed). Will populate once mock is gone.
- **Pipelines deployed + correct:** `ingest-location`, `ingest-photo-exif`, `suggest-stamp`,
  `match-place`, `geocode-nudge` all ACTIVE.
- **`delete-account` edge function already exists + ACTIVE** → settings delete just calls it.
- **Orphan v1 cruft (deployed, not in repo):** `verify-stamp`, `place-coverage`, `tier2-import`,
  `register-place` — the removed verification/consensus system. Tear down in Phase 7.
- **Security advisor:** `public.spatial_ref_sys` has RLS disabled — it's PostGIS's own system
  table (no user data); **leave as-is** (enabling RLS can break PostGIS).

---

## 4. Phased plan

Legend: ☐ todo · ◐ in progress · ☑ done

### Phase 0 — Foundation ✅
- ☑ Pipeline + live-schema audit
- ☑ DB migration `010_checkin_layer` (check_ins table, geo trigger, RLS, indexes; `stamps.check_in_id` 1:1; `photos.check_in_id` + count trigger; `user_privacy.location_sharing_enabled`; `check_ins_for_day` RPC) — **applied**
- ☑ Remove dev-mock entirely; `currentUser` made reactive to auth changes
- ☑ Models + repo: `CheckIn`/`CheckInDraft`, `CheckInRepository` (create/getForDay/getMyCheckIns/get/delete/**promoteToStamp**); `checkInId` on `Stamp`/`StampDraft`; `getSavedStamps` added
- ☑ Added `image_picker`; build_runner + analyze clean

### Phase 1 — Check-in + photo upload (the heart) — #6, #7 ✅
- ☑ `PhotoService.uploadFile(File)` (gallery `uploadPhoto` delegates to it)
- ☑ `PhotoStrip` shared picker (image_picker, local-path → upload at save) + wired into `stamp_editor` (#6)
- ☑ Two-action FAB menu in `MainShell`: Check in / Create stamp (#7)
- ☑ Mode-aware `CheckinNotifier`: check-in → `createCheckIn`; stamp → create check-in then `promoteToStamp` (#7)

### Phase 2 — Stamp modification — #4 ✅
- ☑ `EditStampScreen` (`/stamp/:id/edit`): place, caption, vibe, visibility, add/remove photos (`updateStamp` + `addStampPhotos`/`deletePhoto`/`getStampPhotos`)
- ☑ Owner edit/delete menu on stamp detail; **fixed** latent bug — photos now actually load (via `stampPhotosProvider`)

### Phase 3 — Profile — #2, #3 ✅
- ☑ Own profile shows **private** stamps (`profileStampsNotifier` gained `publicOnly`; profile passes `!isOwnProfile`) (#3)
- ☑ Check-in list (`/check-ins`, pin icon on own profile) → promote-to-stamp sheet
- ☑ `SettingsScreen` (`/settings`): edit profile (name/bio/avatar→`avatars` bucket) · privacy & location (`PrivacyRepository` on `user_privacy`, incl. location-sharing toggle) · notification prefs · sign out · **delete account** (`delete-account` fn) (#2)
- ☑ `UserProfile.displayName` added

### Phase 4 — Timeline · Calendar · Map — #8, #9, #10, #11, #15 ✅
- ☑ Timeline → single-day + prev/next + **calendar picker** (`DayBundle` = route+check-ins+stamps; `loadDay`); mini `DayRouteMap` (#8,#9,#10)
- ☑ Map = today-only + social; **fixed** all-stamps-ignoring-day bug; mine (route+stamps+check-ins) + followed (shared check-ins via RPC + public stamps) (#11)
- ☑ Tappable pins via `TapInteraction.onMap` + `queryRenderedFeatures` → bottom sheet; check-in → "Make a stamp", stamp → full page (#15)
- ☑ Migration `011_map_sharing`: `shared_check_ins_for_day` (security-definer; follows + sharing + day); shared drawing helper `map_drawing.dart`

### Phase 5 — Social — #12, #13, #14 ✅
- ☑ Bookmarks: `SavedStampsScreen` (`/saved`, bookmark icon on profile); `getSavedStamps` (#12)
- ☑ `UserSearchScreen` (`/search`, feed search icon); `searchUsers` (#13)
- ☑ Followers/Following `UserListScreen` (`/profile/:id/followers|following`); tappable profile stats; `getFollowers`/`getFollowing` (#13)
- ☑ `ActivityScreen` (`/activity`, wired the feed bell); `NotificationRepository` over `notification_log`; migration `012_activity_notifications` (DEFINER triggers for like/comment/follow/tag + mention RPC) (#13, #1)
- ☑ Comment 1-level replies (`parentId`) + @mention picker (`showUserPicker`) that notifies (#14)
- ☑ `UserTagField` on stamp **and** check-in editors; tag notifications via trigger (G7)

### Phase 6 — Photo → check-in suggestion — #5 ✅
- ☑ `PhotoService.getNewPhotosToday`; `todayPhotoSuggestions` provider
- ☑ Dismissible banner atop Feed (`_PhotoSuggestionBanner`) → review screen converts photos to **check-ins** (source=photo); orphan-photo path dropped (`processAsset` removed)
- ☑ One-shot local notification on detection (payload routes to `/photo-suggestions`)
- ◐ Significant-change background + remote push: notification routing seams already exist (`_routeForData`); full background trigger awaits Apple paid enrollment

### Phase 7 — Sweep — #1 ✅ (1 user action)
- ☑ Removed dead `processAsset`; verified no empty handlers / placeholders remain; `flutter analyze` = 0 issues
- ☑ Security pass via `get_advisors` → migration `013_harden_security` (fixed a `shared_check_ins_for_day` param-spoofing leak; locked EXECUTE on new definer fns)
- ☐ **User action:** delete orphan v1 edge functions (no MCP delete tool):
  `supabase functions delete verify-stamp place-coverage tier2-import register-place`
- ☐ **Device verify:** ingest pipeline fills the route line on a real foreground GPS session (can't run on-device from here)

---

## Phase 8 — Timeline UX + Live Map Polish ✅ (2026-06-04/05)

### 8a — Timeline UX
- ☑ Photo slides: Add button lives next to last photo only (no duplicate slide during edit)
- ☑ Swipe-to-delete nodes (`Dismissible`; check-in confirms, note immediate)
- ☑ Tap = highlight only (like map pin tap); long-press = edit/open
- ☑ `_AddNoteTile`: inline note editor (no modal), expands in-place with autofocus
- ☑ Note inline editor shows "Change time" button (consistent with check-in edit)
- ☑ `_InlineNodeEditor`: `onAddPhoto` param adds photo Add tile next to existing photos

### 8b — Map: session path + live route
- ☑ Map shows current session path only (since last app open), not full historical day
- ☑ `upsertLine()` in `map_drawing.dart`: updates GeoJSON source in-place (smooth, no flicker)
- ☑ `removeLine()`: clears stale line when session resets
- ☑ Auto check-in pins rendered tiny (r=2.5, opacity=0.55, no stroke) — trace dots, not full pins
- ☑ Timeline map still shows full historical day trace

### 8c — Auto-anchor dedup
- ☑ DB-backed per-day dedup: queries `getForDay(today)`, skips if any today check-in within 80m
- ☑ Resets naturally at midnight (no stored state, no in-memory sentinel)
- ☑ `stopTracking()` is now async, calls `_anchorPath()` at session end

### 8d — Promote-to-stamp flow
- ☑ "Promote" no longer instant — navigates to `/checkin?fromCheckIn=<id>` → stamp editor pre-filled
- ☑ `CheckinEntry.fromCheckInId` param: loads check-in + photos, calls `startStampFromCheckIn`
- ☑ `StampDraft.existingPhotoUrls`: carries over check-in photos (display-only row in stamp editor)
- ☑ On save: updates existing check-in + promotes (no duplicate row)

---

## Phase 9 — Feed + Feed Stories (Public Check-ins) ✅ (2026-06-05/06)

### 9a — Feed ordering
- ☑ `getFeedStamps` orders by `created_at` (when posted), not `visited_at` (when visited)

### 9b — Private accounts + follow requests
- ☑ Migration 023: `profiles.is_private`, `follows.status {pending|accepted}`, `enforce_follow_status` BEFORE INSERT trigger, `can_view_user()` SECURITY DEFINER function
- ☑ Migration 024: revoke anon/public from `can_view_user` + trigger functions
- ☑ `FollowState {none, requested, following}` in `profile_repository.dart`
- ☑ `ProfileRepository.follow()` returns `FollowState`; `followState()`, `getFollowRequests()`, `approveFollow()`, `denyFollow()`
- ☑ `UserProfile.isPrivate` field
- ☑ Profile screen: follow button reflects state; private non-followers see locked grid
- ☑ Settings: "Private account" SwitchListTile
- ☑ Activity screen: follow requests at top; navigates to `/follow-requests`
- ☑ `FollowRequestsScreen` at `/follow-requests`

### 9c — Public check-ins as feed stories
- ☑ Migration 025: `check_ins.visibility {private|public}`, partial index, SELECT RLS via `can_view_user`
- ☑ `CheckIn.visibility` + `CheckInDraft.visibility` fields
- ☑ `CheckInRepository.getFollowingPublicCheckIns()` (flat list for map)
- ☑ `CheckInRepository.getStories()`: last-24h public check-ins from accepted-following + self, grouped per author with photos, own first
- ☑ `feedStoriesProvider` in `feed_provider.dart`
- ☑ `_StoriesRail`: horizontal scrollable avatar list with gradient rings at top of feed
- ☑ `_StoryView`: full-screen dialog, tap left/right to page, progress bar segments, place/time/note overlay
- ☑ "Share as a story" SwitchListTile in check-in creation editor + timeline edit sheet
- ☑ Bell badge counts follow requests + (later) friend requests

---

## Phase 10 — Friends (Facebook-style) ✅ (2026-06-06)

- ☑ Migration 026: `friendships (user_a, user_b, status, requested_by)` canonical-pair table; `profiles.friend_count`; `update_friend_count` + `auto_follow_on_friendship` + `notify_on_friend_request` triggers
- ☑ `FriendState {none, requestedByMe, requestedByThem, friends}` in `profile_repository.dart`
- ☑ Friendship methods: `friendState`, `sendFriendRequest`, `removeFriendship`, `acceptFriendRequest`, `denyFriendRequest`, `getIncomingFriendRequests`, `getFriends`
- ☑ `friendStateProvider`, `friendRequestsProvider` in `profile_provider.dart`
- ☑ `ProfileNotifier`: `sendFriendRequest()`, `cancelFriendRequest()`, `unfriend()` methods
- ☑ Profile screen: 4 stats (Stamps / Friends / Followers / Following); `_SocialButtons` widget — "Add Friend" primary + "Follow" secondary; state-driven labels; popup menus for Respond / Unfriend
- ☑ Activity screen: friend requests row above follow requests; `friend_request` + `friend_accepted` notification types
- ☑ `FriendRequestsScreen` at `/friend-requests`
- ☑ `/profile/:id/friends` route via `UserListScreen(friends: true)`
- ☑ `UserListScreen` gains `friends: bool` param + `getFriends()` repo call
- ☑ Feed bell badge counts friend requests + follow requests

---

## Phase 11 — Map Social Layer + Filter ✅ (2026-06-06)

- ☑ `StampRepository.getFollowingStamps({from, to})`: range-based query against `v_feed_stamps`
- ☑ `CheckInRepository.getFollowingPublicCheckIns()`: last-24h public check-ins from followed users (flat, for map)
- ☑ `MapFilter {today, week, month, year, all, custom}` enum + `_filterRange()` in `map_screen.dart`
- ☑ Filter chips row in top card; "Custom" opens `showDateRangePicker`
- ☑ `followed-stamps-layer` (orange): following stamps in filter window
- ☑ `followed-checkins-layer` (pink): following public check-ins, always last 24h
- ☑ Updated legend: 4 layers — My stamps / My check-ins / Following stamps / Stories (24h)
- ☑ Top card: "Mine: N today · Following: M stamps, K stories"
- ☑ Stamp bottom sheet shows `@username` for followed stamps

---

## Phase 12 — Page Unification + Photos RLS Fix ✅ (2026-06-06)

### Photos RLS (migration 028)
- ☑ Replaced two fragmented SELECT policies ("Users can view own photos" + "Public stamp photos viewable by everyone") with one unified policy using `can_view_user()`
- ☑ Covers: own photos, photos on permitted public stamps, photos on own/public check-ins
- ☑ Previously: check-in photos completely invisible to any other user; private-account stamps leaked

### CheckInDetailScreen
- ☑ New full-screen detail page at `/check-in/:id`
- ☑ Hero photo, place name, date/time, visibility + source badges, note, additional photo row
- ☑ Owner: "Make a stamp" (→ pre-filled stamp editor) or "View stamp" if promoted
- ☑ `checkInDetailProvider` (autoDispose FutureProvider.family)

### CheckInListScreen rebuild
- ☑ Batch photo load via `photoUrlsByCheckIn` — one query, no N+1
- ☑ Card format: 72×72 thumbnail (or colored placeholder), place + visibility icon, date/time, note, photo count, chip buttons
- ☑ Navigates to `/check-in/:id` on tap; pull-to-refresh
- ☑ "Make stamp" / "View stamp" chip buttons per card

### Map check-in sheet
- ☑ "View details" button → `/check-in/:id`; "Make a stamp" remains secondary for own

---

## Phase 13 — Optimization + Doc Refresh ✅ (2026-06-06)

- ☑ Dead code removed: `getSharedCheckInsForDay()` (superseded by `getFollowingPublicCheckIns`)
- ☑ `flutter analyze` = 0 issues
- ☑ `CLAUDE.md` fully rewritten (v3.0) to reflect three-layer model, social graph, all routes, current data models, migration log
- ☑ `docs/advanced-features-plan.md` updated (Phases 8–13)
- ☑ `docs/dependencies.md` filled out

---

## 5. Conventions

- Migrations: versioned files in `supabase/migrations/`, applied via Supabase MCP; keep the
  local file in sync with what was applied.
- Functions: `set search_path = ''` + schema-qualified identifiers (matches the existing
  `function_search_path_fix` migration + advisor guidance).
- RLS performance: wrap `auth.uid()` as `(select auth.uid())` (matches `rls_auth_uid_performance_fix`).
- After DDL: run `get_advisors` (security + performance) and address new findings.

---

## 6. Post-feature polish pass (2026-06-04)

Autonomous quality/UX pass on top of the feature work (branch `feature/advanced-mvp-features`):
- **Shared widgets** `lib/shared/widgets/app_states.dart` (`LoadingView`/`EmptyView`/`ErrorView`
  + `errorMessage`) — refactored ~10 screens, removed duplicated state scaffolding.
- **Theme** `lib/shared/theme/app_theme.dart` — unified cards/inputs/app bar/buttons/snackbars.
- **Bugs fixed:** async errors rendered "Instance of NetworkError" → now `AppException.message`
  (screens, check-in flow, snackbars); stamp-detail like/save state never loaded
  (`getStamp` now resolves it) so the bookmark/like icons stayed empty; feed `loadMore`
  re-entrancy guard.
- **UX:** save/bookmark on feed cards (optimistic) + colored when saved; unread activity
  badge on the bell; map color legend; profile display-name + @handle; tagged users shown
  on stamp detail (tap → profile); empty-state CTAs; compact counts (1.2k);
  post-create feed/timeline refresh; profile grid pagination; tooltips on icon buttons.
- **Tests:** real unit tests for `compactCount` + `errorMessage` (`test/unit/`).
- `flutter analyze` = 0 issues; `flutter test` green throughout.
- **Still device-only:** visual/interaction QA needs `flutter run --release`.
