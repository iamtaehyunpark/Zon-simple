# ZON — Claude Code Project Context (v3.0)

> **Read this file before every session. Do not deviate from the rules below.**
> Updated 2026-06-06 to reflect the current shipped state of the app.

---

## 1. What is ZON

ZON is a **place-based diary SNS**. It passively collects location data while the app is open (foreground GPS) and from photo EXIF, then lets users turn meaningful moments into **Stamps** — rich cards with photos, vibe tags, and captions that can be kept private or shared to a social feed.

**Three-layer trace model (source of truth):**

| Layer | Table | User-facing? | Visibility |
|---|---|---|---|
| **Breadcrumbs** | `raw_location_events` | No — powers route line on map/timeline | Always system-private |
| **Check-in** | `check_ins` | Yes — discrete visit pins on map/timeline | Private by default; owner can set `public` to share as a 24h story in followers' feed |
| **Stamp** | `stamps` | Yes — promoted post (caption, vibe tags, likes/comments/saves) | Private by default; owner sets `public` to appear in feed |

**Invariants:**
- `stamp ⊂ check-in`: every stamp has exactly one parent `check_in_id` (1:1)
- You **check in first**, then optionally **promote** one check-in into a stamp
- Photos attach to `check_ins`; on promotion they carry over to the stamp (re-pointed, not re-uploaded)
- Promoting a check-in opens the stamp editor pre-filled — no instant promote

**Core loop:**
```
GPS/EXIF location collected → check-in suggested/created
  → Photos attached
  → Check-in can be shared as a 24h public "story"
  → Optionally promoted to Stamp (add caption, vibe tags, make public)
  → Stamp appears in followers' feed
```

---

## 2. What Is NOT in This MVP

**REMOVED from MVP — do not implement:**
- TensorFlow Lite / ONNX Runtime / any AI vision models
- Liveness detection, verification tier system (Tier 1/2/3), badges
- On-device signing / proof certificates
- Consensus place registration
- Automatic companion detection (BLE-based)
- Real-time location sharing (Snapchat-map style) — schema groundwork exists (friendships table), feature not yet built
- Route navigation (Mapbox Navigation)
- Premium subscription / B2B campaign tools

When asked to implement these, say:
> "This is a future version feature. Adding a TODO and skipping for now."

---

## 3. Tech Stack (Non-Negotiable)

| Layer | Choice | Notes |
|---|---|---|
| App | Flutter (Dart) | iOS first |
| State | Riverpod | `@riverpod` codegen — run `dart run build_runner build` after model/provider changes |
| Navigation | go_router | All routes in `lib/app.dart`. Declarative only. |
| Backend | Supabase | PostgreSQL + Auth + Storage + Edge Functions |
| Auth | Supabase Auth + `flutter_web_auth_2` | OAuth (Apple/Google) via native ASWebAuthenticationSession; `detectSessionInUri: false` in `Supabase.initialize`; manual `getOAuthSignInUrl` → `getSessionFromUrl` |
| Maps | Mapbox (`mapbox_maps_flutter`) | `GeoJsonSource`, `CircleLayer`, `LineLayer`. `upsertLine` for smooth live path. |
| Location | geolocator | Foreground "while in use" only. `distanceBetween` for dedup. |
| Photo | photo_manager | EXIF parsing. `PhotoService.uploadFile` for storage. |
| Place search | Kakao Local API (Korea) + Google Places (worldwide) | Routed by `placeServiceFor(lat,lng)` in `lib/core/places/`. |
| Local storage | Hive | GPS event batch queue. |
| Notifications | `firebase_messaging` + `flutter_local_notifications` | FCM for remote; local for photo suggestions. Remote push blocked on Apple paid enrollment. |
| Image | `flutter_image_compress` + `cached_network_image` | |
| HTTP | Dio | Auth interceptors. |

**Never add dependencies without updating `pubspec.yaml` and `docs/dependencies.md`.**

---

## 4. Current Route Map

All routes defined in `lib/app.dart`:

