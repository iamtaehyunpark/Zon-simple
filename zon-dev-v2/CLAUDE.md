# ZON — Claude Code Project Context (v2.0)

> **Read this file before every session. Do not deviate from the rules below.**
> This is v2.0 — the pivot version. AI model pipeline has been removed from MVP scope.

---

## 1. What is ZON

ZON is a **place-based diary SNS**. It automatically collects location data from multiple sources (GPS while app is open, photo EXIF, significant-change cell tower detection) and lets users turn meaningful moments into **Stamps** — rich cards with photos, text, and sensory tags that can be kept private or shared on a social feed.

**Core loop:**
```
Location data collected passively
    → System suggests "add a Stamp here?"
    → User creates Stamp (photo + text + tags)
    → Stamp stays private by default
    → User optionally makes it public → appears in feed
```

**Two-layer data model:**
- `RawLocationEvent` — system layer, not directly visible to users, powers the map route and Stamp suggestions
- `Stamp` — user layer, the actual content object, private by default

---

## 2. What Changed from v1 (Important)

**REMOVED from MVP scope (do not implement):**
- TensorFlow Lite / ONNX Runtime
- All AI vision models (Depth Anything, SuperPoint, LightGlue, MixVPR)
- Liveness detection pipeline
- Verification tier system (Tier 1/2/3)
- Badge system based on verification
- On-device signing / proof certificates
- Consensus place registration (n-round cross-validation)

**These are valid future features. When asked to implement them, say:**
> "This is a future version feature (post-MVP vision model layer). Adding a TODO and skipping for now."

**ADDED / CHANGED:**
- Always-on GPS tracking while app is foregrounded (no background continuous tracking)
- Photo EXIF parsing via `photo_manager`
- Significant-change location updates (background cell tower detection)
- `RawLocationEvent` table replaces the `Visit` concept
- Stamp is private by default, user explicitly makes public
- Feed shows Stamp units (public only)
- Map shows RawLocationEvent route lines + Stamp pins + unlinked photo icons
- Companion detection via GPS proximity (MVP: manual tag suggestion; Phase 2: auto BLE)
- Google Places API for external place matching (store `external_place_id` on every Stamp)

---

## 3. Tech Stack (Non-Negotiable)

| Layer | Choice | Notes |
|---|---|---|
| App | Flutter (Dart) | iOS first, Android Phase 2 |
| State Management | Riverpod | `@riverpod` code generation |
| Navigation | go_router | Declarative routing only |
| Backend | Supabase | PostgreSQL + Auth + Storage + Realtime + Edge Functions |
| Maps | Mapbox Flutter SDK | Full-screen overlay style |
| Location | geolocator + geofence_service | iOS "While Using" permission only |
| Background location | iOS CLLocationManager (significant-change) | NOT "Always Allow" |
| Photo access | photo_manager | iOS Photos Framework, EXIF parsing |
| Geocoding | Mapbox Geocoding API | Coordinates → place name. Call sparingly. |
| Place search | Google Places API | External place ID matching |
| HTTP | Dio | With auth interceptors |
| Local storage | Hive | Cached route events, draft Stamps |
| Push notifications | firebase_messaging | FCM for significant-change nudges |
| Image | flutter_image_compress + cached_network_image | |

**Never introduce new dependencies without updating `pubspec.yaml` and `docs/dependencies.md`.**

---

## 4. Project Folder Structure

