# ZON — Feature & Logic Reference

> Complete map of every screen, feature, data pipeline, and provider relationship in the codebase.  
> Last updated: 2026-06-10 (branch: feature/flutter-ui-redesign)

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [Core GPS Tracking](#2-core-gps-tracking)
3. [Live Location Sharing](#3-live-location-sharing-snap-map)
4. [Photo Import](#4-photo-import)
5. [Check-in / Stamp Creation](#5-check-in--stamp-creation)
6. [Feed](#6-feed)
7. [Stamp Detail & Comments](#7-stamp-detail--comments)
8. [Map](#8-map)
9. [Timeline](#9-timeline)
10. [Profile & Social Graph](#10-profile--social-graph)
11. [Activity & Notifications](#11-activity--notifications)
12. [Settings & Privacy](#12-settings--privacy)
13. [Social Graph Management](#13-social-graph-management)
14. [Place Discovery](#14-place-discovery)
15. [Provider Graph](#15-key-provider-graph)
16. [Database Tables](#16-database-tables)
17. [Route Map](#17-route-map)
18. [Data Models](#18-data-models)
19. [Error Handling](#19-error-handling)

---

## 1. Authentication

**Route:** `/login`  
**File:** `lib/features/auth/presentation/login_screen.dart`

### Flow

```
LoginScreen
  → Supabase.auth.getOAuthSignInUrl(provider: apple | google)
  → flutter_web_auth_2 opens native ASWebAuthenticationSession
  → callback URL (app.getzon://login-callback) intercepted
  → getSessionFromUrl(callbackUrl)
  → authStateStreamProvider emits SIGNED_IN
  → currentUserProvider updates to User
  → GoRouter redirect fires → /map
```

### Key Details

- `detectSessionInUri: false` in `Supabase.initialize` — session is exchanged manually, not from URI
- Error differentiation: `PlatformException` with `CANCELED` code vs actual auth error
- Both Apple and Google share the same flow; provider is passed as enum

---

## 2. Core GPS Tracking

**Entry:** `_ZonAppState` (app lifecycle observer in `lib/app.dart`)  
**Files:** `lib/core/location/gps_service.dart`, `location_batcher.dart`, `providers/gps_provider.dart`

### Pipeline

```
AppLifecycleState.resumed
  → GpsNotifier.startTracking()
    → GpsService.requestPermission()
    → sessionPath.clear(); sessionStartedAt = DateTime.now()
    → batchUserId = Supabase.auth.currentUser?.id  — read once to avoid provider churn
    → GpsService.startTracking() — stream, distanceFilter: 50m, accuracy: high
      ↓ each position (batchUserId != null guard)
      → sessionPath.add([lng, lat])                 — in-memory path for live map line
      → LocationBatcher.add(RawLocationEvent(userId: batchUserId, ...))
    → GpsService.currentPosition()                  — fast initial fix on session start

LocationBatcher (keepAlive, Timer every 5 min)
  → flush() → up to 100 events → LocationRepository.batchIngest()
  → Edge Function ingest-location → raw_location_events table

AppLifecycleState.paused / detached
  → GpsNotifier.stopTracking()
    → LocationBatcher.flush()   — immediate flush so trace is visible right away
    → _anchorPath()
      → query today's check_ins + stamps within 80m of last position
      → if none found → placeServiceFor(lat,lng).nearby() → resolve place name
      → CheckInRepository.createCheckIn(source: auto)
```

### Session ID Guard

`_sessionId` is incremented on each `startTracking()`. `_anchorPath()` captures the ID at stop-time and aborts if the session has since restarted — prevents phantom anchors when the app quickly backgrounds then resumes.

### `sessionStartedAt`

`GpsNotifier.sessionStartedAt` is set to `DateTime.now()` at the start of each session. The map uses this to split today's total distance into (pre-session recorded breadcrumbs) + (live session path), avoiding double-counting breadcrumbs the batcher already flushed during the current session.

### Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `distanceFilter` | 50 m | Minimum movement before stream fires |
| `_kMinAnchorGapM` | 80 m | Proximity threshold for auto-anchor dedup |
| `_batchInterval` | 5 min | Hive flush cadence |
| `_maxBatchSize` | 100 events | Max events per flush |

---

## 3. Live Location Sharing (Snap Map)

**Entry:** `MapScreen` mount  
**File:** `lib/data/repositories/location_sharing_repository.dart`

### Pipeline

```
MapScreen.initState
  → friendLocationsProvider (stream)
      → LocationSharingRepository.streamFriendLocations()
      → Supabase Realtime channel on user_locations
      → emits List<FriendLocation> on each change

Each GPS position (from gpsNotifierProvider)
  → _maybeBroadcast(pos)
      → throttled: 30s elapsed OR 50m moved
      → LocationSharingRepository.upsertMyLocation(lat, lng, accuracy, heading)
      → UPSERT into user_locations (PK = user_id)

Friend bubble rendering (Stack overlay, NOT map layer)
  → _onFriendLocationsChanged() → filter stale (≥8h) → setState
  → _updateFriendScreenPositions()
      → map.pixelForCoordinate(Point) per friend
      → _friendScreenPosNotifier.value = Map<userId, Offset>
  → ValueListenableBuilder rebuilds bubbles on position change
  → Triggered on: friend location update, camera change (onCameraChangeListener)
```

### Visibility Gates (RLS)

- Own position: full CRUD
- Others' positions: SELECT gated by accepted friendship + `is_ghost_mode = false` + not in `location_hidden_from`
- `FriendLocation.isStale` = true when `updatedAt` is ≥8h ago (hidden from map)

---

## 4. Photo Import

**Route:** `/photo-suggestions`  
**Files:** `lib/features/photo_import/presentation/photo_suggestion_screen.dart`, `photo_checkin_inspection_screen.dart`

### Pipeline

```
PhotoSuggestionScreen
  → PhotoService.getPhotosWithLocation() — scan device, last 30 days, EXIF GPS only
  → Group into clusters: < 150m proximity + time gap detection
  → Filter: no existing manual check-in already exists between photos
  → Resolve place name per cluster: placeServiceFor(lat, lng).nearby()

PhotoCheckinInspectionScreen (per cluster, swipeable)
  → User can: keep, skip, merge adjacent clusters
  → On confirm:
      → PhotoService.uploadFile(asset) → Supabase Storage /photos/userId/*.jpg
      → CheckInRepository.createCheckIn(
           placeName, lat, lng, source: photo,
           photoUrls: [uploaded URLs]
         )
  → On complete: ref.invalidate(timelineNotifierProvider)
```

### Key Details

- EXIF is parsed on-device — photo bytes are never sent to server for analysis
- Upload uses `flutter_image_compress` to resize before upload
- `PhotoService.uploadFile()` returns public CDN URL
- Local notification (`flutter_local_notifications`) can trigger the screen daily

---

## 5. Check-in / Stamp Creation

**Route:** `/checkin?mode=stamp|checkin&lat=&lng=&fromCheckIn=&time=`  
**Files:** `lib/features/checkin/presentation/checkin_entry.dart`, `check_in_editor.dart`, `stamp_editor.dart`, `providers/checkin_provider.dart`

### State Machine (`CheckinNotifier`)

```
idle
  → startCheckin(lat, lng, mode, visitedAt)
locating
  → GpsNotifier resolves position
  → placeServiceFor(lat, lng).nearby() → top suggestions
placeSelected(lat, lng, nearbyStamps, suggestedPlace, placeSuggestions)
  → user picks or searches a place
  → beginEditing(ExternalPlace?)
editingCheckIn(CheckInDraft)
  → user fills: place, note, photos, tagged users, visibility
  → save()
editingStamp(StampDraft)
  → user fills: all check-in fields + caption, sensory tags, cover photo
  → save()
saving
  → upload photos → PhotoService.uploadFile() × n
  → CheckInRepository.createCheckIn()
  → if stamp: StampRepository.createStamp(checkInId=)
  → invalidate: timelineNotifierProvider, feedNotifierProvider
completeCheckIn(CheckIn) | completeStamp(stampId)
error(message)
```

### Promote-from-existing Flow

When `fromCheckInId` is set:
1. `CheckInRepository.getCheckIn(id)` + `getCheckInPhotos(id)` 
2. Pre-fill `StampDraft` (note → caption, photos carry over, place/coords copied)
3. Open directly into `editingStamp` state

### Editors

**CheckInEditorBody**
- Place (via `PlaceSearchField` — coordinate-anchored, Overlay dropdown)
- Note (multiline, optional)
- Photo strip (up to 5, `PhotoStrip` widget)
- Tagged users (`UserTagField.showUserPicker()` → search + multi-select)
- Visibility toggle (private default)

**StampEditorBody**
- All of the above, plus:
- Caption (richer text intent)
- Sensory tags (preset list: vibes, moods, season)
- Cover photo selection from attached photos

---

## 6. Feed

**Route:** `/feed` (shell tab)  
**File:** `lib/features/feed/presentation/feed_screen.dart`

### Three Tabs

#### Following Tab

```
feedStoriesProvider
  → CheckInRepository.getStories()
  → public check-ins, last 24h, grouped by author → List<CheckInStory>
  → renders horizontal Stories Rail (tap → StoryView modal)

feedNotifierProvider (paginated)
  → StampRepository.getFeedStamps(limit=30, offset)
  → v_feed_stamps view (stamps + profiles join + engagement counts)
  → renders StampCard list
  → loadMore() triggered at 3 items from end

Photo suggestion banner
  → todayPhotoSuggestionsProvider → PhotoService.getNewPhotosToday()
  → shows if count > 0, dismissible, tap → /photo-suggestions
```

**StampCard actions:** like toggle, save toggle, tap → `/stamp/:id`, author tap → `/profile/:id`

#### Nearby Tab

```
→ GpsNotifier.current position
→ StampRepository.nearbyStamps(lat, lng, radiusM: 5000)
→ card list with distance label
→ manual refresh button
```

#### Trending Tab

```
→ StampRepository.getTrendingPlaces()
→ ORDER BY hot_score DESC on place_stats view
→ place cards with stamp/visitor counts
→ tap → /place/:id
```

### Stories Rail

```
Tap story avatar
→ StoryView modal (full-screen)
→ swipe left/right: next/previous author's stories
→ within author: PageView of their public check-ins (last 24h)
→ tap → /profile/:id
```

---

## 7. Stamp Detail & Comments

**Route:** `/stamp/:id`  
**File:** `lib/features/feed/presentation/stamp_detail_screen.dart`

### Data

```
stampDetailProvider(stampId)
  → StampRepository.getStamp(id)    — from v_feed_stamps view
  → resolved: isLiked, isSaved for current user

stampCommentsProvider(stampId)
  → CommentRepository.getComments(stampId)
  → threaded: parent comments + replies (parent_id FK)

stampPhotosProvider(stampId)
  → StampRepository.getStampPhotos(stampId)

stampTaggedUsersProvider
  → ProfileRepository.getProfiles(stamp.taggedUserIds)
```

### Layout

- Header: author avatar, username, follow button, place name + date
- Photo carousel (swipeable `PageView`), tap → `FullScreenImageViewer.show()`
- Caption with `@mention` spans highlighted
- Sensory tags row
- Like / save / comment count buttons
- Comment thread (chronological, replies indented)
- Sticky comment input at bottom (shows avatar, keyboard-aware)

### Actions

| Action | Logic |
|---|---|
| Like | `StampRepository.toggleLike()` — optimistic UI update |
| Save | `StampRepository.toggleSave()` — invalidate `savedStampsProvider` |
| Post comment | `CommentRepository.addComment()` — scans body for `@username` → `create_mention_notification` RPC |
| Reply | Sets `replyTargetProvider` — prefixes `@username` in input, sets `parent_id` |
| Delete comment | `CommentRepository.deleteComment()` — own comments only |
| Edit stamp | Own stamp only → `/stamp/:id/edit` |

---

## 8. Map

**Route:** `/map` (shell tab)  
**File:** `lib/features/map/presentation/map_screen.dart`, `map_drawing.dart`

### Data Loading (parallel on mount)

```
_load()
  → StampRepository.getMyStampsForRange(from, to)
  → CheckInRepository.getMyCheckInsForRange(from, to)
  → StampRepository.getFollowingStamps(from, to)
  → CheckInRepository.getFollowingPublicCheckIns()   — always last 24h
  → StampRepository.getSavedStamps()
  → → setState → _updateLayers()
  → _refreshTodayRoute()

_loadNearbyPlaces()
  → StampRepository.getNearbyHotPlaces(lat, lng, 5km)
  → rendered in bottom sheet carousel

_refreshTodayRoute()
  → LocationRepository.getRouteForDay(DateTime.now())
  → stores into _todayRoute (List<RawLocationEvent>)
  → re-triggered when a new GPS session starts (sessionStartedAt changes)
```

### Today's Distance Stat

The map header shows `X.X km today`. This is computed by `_todayDistanceKm`:

```
_todayDistanceKm = pre-session-distance(_todayRoute) + _sessionDistanceKm
  where pre-session-distance sums consecutive breadcrumbs in _todayRoute
        with capturedAt < sessionStartedAt  (stops before current session to
        avoid double-counting events that the batcher already flushed)
```

This replaces the previous `_sessionDistanceKm`-only stat, which reset to 0 on every app open.

### Map Layers

| Layer | Source ID | Color | Content |
|---|---|---|---|
| Live route | `live-route-*` | Green | Session GPS path (`upsertLine`) |
| My stamps | `my-stamps-source` | Brand purple | Own stamps (today range) |
| My check-ins | `my-checkins-source` | Blue | Own manual check-ins (today) |
| Auto anchors | `my-auto-source` | Grey r=2.5 | Auto check-ins (today) |
| Following stamps | `followed-stamps-source` | Orange | Filter window only |
| Following stories | `followed-checkins-source` | Pink | Last 24h |
| Friend bubbles | Stack overlay | Avatars | Realtime (pixelForCoordinate) |

### Filter Logic

`MapFilter` enum: `today | week | month | year | all | custom`

```
_onFilterTap(filter)
  → _filter = filter
  → if custom → showDateRangePicker()
  → _load()          — re-fetches stamps/check-ins for new range
  → _updateLayers()  — redraws all pins
```

### Map Drawing (`map_drawing.dart`)

- `drawPins(map, sourceId, layerId, pins, color)` — upserts GeoJSON `FeatureCollection`
- `removePins(map, sourceId, layerId)` — clears source
- `upsertLine(map, coords, color, idPrefix)` — updates or inserts `LineString` (no flicker)
- `removeLine(map, idPrefix)` — removes line source+layer
- `drawHotPlaces(map, places)` — renders nearby hot place pins

### Tap Handling (`_onMapTap`)

```
queryRenderedFeatures(point, layerIds: [...all layers])
  → extract feature kind + id from properties
  → _showSheet(kind, id)
    → kind=stamp  → bottom sheet with StampSheet
    → kind=checkin → bottom sheet with CheckInSheet
    → kind=hot     → context.push('/place/:id')
  → if no feature hit → no-op
```

### Additional UI Controls

- **Search bar:** `_onSearchChanged(q)` → `placeServiceFor.search(q)` → results dropdown → tap → `flyTo()` + draw search pin
- **Category filter chips:** `PlaceCategory` enum → filter `_followedStamps` client-side by category
- **Saved-only toggle:** switches between `_myStamps` and `_savedStamps` for own layer
- **Legend:** auto-shows on map touch, hides after 3s (`Timer`)
- **Locate Me FAB:** `map.flyTo()` to current GPS position

---

## 9. Timeline

**Route:** `/timeline` (shell tab)  
**Files:** `lib/features/timeline/presentation/timeline_screen.dart`, `providers/timeline_provider.dart`

### Data Loading

```
TimelineNotifier.loadDay(date)  [keepAlive: true]
  → StampRepository.getMyStampsForDay(date)
  → CheckInRepository.getForDay(date)           — check_ins_for_local_day RPC
  → LocationRepository.getRouteForDay(date)     — route_events_for_day RPC
  → DiaryRepository.getDiary(date)              — day_diaries table
  → TimelineNoteRepository.getForDay(date)      — timeline_notes table
  → → state = DayBundle(date, route, checkIns, stamps, notes, diary)
```

### Date Strip

```
_slidableDays: last 180 days + any earlier selected day
_monthlyActivity: monthly_visit_counts RPC → badge dots
_diaryDays: getDiaries() → which days have written entries (dots)

Date tap
  → _load(selectedDay)
  → _scrollToSelectedDate()   — animates strip to center selected date
```

### List Panel (`_ListPanel`)

Items built from `DayBundle` via `_buildItems()`:
- merge check-ins + stamps + notes, sort by `visitedAt`
- filter out auto anchors within 80m of adjacent manual pins

**Interactions:**
- Drag to reorder (notes only) → `onReorderItem` → `_persistNoteTime()` → `TimelineNoteRepository.setTime()`
- Swipe to delete → `_deleteItem()` → repo delete + `_reload()`
- Tap check-in → expand inline editor (note, visibility, photos)
- Tap stamp → expand inline editor (caption, tags, photos)
- Tap auto anchor → open `/checkin?lat=&lng=&time=` for promotion

**Note editor (`_TimelineNoteEditor`):**
- Text + time picker + public toggle
- Save → `TimelineNoteRepository.save()` / `update()`

### Map Panel

```
_maybeRedraw(bundle)
  → _buildItems(bundle) → located items → coords list
  → drawLine(map, coords, color, 'tl-path')
  → drawPins — check-ins (blue), stamps (purple), auto (grey)
  → tap pin → _showCheckInDetail() or context.push('/stamp/:id')
```

### AI Diary Generation

```
Generate button
  → _generateDiary()
  → collect stamps + photos for day
  → PhotoService.resizeForLlm(asset) → 512px JPEG → base64 string
  → DiaryRepository.generateDiary(date, stamps, photoBase64s)
    → Edge Function generate-diary (Gemini 3.1 flash lite, JWT-gated)
    → returns generated text
  → display + save to day_diaries
  → editable inline, saved via DiaryRepository.saveDiary()
```

---

## 10. Profile & Social Graph

**Routes:** `/profile` (own, shell), `/profile/:id` (other user)  
**File:** `lib/features/profile/presentation/profile_screen.dart`, `providers/profile_provider.dart`

### Data

```
ProfileNotifier(targetId)
  → ProfileRepository.getProfile(targetId)    — profiles table

followStateProvider(targetId)
  → ProfileRepository.getFollowState(targetId)
  → FollowState { none | requested | following }

friendStateProvider(targetId)
  → ProfileRepository.getFriendState(targetId)
  → FriendState { none | requestedByMe | requestedByThem | friends }

profileStampsNotifierProvider(targetId, publicOnly)
  → StampRepository.getMyStamps(userId, publicOnly, limit=30, offset)
  → paginated, loadMore() on scroll
```

### Header

| Own profile | Other profile |
|---|---|
| Avatar tap → ImagePicker → upload → `updateProfile()` | View-only avatar |
| Settings icon → `/settings` | "⋯" icon (no-op for now) |
| Notification bell → `/activity` | Follow button (state-driven) |
| Check-ins icon → `/check-ins` | Add Friend button |

### Social Buttons Logic

```
Follow button
  → none        → follow() → FollowState.requested (if private) or .following
  → requested   → label "Requested" (tap to cancel)
  → following   → label "Following" (tap to unfollow)

Add Friend button
  → none           → sendFriendRequest()
  → requestedByMe  → label "Requested"
  → requestedByThem → label "Accept" → acceptFriendRequest()
  → friends        → label "Friends" (tap to unfriend → confirm dialog)
```

### Tabs

| Tab | Own | Other |
|---|---|---|
| Stamps | All stamps (public + private badges) | Public only |
| Activity (own) / Followers (other) | Notification summary | Follower list |
| Friends / Following | Friend list | Following list |

### Visibility Gate

```sql
can_view_user(p_owner uuid) RETURNS boolean
  → TRUE if: owner = current user
           OR owner.is_private = false
           OR EXISTS accepted follow (viewer → owner)
```

Applied as RLS policy on `stamps`, `check_ins`, `photos`.

---

## 11. Activity & Notifications

**Route:** `/activity`  
**File:** `lib/features/profile/presentation/activity_screen.dart`

### Sections

1. **Friend requests** — accept (`acceptFriendRequest()`) / decline (`denyFriendRequest()`)
2. **Follow requests** — approve (`approveFollow()`) / deny (`denyFollow()`)
3. **Notifications** — chronological list with type-based icons

### Notification Types

| `type` | DB Trigger | Tap Action |
|---|---|---|
| `like` | INSERT stamp_likes | → `/stamp/:id` |
| `comment` | INSERT stamp_comments | → `/stamp/:id` |
| `follow` | INSERT follows (accepted) | → `/profile/:actorId` |
| `follow_accepted` | UPDATE follows pending→accepted | → `/profile/:actorId` |
| `tag` | UPDATE check_ins/stamps taggedUserIds | → `/stamp/:id` |
| `mention` | `create_mention_notification` RPC | → `/stamp/:id` |
| `friend_request` | INSERT friendships (pending) | → `/friend-requests` |
| `friend_accepted` | UPDATE friendships pending→accepted | → `/profile/:actorId` |

### Push Notifications

```
App start → NotificationService.initialize()
  → Firebase.initializeApp()
  → FirebaseMessaging.requestPermission()
  → getToken() → upsert into fcm_tokens table

Foreground message → flutter_local_notifications.show()
Background tap → onMessageOpenedApp → notificationRouteStream.add(route)
  → ZonApp._notifSub listener → router.go(route)

Status: Remote push BLOCKED (no APNs key — Apple paid enrollment required)
Local notifications: WORKING
```

### Bell Badge Count

```
unreadNotificationCountProvider
  → NotificationRepository.getUnreadCount()
  + followRequestsProvider.length
  + friendRequestsProvider.length
```

---

## 12. Settings & Privacy

**Route:** `/settings`  
**File:** `lib/features/profile/presentation/settings_screen.dart`

### Edit Profile Sheet

Opens `showModalBottomSheet` with username, display name, bio fields.  
`_saveProfile()` → `ProfileRepository.updateProfile({'username': ..., 'display_name': ..., 'bio': ...})`

### Privacy Controls

| Control | DB Field | Logic |
|---|---|---|
| Private account | `profiles.is_private` | When true: new follows create `status='pending'`; `can_view_user()` checks follow acceptance |
| Ghost mode | `profiles.is_ghost_mode` | Suppresses own location from `user_locations` Realtime channel |
| Location visibility | `location_hidden_from` table | Per-friend blocking via `/location-visibility` screen |

### Delete Account

```
→ confirm dialog
→ Supabase RPC (cascades: stamps, check-ins, photos, follows, friendships, locations)
→ Supabase.auth.signOut()
→ router.go('/login')
```

---

## 13. Social Graph Management

### FollowRequestsScreen (`/follow-requests`)

```
followRequestsProvider
  → ProfileRepository.getFollowRequests()
  → follows WHERE following_id = currentUser AND status = 'pending'

Approve → ProfileRepository.approveFollow(requesterId)
  → UPDATE follows SET status = 'accepted'
  → DB trigger: notify_on_follow_accepted → INSERT notification

Deny → ProfileRepository.denyFollow(requesterId)
  → DELETE FROM follows
```

### FriendRequestsScreen (`/friend-requests`)

```
friendRequestsProvider
  → ProfileRepository.getIncomingFriendRequests()
  → friendships WHERE (user_a or user_b = currentUser) AND status = 'pending' AND requested_by != currentUser

Accept → ProfileRepository.acceptFriendRequest(id)
  → UPDATE friendships SET status = 'accepted'
  → DB trigger: auto_follow_on_friendship → INSERT both follows rows (mutual)
  → DB trigger: notify_on_friend_accepted → INSERT notification

Decline → ProfileRepository.denyFriendRequest(id)
  → DELETE FROM friendships
```

### UserListScreen (`/profile/:id/friends|followers|following`)

```
mode=friends    → friendships WHERE user_a|user_b = id AND status='accepted'
mode=followers  → follows WHERE following_id = id AND status='accepted'
mode=following  → follows WHERE follower_id = id AND status='accepted'
→ renders UserListTile with quick follow/unfriend CTA
```

### UserSearchScreen (`/search`)

```
→ TextField with debounce
→ ProfileRepository.searchUsers(query)
→ result list → tap → /profile/:id
```

---

## 14. Place Discovery

### PlaceDetailScreen (`/place/:id`)

```
→ StampRepository.getStampsForPlace(externalPlaceId)
→ place info (name, lat, lng) from stamps
→ stamp grid + visitor count
→ "Check in here" → /checkin?mode=checkin
```

### Nearby Hot Places (Map bottom sheet)

```
_loadNearbyPlaces()
  → current GPS position
  → StampRepository.getNearbyHotPlaces(lat, lng, radiusKm: 5)
    → SELECT FROM place_stats WHERE lat/lng WITHIN bounding box
    → ORDER BY hot_score DESC LIMIT 20
  → carousel in bottom sheet
  → tap → /place/:id
```

### Place Service Routing

```
placeServiceFor(lat, lng)
  → if Korea (lat 33–38, lng 126–130) → KakaoPlaceService
      → Kakao Local API /v2/local/search/keyword.json
      → KAKAO_REST_API_KEY from .env
      → returns real GPS coordinates + place metadata
  → else → GooglePlaceService
      → Google Places Nearby Search API
      → returns coordinates + place metadata

Fallback: NaverPlaceService (text-only, no coordinates)
  → Naver Local Search API
  → used when Kakao has no results
```

---

## 15. Key Provider Graph

```
supabaseClientProvider  ←  Supabase.instance.client (singleton)

authStateStreamProvider  ←  supabaseClientProvider.auth.onAuthStateChange

currentUserProvider
  ←  authStateStreamProvider (dependency for re-eval on auth change)
  ←  supabaseClientProvider.auth.currentUser (synchronous read)

_routerProvider (keepAlive via ZonApp.build ref.watch)
  ←  currentUserProvider  (redirect logic)

[All repositories] (AutoDispose)
  ←  supabaseClientProvider
  ←  currentUserProvider

gpsNotifierProvider (keepAlive)
  ←  gpsServiceProvider
  ←  locationBatcherProvider (keepAlive)
  ←  checkInRepositoryProvider (for auto check-in dedup)
  ←  placeServiceForProvider(lat, lng) (for auto check-in name)
  ←  supabaseClientProvider.auth.currentUser (for batch userId)

locationBatcherProvider (keepAlive)
  ←  locationRepositoryProvider

timelineNotifierProvider (keepAlive)
  ←  stampRepositoryProvider, checkInRepositoryProvider,
      locationRepositoryProvider, diaryRepositoryProvider,
      timelineNoteRepositoryProvider  (all ref.read, not ref.watch)

feedNotifierProvider
  ←  stampRepositoryProvider

friendLocationsProvider (StreamProvider)
  ←  locationSharingRepositoryProvider → Supabase Realtime

ghostModeProvider (FutureProvider)
  ←  locationSharingRepositoryProvider.getGhostMode()

profileNotifierProvider(userId)  [.family]
  ←  profileRepositoryProvider

followStateProvider(userId)  [.family, FutureProvider]
  ←  profileRepositoryProvider

friendStateProvider(userId)  [.family, FutureProvider]
  ←  profileRepositoryProvider

placeServiceForProvider(lat, lng)  [.family]
  ←  environment variables (KAKAO_REST_API_KEY, GOOGLE_PLACES_KEY)
```

---

## 16. Database Tables

### Core Trace

| Table | Key Columns | Role | Visibility |
|---|---|---|---|
| `raw_location_events` | user_id, lat, lng, accuracy_m, source, captured_at | GPS breadcrumbs → route line | System-private (RLS blocks all non-own reads) |
| `check_ins` | user_id, place_name, lat, lng, note, source, visibility, stamp_id, visited_at | Visit pins | Private default; `visibility='public'` → 24h story |
| `stamps` | user_id, check_in_id, caption, sensory_tags, cover_photo_url, visibility, visited_at | Posts | Private default; `visibility='public'` → feed |

### Social

| Table | Key Columns | Role |
|---|---|---|
| `profiles` | id, username, display_name, avatar_url, is_private, is_ghost_mode, stamp_count, friend_count, follower_count | User profiles + denormalized counts |
| `follows` | follower_id, following_id, status {pending\|accepted} | Asymmetric follow graph |
| `friendships` | user_a, user_b, status {pending\|accepted}, requested_by | Symmetric friend graph (user_a < user_b canonical ordering) |

### Engagement

| Table | Key Columns | Role |
|---|---|---|
| `stamp_likes` | stamp_id, user_id | Like toggles |
| `stamp_saves` | stamp_id, user_id | Bookmark toggles |
| `stamp_comments` | stamp_id, user_id, body, parent_id, created_at | Threaded comments |

### Location & Notifications

| Table | Key Columns | Role |
|---|---|---|
| `user_locations` | user_id (PK), lat, lng, heading, accuracy, updated_at | Live position (Realtime) |
| `location_hidden_from` | user_id, hidden_from_id | Per-friend location block |
| `notifications` | type, user_id, actor_id, stamp_id, actor_username, read_at | Activity feed |
| `fcm_tokens` | user_id, token, platform, updated_at | Push registration |

### Discovery & AI

| Table | Key Columns | Role |
|---|---|---|
| `place_stats` | external_place_id, place_name, lat, lng, stamp_count, visitor_count, hot_score, last_visit | Denormalized trending/nearby view |
| `day_diaries` | user_id, date (PK pair), body, updated_at | AI-generated + manual diary entries |
| `photos` | id, url, check_in_id, stamp_id, user_id | Media attachments |

### DB Functions & RPCs

| Name | Purpose |
|---|---|
| `can_view_user(p_owner uuid)` | Universal privacy gate (SECURITY DEFINER) |
| `check_ins_for_local_day(p_date)` | Calendar-day check-ins (timezone-aware) |
| `route_events_for_day(p_user_id, p_date)` | GPS breadcrumbs for a day |
| `monthly_visit_counts(p_year, p_month)` | Day-of-month visit aggregates for calendar dots |
| `auto_follow_on_friendship` | Trigger: accepted friendship → insert both follow rows |
| `enforce_follow_status` | Trigger: private account → follow starts as pending |
| `notify_on_*` | Triggers: like, comment, follow, tag, friend events → INSERT notifications |
| `create_mention_notification` | RPC: `@mention` in comment → notification |

### Edge Functions

| Function | Purpose |
|---|---|
| `ingest-location` | Batch GPS events → `raw_location_events` |
| `generate-diary` | Gemini 3.1 flash lite multimodal → AI diary text |
| `suggest-stamp` | Place suggestions (pre-existing) |
| `match-place` | Canonical place matching (pre-existing) |
| `geocode-nudge` | Reverse-geocode for auto check-in (pre-existing) |

---

## 17. Route Map

All routes defined in `lib/app.dart`.

| Path | Screen | Shell? | Notes |
|---|---|---|---|
| `/login` | `LoginScreen` | No | OAuth entry, public |
| `/feed` | `FeedScreen` | Yes | Main feed (3 tabs) |
| `/map` | `MapScreen` | Yes | Live map |
| `/timeline` | `TimelineScreen` | Yes | Historical trace |
| `/profile` | `ProfileScreen` (own) | Yes | Own profile |
| `/checkin` | `CheckinEntry` | No | Full-screen modal; query params: `mode`, `lat`, `lng`, `fromCheckIn`, `time` |
| `/check-in/:id` | `CheckInDetailScreen` | No | View a check-in |
| `/stamp/:id` | `StampDetailScreen` | No | Full stamp + comments |
| `/stamp/:id/edit` | `EditStampScreen` | No | Edit own stamp |
| `/photo-suggestions` | `PhotoSuggestionScreen` | No | Photo import modal |
| `/settings` | `SettingsScreen` | No | Account/privacy |
| `/check-ins` | `CheckInListScreen` | No | Own check-in history |
| `/saved` | `SavedStampsScreen` | No | Bookmarked stamps |
| `/search` | `UserSearchScreen` | No | Find people |
| `/activity` | `ActivityScreen` | No | Notifications + requests |
| `/follow-requests` | `FollowRequestsScreen` | No | Approve pending follows |
| `/friend-requests` | `FriendRequestsScreen` | No | Approve pending friend requests |
| `/location-visibility` | `LocationVisibilityScreen` | No | Per-friend location sharing |
| `/place/:id` | `PlaceDetailScreen` | No | Stamps at a place |
| `/profile/:id` | `ProfileScreen` (other) | No | View another user |
| `/profile/:id/friends` | `UserListScreen(friends: true)` | No | |
| `/profile/:id/followers` | `UserListScreen(followers: true)` | No | |
| `/profile/:id/following` | `UserListScreen(followers: false)` | No | |

**Navigation patterns:**
- Shell tabs (`/feed`, `/map`, `/timeline`, `/profile`): `context.go()`, state preserved
- Drill-downs: `context.push()` / `Navigator.push()`
- Modals (`/checkin`, `/photo-suggestions`): `context.push()`, full-screen

---

## 18. Data Models

### CheckIn

```dart
CheckIn {
  id, userId, placeName, normalizedPlaceName,
  lat, lng, externalPlaceId, externalSource,
  note,
  source,          // CheckInSource { manual | photo | auto }
  visibility,      // StampVisibility { private | public }
  taggedUserIds,   // List<String>
  photoUrls,       // populated on fetch (not stored on row)
  photoCount,
  stampId,         // non-null if promoted to stamp
  visitedAt, createdAt, updatedAt
}
```

### Stamp

```dart
Stamp {
  id, userId, placeName, normalizedPlaceName,
  lat, lng, externalPlaceId, externalSource,
  checkInId,       // parent check-in (1:1, never null)
  visibility,      // StampVisibility
  coverPhotoUrl, caption,
  sensoryTags,     // List<String>
  taggedUserIds,
  photoUrls, photoCount,
  likeCount, commentCount,
  isLiked, isSaved,
  username, avatarUrl,   // joined from profiles via v_feed_stamps
  visitedAt, createdAt, updatedAt
}
```

### UserProfile

```dart
UserProfile {
  id, username, displayName, avatarUrl, bio,
  stampCount, friendCount, followerCount, followingCount,
  isPrivate,
  createdAt
}
```

### Social Enums

```dart
enum FollowState  { none, requested, following }
enum FriendState  { none, requestedByMe, requestedByThem, friends }
enum CheckInSource { manual, photo, auto }
enum StampVisibility { private, public }
enum MapFilter { today, week, month, year, all, custom }
```

### DayBundle (Timeline)

```dart
DayBundle {
  date: DateTime,
  route: List<RawLocationEvent>,   // GPS breadcrumbs → route line
  checkIns: List<CheckIn>,         // visit pins
  stamps: List<Stamp>,             // promoted posts
  notes: List<TimelineNote>,       // free-text note nodes
  diary: String,                   // AI-generated or manually written
}
```

### FriendLocation

```dart
FriendLocation {
  userId, username, avatarUrl,
  lat, lng, accuracy, heading,
  updatedAt,
  bool isStale,     // updatedAt >= 8h ago
  String timeLabel  // "Just now" | "Xm ago" | "Xh ago"
}
```

---

## 19. Error Handling

### Result Pattern

All repository methods return `Either<AppException, T>` (fpdart).

```dart
// Usage in UI:
result.fold(
  (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message))),
  (data) => handleSuccess(data),
);
```

### Exception Types

| Type | When |
|---|---|
| `AuthError` | `currentUserId == null` on any repo method |
| `NetworkError` | Supabase throws, HTTP error, timeout |

`LocationError`, `PhotoError`, and `NotFoundError` were removed — they were unused dead code. Only the three above remain in `lib/core/errors/app_exception.dart`.

### Async Safety Pattern

All async UI callbacks guard `context.mounted` / `mounted` after each `await`:

```dart
onTap: () async {
  final result = await repo.doSomething();
  if (!context.mounted) return;
  result.fold(...);
},
```