| Path | Screen | Notes |
|---|---|---|
| `/login` | `LoginScreen` | OAuth entry |
| `/feed` | `FeedScreen` | Stamp feed + stories rail (shell) |
| `/map` | `MapScreen` | Live map (shell) |
| `/timeline` | `TimelineScreen` | Single-day trace (shell) |
| `/profile` | `ProfileScreen` (own) | (shell) |
| `/checkin` | `CheckinEntry` | Creation flow; query params: `mode=stamp\|checkin`, `lat`, `lng`, `fromCheckIn=<id>` |
| `/check-in/:id` | `CheckInDetailScreen` | View a check-in (photos, note, promote CTA) |
| `/stamp/:id` | `StampDetailScreen` | Full stamp detail + comments |
| `/stamp/:id/edit` | `EditStampScreen` | |
| `/profile/:id` | `ProfileScreen` (other) | |
| `/profile/:id/friends` | `UserListScreen(friends:true)` | |
| `/profile/:id/followers` | `UserListScreen(followers:true)` | |
| `/profile/:id/following` | `UserListScreen(followers:false)` | |
| `/settings` | `SettingsScreen` | Edit profile, privacy account toggle, delete account |
| `/check-ins` | `CheckInListScreen` | Own check-in list with photo thumbnails |
| `/saved` | `SavedStampsScreen` | Bookmarked stamps |
| `/search` | `UserSearchScreen` | Find people |
| `/activity` | `ActivityScreen` | Notifications + friend/follow request rows |
| `/follow-requests` | `FollowRequestsScreen` | Approve/deny pending follows |
| `/friend-requests` | `FriendRequestsScreen` | Approve/deny pending friend requests |
| `/photo-suggestions` | `PhotoSuggestionScreen` | Today's geotagged photos → check-ins |

---

## 5. Folder Structure (Current)

```
lib/
├── app.dart                     ← MaterialApp + GoRouter (ALL routes here)
├── main.dart
├── core/
│   ├── auth/                    ← auth_provider.dart (currentUserProvider)
│   ├── errors/                  ← app_exception.dart (AppException, NetworkError, AuthError)
│   ├── location/
│   │   └── providers/
│   │       └── gps_provider.dart  ← GpsNotifier (session path, auto-anchor)
│   ├── notifications/           ← notification_service.dart
│   ├── photos/                  ← photo_service.dart (upload, EXIF)
│   ├── places/                  ← place_service_provider.dart (Kakao/Google router)
│   └── supabase/                ← supabase_provider.dart
├── data/
│   ├── models/
│   │   ├── check_in.dart        ← CheckIn, CheckInDraft, CheckInSource enum
│   │   ├── enums.dart           ← StampVisibility {private, public}
│   │   ├── raw_location_event.dart
│   │   ├── stamp.dart           ← Stamp, StampDraft
│   │   └── user_profile.dart    ← UserProfile (friendCount, followerCount, isPrivate)
│   └── repositories/
│       ├── base_repository.dart
│       ├── check_in_repository.dart   ← CheckInRepository + CheckInStory class
│       ├── comment_repository.dart
│       ├── notification_repository.dart
│       ├── profile_repository.dart    ← FollowState, FriendState enums here
│       └── stamp_repository.dart
├── features/
│   ├── auth/presentation/       ← login_screen.dart
│   ├── checkin/presentation/
│   │   ├── check_in_detail_screen.dart  ← /check-in/:id
│   │   ├── check_in_editor.dart         ← CheckInEditorBody (place+note+photos+story toggle)
│   │   ├── checkin_entry.dart           ← Entry router (place search → editor → stamp)
│   │   ├── photo_strip.dart
│   │   ├── stamp_editor.dart
│   │   ├── user_tag_field.dart          ← showUserPicker
│   │   └── providers/
│   │       └── checkin_provider.dart    ← CheckinNotifier
│   ├── feed/presentation/
│   │   ├── feed_screen.dart             ← FeedScreen + StampCard + _StoriesRail + _StoryView
│   │   ├── stamp_detail_screen.dart     ← Full detail + comments
│   │   ├── edit_stamp_screen.dart
│   │   ├── saved_stamps_screen.dart
│   │   └── providers/
│   │       └── feed_provider.dart       ← FeedNotifier, feedStoriesProvider
│   ├── map/presentation/
│   │   ├── map_screen.dart             ← MapScreen + MapFilter enum + bottom sheets
│   │   └── map_drawing.dart            ← drawPins, upsertLine, removeLine
│   ├── photo_import/presentation/
│   │   ├── photo_suggestion_screen.dart
│   │   └── providers/
│   │       └── photo_suggestion_provider.dart
│   ├── profile/presentation/
│   │   ├── activity_screen.dart        ← Notifications + friend/follow request rows
│   │   ├── check_in_list_screen.dart   ← Card list with photo thumbnails
│   │   ├── follow_requests_screen.dart
│   │   ├── friend_requests_screen.dart
│   │   ├── profile_screen.dart         ← _SocialButtons (Add Friend + Follow)
│   │   ├── settings_screen.dart        ← Private account toggle
│   │   ├── user_list_screen.dart       ← friends/followers/following (friends:bool param)
│   │   ├── user_search_screen.dart
│   │   └── providers/
│   │       └── profile_provider.dart   ← ProfileNotifier, followStateProvider,
│   │                                      friendStateProvider, followRequestsProvider,
│   │                                      friendRequestsProvider
│   └── timeline/presentation/
│       └── timeline_screen.dart        ← _ListPanel (drag/swipe/inline edit), _TimelineMap
└── shared/
    ├── theme/app_theme.dart
    ├── utils/format.dart               ← compactCount, errorMessage
    └── widgets/
        ├── app_states.dart             ← LoadingView, EmptyView, ErrorView
        └── photo_thumb_row.dart
```