```
zon/
├── CLAUDE.md
├── pubspec.yaml
├── .env                          ← Never commit
├── .env.example
├── docs/
│   ├── schema.sql                ← Supabase DB schema (source of truth)
│   ├── api.md                    ← Edge Function API reference
│   ├── permissions.md            ← iOS/Android permission rationale
│   └── dependencies.md
├── supabase/
│   ├── migrations/               ← Numbered SQL files
│   └── functions/
│       ├── ingest-location/      ← Batch RawLocationEvent ingestion
│       ├── suggest-stamp/        ← Stamp suggestion from events
│       ├── geocode-nudge/        ← Geocode + send notification
│       └── match-place/          ← Google Places API matching
├── lib/
│   ├── main.dart
│   ├── app.dart                  ← MaterialApp + go_router
│   ├── core/
│   │   ├── location/
│   │   │   ├── gps_service.dart           ← Foreground GPS tracking
│   │   │   ├── significant_change.dart    ← Background cell tower detection
│   │   │   └── location_models.dart
│   │   ├── photos/
│   │   │   ├── photo_service.dart         ← photo_manager + EXIF parsing
│   │   │   └── photo_models.dart
│   │   ├── notifications/
│   │   │   └── notification_service.dart  ← FCM + local notifications
│   │   ├── auth/
│   │   │   └── auth_service.dart          ← Supabase auth
│   │   └── errors/
│   │       └── app_exception.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── raw_location_event.dart    ← Freezed
│   │   │   ├── stamp.dart                 ← Freezed
│   │   │   ├── photo.dart                 ← Freezed
│   │   │   ├── user_profile.dart          ← Freezed
│   │   │   └── enums.dart                 ← LocationSource, Visibility, etc.
│   │   ├── repositories/                  ← Abstract interfaces
│   │   └── datasources/
│   │       ├── remote/                    ← Supabase calls
│   │       └── local/                     ← Hive cache
│   ├── features/
│   │   ├── feed/
│   │   │   └── presentation/
│   │   │       ├── feed_screen.dart
│   │   │       └── stamp_card.dart
│   │   ├── map/
│   │   │   └── presentation/
│   │   │       ├── map_screen.dart         ← Full-screen Mapbox
│   │   │       ├── route_layer.dart        ← RawLocationEvent path rendering
│   │   │       ├── stamp_pin_layer.dart    ← Stamp pins on map
│   │   │       └── photo_icon_layer.dart   ← Unlinked photo icons
│   │   ├── checkin/                        ← Central CTA flow
│   │   │   └── presentation/
│   │   │       ├── checkin_entry.dart      ← Place selection
│   │   │       ├── stamp_editor.dart       ← Photo + text + tags
│   │   │       └── stamp_complete.dart     ← Save + visibility choice
│   │   ├── photo_import/
│   │   │   └── presentation/
│   │   │       ├── photo_suggestion.dart   ← "Add this photo to map?"
│   │   │       └── bulk_import.dart        ← Batch EXIF import
│   │   ├── timeline/
│   │   │   └── presentation/
│   │   │       ├── timeline_screen.dart
│   │   │       ├── calendar_view.dart
│   │   │       ├── map_view.dart
│   │   │       └── list_view.dart
│   │   └── profile/
│   │       └── presentation/
│   │           ├── profile_screen.dart
│   │           └── stamp_grid.dart
│   └── shared/
│       ├── widgets/
│       ├── theme/                          ← Design tokens (TBD)
│       └── utils/
└── test/
    ├── unit/
    ├── widget/
    └── integration/
```

---

## 5. Architecture Rules

### 5.1 Feature Structure (Clean Architecture)
```
feature/
├── data/
│   ├── datasources/  ← Supabase / Hive
│   ├── models/       ← JSON serialization
│   └── repositories/ ← Implements domain interface
├── domain/
│   ├── entities/     ← Pure Dart
│   ├── repositories/ ← Abstract interface
│   └── usecases/     ← Single-responsibility
└── presentation/
    ├── providers/    ← Riverpod state
    └── screens/      ← UI only
```

### 5.2 State Management
- All state through Riverpod. No `setState()` except local ephemeral UI.
- `AsyncNotifierProvider` for Supabase data.
- `NotifierProvider` for synchronous state.

### 5.3 Navigation
- All routes in `lib/app.dart` via `go_router`.
- Named routes only. Pass IDs between routes, not full objects.

### 5.4 Error Handling
- Repositories return `Either<AppException, T>` via `fpdart`.
- Never swallow exceptions silently.

---

## 6. Location & Photo Rules

### 6.1 GPS (Foreground Only)
```dart
// ONLY collect GPS when app is in foreground
// Use geolocator with LocationPermission.whileInUse
// Start tracking in AppLifecycleState.resumed
// Stop tracking in AppLifecycleState.paused

// Collect every 30 seconds OR when movement > 50m
// Batch upload to Supabase every 5 minutes
// Store locally in Hive when offline
```