---

## 6. Architecture Rules

### 6.1 Feature Structure
Flat-ish in practice. Shared code in `lib/shared/`; feature code in `lib/features/<feature>/presentation/`. Repositories in `lib/data/repositories/`. No separate domain/usecase layer (YAGNI at this scale).

### 6.2 State Management
- All persistent state through Riverpod (`@riverpod` codegen).
- `setState()` only for local ephemeral widget state (animation, form controllers).
- After adding/changing `@riverpod` providers or `@freezed` models: **run `dart run build_runner build --delete-conflicting-outputs`**.

### 6.3 Navigation
- Named routes in `lib/app.dart` only. Pass IDs (never full objects) between routes.
- `context.push()` for drill-down; `context.go()` for tab-level navigation.

### 6.4 Error Handling
- Repositories return `Either<AppException, T>` via `fpdart`.
- UI: `.fold((e) => ..., (data) => ...)` or `.getOrElse`.
- Never swallow exceptions silently.

---

## 7. Location & Photo Rules

### GPS (Foreground Only)
- Collect while app is foregrounded; stop on `AppLifecycleState.paused`.
- `GpsNotifier` keeps `sessionPath` (cleared on each new session start).
- Auto-anchor: when session ends, if no check-in within 80m exists for today → create auto check-in. DB-backed dedup (queries today's check-ins), resets naturally at midnight.

### Significant-Change (Background)
- iOS only: `CLLocationManager.startMonitoringSignificantLocationChanges()`.
- Purpose: trigger nudge notification only. NOT continuous tracking.
- Remote push blocked on Apple paid enrollment (no APNs key). Local notifications work.

### Photo EXIF
- `PhotoService.getNewPhotosToday()` scans for today's geotagged photos.
- Parse EXIF on device — never send image bytes to server for parsing.
- Detected photos → dismissible banner on Feed → `PhotoSuggestionScreen` → creates **check-ins** (source=photo).

### Privacy
- `raw_location_events`: always system-private, never exposed to other users.
- `check_ins`: private by default. Owner can set `visibility='public'` → surfaces as a 24h story in followers' feed.
- `stamps`: private by default. Owner sets `public` for feed visibility.
- Private accounts: followers must be approved. `can_view_user(owner_uuid)` is the universal RLS gate.

---

## 8. Data Models

### CheckIn (check_ins table)
```dart
CheckIn {
  id, userId, placeName, normalizedPlaceName,
  lat, lng, externalPlaceId, externalSource,
  note,                          // short text
  source,                        // CheckInSource {manual, photo, auto}
  visibility,                    // StampVisibility {private, public}
  taggedUserIds,                 // List<String>
  photoUrls,                     // populated on fetch, not stored on row
  photoCount,
  stampId,                       // set if promoted
  visitedAt, createdAt, updatedAt
}
```

### Stamp (stamps table)
```dart
Stamp {
  id, userId, placeName, normalizedPlaceName,
  lat, lng, externalPlaceId, externalSource,
  checkInId,                     // parent check-in (1:1)
  visibility,                    // StampVisibility
  coverPhotoUrl, caption,
  sensoryTags, taggedUserIds,
  photoUrls, photoCount,
  likeCount, commentCount,
  isLiked, isSaved,
  username, avatarUrl,           // populated from v_feed_stamps view join
  visitedAt, createdAt, updatedAt
}
```

### UserProfile (profiles table)
```dart
UserProfile {
  id, username, displayName, avatarUrl, bio,
  stampCount,
  friendCount,                   // accepted friendships
  followerCount, followingCount,
  isPrivate,                     // private account flag
  createdAt
}
```

### Social enums (profile_repository.dart)
```dart
enum FollowState { none, requested, following }
enum FriendState { none, requestedByMe, requestedByThem, friends }
```

### CheckInStory (check_in_repository.dart)
```dart
// One author's recent public check-ins, grouped for feed stories rail.
CheckInStory { userId, username, avatarUrl, checkIns: List<CheckIn> }
```

---

## 9. Social Graph

Two overlapping relationship types:

### Follows (asymmetric)
- Table: `follows (follower_id, following_id, status {pending|accepted})`
- Private accounts: follow triggers `status='pending'` (server-enforced by `enforce_follow_status` trigger). Target approves/denies.
- Gates: feed stamps, stories, map following layer, profile visibility for private accounts.
- `can_view_user(owner uuid)` SECURITY DEFINER function: true when owner=self, OR owner not private, OR accepted follow exists.

### Friendships (symmetric)
- Table: `friendships (user_a, user_b, status {pending|accepted}, requested_by)` — canonical ordering `user_a < user_b`.
- On acceptance: `auto_follow_on_friendship` trigger inserts both `follows` rows.
- Gates: future real-time location sharing, companying/tagging features.
- Profile UI: "Add Friend" (primary) + "Follow" (secondary), Facebook-style.
- Friend requests surface in Activity tab above follow requests.

### Privacy gate
```sql
-- can_view_user(p_owner uuid) returns boolean
-- used in stamps RLS, check_ins RLS, photos RLS
-- true when: owner=self OR owner not private OR accepted follow from viewer to owner
```

---

## 10. Map Layers

**Timeline map** — historical; shows the full day's route + check-in pins + stamp pins for the selected day.

**Live map (MapScreen)** — session-focused + social:

| Layer | Source ID | Color | Content |
|---|---|---|---|
| Live route | `live-route-*` | Green | Current session GPS path (`upsertLine` — no flicker) |
| My stamps | `my-stamps-source` | Green | Own stamps — today |
| My check-ins | `my-checkins-source` | Blue | Own manual check-ins — today |
| Auto anchors | `my-auto-source` | Grey (tiny r=2.5) | Auto check-ins — today |
| Following stamps | `followed-stamps-source` | Orange | Following users' public stamps — **filter window** |
| Following stories | `followed-checkins-source` | Pink | Following users' public check-ins — always last 24h |

**Filter** (`MapFilter` enum): `today | week | month | year | all | custom` — applies to following stamps only. "Custom" opens Flutter's `showDateRangePicker`.

Tap on any pin → bottom sheet with place preview + navigation action.

---

## 11. Database Migrations Applied

Migrations live in `supabase/migrations/`. All have been applied to the remote project.

| Migration | Key content |
|---|---|
| 001–009 | Initial schema: profiles, stamps, photos, follows, stamp_likes/saves, comments, notifications, raw_location_events |
| 010 | check_ins table, geo trigger, RLS, indexes; stamps.check_in_id; photos.check_in_id; check_ins_for_day RPC |
| 011 | shared_check_ins_for_day RPC (social map); map_sharing |
| 012 | Activity notifications triggers (like/comment/follow/tag/mention) |
| 013 | Security hardening (search_path, EXECUTE revokes) |
| 014–022 | Timeline refinements, GPS auto-anchor, promote-to-stamp flow, feed ordering |
| 023 | Private accounts: profiles.is_private, follows.status, enforce_follow_status trigger, can_view_user(), stamps RLS privacy gate |
| 024 | Lock down trigger functions from REST |
| 025 | check_ins.visibility + partial index + public check-ins RLS |
| 026 | friendships table + friend_count + auto_follow_on_friendship + notify_on_friend_request triggers |
| 027 (unused) | *(skipped in numbering)* |
| 028 | photos RLS unified: own + can_view_user-gated stamp + check-in photos |

---

## 12. Coding Conventions

### Dart / Flutter
```dart
// ✅ Freezed for all data models
// ✅ Either<AppException, T> for all repo methods
// ✅ @riverpod codegen for providers
// ✅ Named routes via go_router (lib/app.dart)
// ✅ build_runner after model/provider changes

// ❌ No business logic in widgets
// ❌ No direct Supabase calls in widgets
// ❌ No setState() for persistent state
// ❌ No "Always Allow" location permission
// ❌ No continuous background GPS
// ❌ No dev-mock / kDevMockUserId — real Supabase session only
// ❌ Never expose .env secrets
```

### DB conventions
- All DB functions: `set search_path = ''` + fully schema-qualified identifiers
- RLS `auth.uid()` calls: always wrapped as `(select auth.uid())` for performance
- After DDL: run `get_advisors` and address findings

### File Naming
- Files: `snake_case.dart` · Classes: `PascalCase` · Variables: `camelCase` · Providers: `camelCaseProvider`

---

## 13. iOS Permissions

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>ZON uses your location while you're using the app to track your route and suggest check-ins.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>ZON uses significant location changes in the background to notify you when you arrive somewhere new.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>ZON reads your photo locations to automatically add them to your personal map and timeline.</string>
```

Request `whileInUse` first; escalate to `always` only if user enables background nudges.

---

## 14. Notification Types

Stored in `notifications` table. Triggers fire on DB events (SECURITY DEFINER).

| type | Trigger | Text shown |
|---|---|---|
| `like` | stamp_likes INSERT | "@X liked your stamp" |
| `comment` | comments INSERT | "@X commented on your stamp" |
| `follow` | follows INSERT (accepted) | "@X started following you" |
| `follow_accepted` | follows UPDATE pending→accepted | "@X accepted your follow request" |
| `tag` | check_ins/stamps taggedUserIds | "@X tagged you in a stamp" |
| `mention` | manual RPC call | "@X mentioned you" |
| `friend_request` | friendships INSERT pending | "@X sent you a friend request" |
| `friend_accepted` | friendships UPDATE pending→accepted | "@X accepted your friend request" |

Bell badge in Feed counts unread notifications + pending follow requests + pending friend requests.

---

## 15. Quick Reference

| Question | Answer |
|---|---|
| Three layers? | raw_location_events (route line) / check_ins (pins) / stamps (posts) |
| stamp ⊂ check-in? | Yes. Every stamp has a parent check_in_id. |
| Default visibility? | Both check-ins and stamps are private by default |
| Public check-in → ? | Appears as a 24h story in followers' feed rail |
| Promote check-in → stamp | Navigate to `/checkin?fromCheckIn=<id>` — opens stamp editor pre-filled |
| Feed unit? | Stamp (public, ordered by `created_at` when posted) |
| Stories unit? | Public check-in (last 24h, ordered by visitedAt) |
| Map: own content? | Today's stamps + check-ins + live session path |
| Map: following content? | Stamps in filter window (orange) + public check-ins last 24h (pink) |
| Follow vs Friend? | Follow = asymmetric content graph. Friend = symmetric, auto-follows both ways, gated for future location sharing |
| Private account gate? | `can_view_user(owner)` — reused in stamps/check_ins/photos RLS |
| Photos RLS? | Own photos OR photos on can_view_user-permitted stamp OR check-in |
| Where are all routes? | `lib/app.dart` |
| Where are social enums? | `FollowState`/`FriendState` in `lib/data/repositories/profile_repository.dart` |
| Run after model changes? | `dart run build_runner build --delete-conflicting-outputs` |
| Analyze clean? | `flutter analyze` → 0 issues (only SPM warnings from plugins, expected) |
| Push notifications status? | Remote push BLOCKED on Apple paid enrollment. Local notifications work. |
| Should I add the vision model? | NO — post-MVP only |