### 6.2 Significant-Change (Background)
```dart
// iOS: CLLocationManager.startMonitoringSignificantLocationChanges()
// Android: FusedLocationProviderClient with PRIORITY_LOW_POWER
// Purpose: ONLY for triggering check-in nudge notifications
// NOT for continuous route tracking
// Accuracy: 500m–several km (acceptable for notification triggers)
```

### 6.3 Photo EXIF Parsing
```dart
// Request photo_manager permission on first launch
// Listen for new photos added to library
// Parse EXIF: lat, lng, taken_at
// Filter: only photos WITH location data
// Do NOT send image bytes to server for EXIF parsing
//   → parse entirely on device, send only coordinates + timestamp
// Batch process: wait 30 minutes after photo is taken before suggesting
```

### 6.4 Privacy Rules
- Raw GPS route data is ALWAYS private (never shown to other users)
- Stamps are private by default
- Only public Stamps appear in friend feeds or friend maps
- Users can delete all location history at any time
- No real-time location sharing between users in MVP

---

## 7. Data Model Reference

### RawLocationEvent
```dart
@freezed
class RawLocationEvent with _$RawLocationEvent {
  const factory RawLocationEvent({
    required String id,
    required String userId,
    required double lat,
    required double lng,
    required double accuracyM,
    required LocationSource source,    // gps | exif | cellTower
    required DateTime capturedAt,
    String? photoId,                   // if from photo EXIF
    String? stampId,                   // if linked to a Stamp
    String? geocodedName,              // filled lazily for notifications
  }) = _RawLocationEvent;
}

enum LocationSource { gps, exif, cellTower }
```

### Stamp
```dart
@freezed
class Stamp with _$Stamp {
  const factory Stamp({
    required String id,
    required String userId,
    required String placeName,
    required double lat,
    required double lng,
    required StampVisibility visibility,   // private (default) | public
    required DateTime visitedAt,
    String? normalizedPlaceName,
    String? externalPlaceId,              // Google Place ID — always store if available
    String? externalSource,               // 'google_places', 'kakao'
    String? coverPhotoUrl,
    String? caption,
    @Default([]) List<String> sensoryTags,
    @Default([]) List<String> taggedUserIds,
    @Default([]) List<String> photoUrls,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(false) bool isLiked,
    @Default(false) bool isSaved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Stamp;
}

enum StampVisibility { private, public }
```

### Key Rule: Always Store external_place_id
```dart
// When creating a Stamp:
// 1. Check if existing Stamp within 100m radius
// 2. If no existing Stamp → call Google Places API to find nearest place
// 3. Store external_place_id even if user doesn't see it
// 4. This enables future place DB migration without data loss
//
// Rate limit: only call Places API if no Stamp within 100m
// Budget: ~$0.017 per call → ~60K calls per $1
```

---

## 8. MVP Scope

### In MVP (M1–M3):
- Active check-in flow (place selection → photo/text/tags → Stamp)
- Photo-based Stamp creation (EXIF parsing → match nearby Stamp → suggest add)
- Significant-change notifications (background detection → nudge → check-in)
- Full-screen Mapbox map with:
  - GPS route lines (foreground tracking)
  - Stamp pins (all user's own Stamps)
  - Unlinked photo icons (photos not added to any Stamp)
  - Date filter
- Timeline (calendar + map + list views)
- Feed (public Stamps only, friends + recommendations)
- Social basics: follow/friend system, manual companion tag on Stamp
- Nearby friend tag suggestion at check-in time (GPS-based)
- Profile with public Stamp grid + visit stats
- Google Places API matching + external_place_id storage
- Push notifications (significant-change nudge, photo add suggestion, evening summary)
- Private by default, per-Stamp visibility toggle

### NOT in MVP (do not implement):
- Automatic companion detection (BLE-based) → Phase 2
- Companion route sharing / journey summary cards → Phase 2
- External share cards → Phase 2
- Own place database → Phase 2 (accumulates from user data)
- Route navigation (Mapbox Navigation) → Phase 3
- Premium subscription → Phase 3
- Vision model verification (Tier system, liveness detection) → future version
- Badge system based on verification → future version
- B2B campaign tools → future version

---

## 9. Notification Rules

```
Significant-change nudge:
  → Max 2 per hour
  → 30-minute cooldown after last notification
  → Message: "Looks like you're near [geocoded_name]. Want to add a Stamp?"

Photo add suggestion:
  → Triggered 30 minutes after new photo with EXIF location detected
  → Batch: group multiple photos from same location into one notification
  → Max 3 per day
  → Message: "You took [N] photos near [place]. Add them to your map?"

Evening summary:
  → Daily at 8pm (user-configurable)
  → Only if user has new RawLocationEvents that day without Stamps
  → Message: "You visited [place1], [place2] today. Want to remember it?"

Companion suggestion:
  → Triggered at check-in time only
  → If friend's last known location within 300m AND within last 30 minutes
  → Message inline in check-in flow: "Friend X seems to be nearby. Add as companion?"
```

---

## 10. Mapbox Layer Order

```
Bottom → Top:
1. Mapbox base map style
2. Route line layer (RawLocationEvents connected by time)
3. Unlinked photo icon layer (small thumbnails)
4. Stamp pin layer (larger pins, public=colored, private=muted)
5. Friend Stamp layer (Phase 2 — only public Stamps)
6. UI overlay (search bar top, bottom sheet)
```

---

## 11. Coding Conventions

### Dart / Flutter
```dart
// ✅ Freezed for all data models
// ✅ Either<AppException, T> for all repo methods
// ✅ AsyncNotifierProvider for async state
// ✅ Named routes via go_router
// ✅ TODO(phase2): / TODO(future): for deferred features

// ❌ No business logic in widgets
// ❌ No direct Supabase calls in widgets
// ❌ No setState() for persistent state
// ❌ No "Always Allow" location permission request
// ❌ No continuous background GPS (significant-change only)
```

### File Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Riverpod providers: `camelCaseProvider`

---

## 12. iOS Permissions Required

```xml
<!-- Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>ZON uses your location while you're using the app to track your route and suggest check-ins.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>ZON uses significant location changes in the background to notify you when you arrive somewhere new.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>ZON reads your photo locations to automatically add them to your personal map and timeline.</string>

<key>NSUserNotificationsUsageDescription</key>
<string>ZON sends reminders to add a Stamp when you visit somewhere new.</string>
```

**Note:** Request `whileInUse` first. Only escalate to `always` if user explicitly enables significant-change notifications. Explain why in the UI before requesting.

---

## 13. Phase Tracking

Current phase: **M0 (Pre-development)**

- [ ] M0 W1: Project setup, Supabase schema, Mapbox prototype
- [ ] M0 W2: Location permissions, EXIF parsing, significant-change test
- [ ] M0 W3: State management skeleton, 5-tab navigation, Stamp creation UI
- [ ] M0 W4: Google Places API, route line rendering, integration test
- [ ] M1: Active check-in + GPS route + Stamp CRUD
- [ ] M2: Photo EXIF import + significant-change + timeline + map layers
- [ ] M3: Feed + social basics + notifications + App Store launch
- [ ] M4–M6: Phase 2 features
- [ ] M7+: Phase 3 + future vision model layer

---

## 14. Quick Reference

| Question | Answer |
|---|---|
| Where does Supabase code go? | `data/datasources/remote/` |
| Where does location logic go? | `lib/core/location/` |
| Where does photo logic go? | `lib/core/photos/` |
| What is a RawLocationEvent? | Raw GPS/EXIF/cell coordinate — system internal, not shown to user directly |
| What is a Stamp? | User-created place record — private by default, optionally public |
| Feed unit? | Stamp (public only) |
| Map unit? | RawLocationEvent (route) + Stamp (pins) + Photo (unlinked icons) |
| Can I track location in background? | Significant-change ONLY. No continuous background GPS. |
| Can I send photos to server? | Send URLs only. Parse EXIF on device. Never upload for AI processing in MVP. |
| Default Stamp visibility? | private — always |
| Where is the DB schema? | `docs/schema.sql` |
| Should I implement the vision model pipeline? | NO — future version only |
