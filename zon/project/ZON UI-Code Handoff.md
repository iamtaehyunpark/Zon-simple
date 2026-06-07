# ZON — UI/UX ↔ Code Handoff Prompt
> Generated 2026-06-07 · Prototype: `Zon Prototype.html` · Codebase: `zon-dev-v2/` (Flutter + Supabase)

---

## 1. Agent Context

You are implementing the **ZON** mobile app in Flutter. A high-fidelity interactive prototype (`Zon Prototype.html`) defines the target visual design and interaction model under **Direction D (Final)**. The Flutter codebase in `zon-dev-v2/` is a working MVP with Phases 0–14 complete. Your job is to close the gap between what the prototype shows and what the code currently does.

**Before touching any file**, read:
- `zon-dev-v2/CLAUDE.md` — full architecture, data model, conventions, migration log
- `zon-dev-v2/docs/design-guide.md` — visual spec, component rules, spacing, typography
- `zon-dev-v2/docs/map-discovery-plan.md` — Phases A–E for the map layer
- `Zon Prototype.html` — the living design reference; open it in a browser to interact

---

## 2. Design → Code Mapping

### Brand color
| Prototype | Code today | Action required |
|---|---|---|
| `#8B6EC4` warm purple | `kBrandGreen = Color(0xFF1D9E75)` teal | Replace `kBrandGreen` in `app_theme.dart` with `Color(0xFF8B6EC4)` and rename to `kBrandPurple` (or whichever the team locks) |

### Initial route
| Prototype | Code |
|---|---|
| Opens on **Map** tab | `initialLocation: '/feed'` in `app.dart` |
| Change `initialLocation` to `'/map'` |

### Navigation shell
The prototype uses a 5-tab bottom nav with a **center FAB** that expands to 3 sub-options (Check in / Photo check-in / Create stamp). The existing `MainShell` in `app.dart` already implements this pattern — match the FAB expand animation from the prototype (staggered fade-up, 80ms between items, rotate FAB icon 45° when open).

### Component names (prototype → Flutter)
| Prototype component | Flutter equivalent |
|---|---|
| `StampCard` | `StampCard` in `feed_screen.dart` |
| `StoriesRail` | `_StoriesRail` in `feed_screen.dart` |
| `StoryViewer` | `_StoryView` dialog in `feed_screen.dart` |
| `TimelineNode` | Inline node widgets in `timeline_screen.dart` |
| `MapCanvas` | `MapboxMap` widget in `map_screen.dart` |
| `CheckInSheet` | `CheckinEntry` fullscreen dialog |
| `PlaceDetailScreen` | **Does not exist yet** — Phase D stub |
| `NearbyCard` | **Does not exist yet** — Phase E stub |
| `KindChip` | Inline `Chip` widgets in `timeline_screen.dart` |

---

## 3. Gap Report

### 3A — In the UI prototype but NOT yet in the codebase

These are designed interactions the prototype shows. No Flutter code backs them.

| # | Feature | Prototype location | What to build | Ref doc |
|---|---|---|---|---|
| 1 | **Map search bar** | Map screen, floating top bar | Floating `TextField` on `MapScreen`; calls `PlaceRepository.search()`; renders a "search result" pin layer distinct from social pins | `map-discovery-plan.md` Phase A |
| 2 | **Category filter chips on map** | Map screen, strip below search | `HorizontalScrollView` of chips; filters `hot_score` layer + nearby list simultaneously; category derived from `places.category` | Phase B |
| 3 | **Hot places cluster layer** | Map screen, numbered circles on map | `GeoJsonSource` layer of sized circles from `place_stats` view; radius ∝ `log(hot_score)`; color by category; zoom-gated (≥13) | Phase C |
| 4 | **Place Detail page** (`/place/:id`) | Tapping nearby card or map cluster | New screen: hero photo, place info, ZON stats (stamp count/visitors/last visit), friends-been-here avatars, public photos grid, stamps from this place. CTA: "Check in here" pre-fills `/checkin?placeId=` | Phase D |
| 5 | **Nearby hot list** (real data) | Map bottom sheet, expanded state | Query `place_stats` view ordered by `hot_score` within viewport bounds; feeds `NearbyCard` list; category filter applies | Phase E |
| 6 | **Feed "Nearby" tab** | Feed screen, 2nd tab | Query stamps/places within radius of user's current location; distinct from Following feed | design-guide §4.2 |
| 7 | **Feed "Trending" tab** | Feed screen, 3rd tab | Query `place_stats.hot_score` descending; show stamps from high-activity places globally | design-guide §4.2 |
| 8 | **"Saved" filter on map** | Map bottom sheet filter chips | Filter the stamp layer to only show the current user's saved stamps; already have `getSavedStamps()` in repo | `advanced-features-plan.md` |
| 9 | **Diaries tab on Profile** | Profile screen, 3rd tab | Query `diary_entries` (or `timeline_notes` with `is_diary = true`) for the user, sorted by date descending; render as a text thread with date headers | design-guide §4.7 |
| 10 | **Draggable bottom sheet on Map** | Map screen | The prototype's snap panel drags up/down over the map. Replace the current static `Column` layout with `DraggableScrollableSheet` (same pattern as `timeline_screen.dart`) | design-guide §5.1 |
| 11 | **Brand color token system** | Prototype-level | The prototype exposes Purple/Teal/Forest swatches. Wire `AppTheme.theme(seedColor)` to a user preference stored in `user_preferences` table or `shared_preferences`. | — |

---

### 3B — In the codebase but NOT in the UI prototype

These features are fully built but the prototype doesn't show them. They need no new code — they need UI entry points and visual polish to match the design language.

| # | Feature | Code location | Missing in prototype | Action |
|---|---|---|---|---|
| 1 | **Check-in detail screen** | `check_in_detail_screen.dart` · `/check-in/:id` | Tapping a timeline check-in node pushes the detail — prototype doesn't navigate there | Add `onTap` on timeline check-in nodes → push `/check-in/:id` |
| 2 | **Edit stamp screen** | `edit_stamp_screen.dart` · `/stamp/:id/edit` | Stamp detail has a `more_vert` menu but no Edit option wired | Add "Edit" to stamp detail overflow menu → push `/stamp/:id/edit` |
| 3 | **Check-in list screen** | `check_in_list_screen.dart` · `/check-ins` | Entry point (pin icon on own profile) exists in code but not in prototype profile header | Add a subtle pin/trail icon button to the profile identity row → `/check-ins` |
| 4 | **Follow requests screen** | `follow_requests_screen.dart` · `/follow-requests` | Activity screen shows friend requests but follow requests aren't reachable | Add "Follow requests" row in Activity screen header (already in code, just needs entry point in Activity UI) |
| 5 | **Friend requests screen** | `friend_requests_screen.dart` · `/friend-requests` | Same as above — wired but unreachable from prototype | Same fix as #4 |
| 6 | **Location visibility (per-friend)** | `location_visibility_screen.dart` · `/location-visibility` | Settings screen has Ghost mode toggle but no link to per-friend control | Add "Location visibility" row under Privacy section in Settings → `/location-visibility` |
| 7 | **Saved stamps screen** | `saved_stamps_screen.dart` · `/saved` | Profile "Saved" tab just shows the same grid — should route to dedicated screen | Profile "Saved" tab → push `/saved` instead of rendering inline |
| 8 | **Photo suggestion flow** | `photo_suggestion_screen.dart` + `photo_check_in_inspection_screen.dart` · `/photo-suggestions` | Prototype FAB "Photo check-in" option navigates here — the route exists but the screen design (swipeable inspection cards) isn't reflected | Apply design-guide §4.4 photo path styling to `PhotoCheckInInspectionScreen` |
| 9 | **User tag field** | `user_tag_field.dart` | Stamp editor and check-in editor both support user tagging — prototype's stamp editor doesn't show it | Add `UserTagField` row to both editor screens |
| 10 | **Comment replies + @mention** | `stamp_detail_screen.dart` | Built with 1-level reply nesting and mention picker — prototype shows flat comments | Update stamp detail comment thread to show reply indentation and @mention chip |
| 11 | **Private account / locked grid** | `profile_screen.dart` + `follow_requests_screen.dart` | Private profiles should show a locked grid to non-followers — prototype doesn't show this state | Add locked-grid empty state on `ProfileScreen` when `!canView` |
| 12 | **Followers / Following / Friends lists** | `user_list_screen.dart` · `/profile/:id/followers` etc. | Profile stats are tappable in prototype but don't navigate anywhere | Wrap stat numbers in `GestureDetector` → push respective list route |

---

## 4. Routing Reconciliation

The prototype uses client-side routing names. Map them to GoRouter paths before implementing:

| Prototype `navigate()` call | GoRouter path | Notes |
|---|---|---|
| `'map'` | `/map` | Tab switch |
| `'feed'` | `/feed` | Tab switch |
| `'timeline'` | `/timeline` | Tab switch |
| `'profile'` | `/profile` | Tab switch |
| `'checkin'` | `/checkin` | Fullscreen dialog |
| `'stamp-editor'` | `/checkin?mode=stamp` | Reuses `CheckinEntry` |
| `'stamp-detail'` | `/stamp/:id` | Push |
| `'place-detail'` | `/place/:id` | **New route — does not exist yet** |
| `'activity'` | `/activity` | Push |
| `'settings'` | `/settings` | Push |
| `'user-search'` | `/search` | Push |
| `'story-viewer'` | Inline dialog in `FeedScreen` | Already a dialog, no route |
| `'photo-checkin'` | `/photo-suggestions` | Fullscreen dialog |

---

## 5. Implementation Priority

Suggested order to minimize regressions and maximize user-visible impact:

```
P0 (visual parity — no new backend):
  - Brand color token (#8B6EC4) + AppTheme seed
  - Initial route → /map
  - FAB expand animation matching prototype
  - Map draggable bottom sheet (DraggableScrollableSheet)
  - Wire entry points for #1–#6 in §3B (detail screens, lists)

P1 (new UI, existing data):
  - Feed Nearby tab (location query already in repos)
  - Saved filter on map (getSavedStamps exists)
  - Profile Diaries tab (query diary from existing timeline_notes)
  - Profile stat tap → list routes

P2 (new features, new data):
  - Phase A: Map search bar + PlaceRepository.search()
  - Phase B: Category filter chips
  - Phase D: Place detail page (scaffold + Supabase query)
  - Phase E: Nearby hot list from place_stats view

P3 (discovery layer, requires place_stats populated):
  - Phase C: Hot places cluster layer on map
  - Feed Trending tab
```

---

## 6. Design Tokens to Enforce

Pull exact values from `Zon Prototype.html` → `zon-tokens.jsx`. Enforce in `app_theme.dart`:

```dart
// Colors
static const brand       = Color(0xFF8B6EC4);
static const checkin     = Color(0xFF3B82F6);
static const following   = Color(0xFFF59E0B);
static const story       = Color(0xFFEC4899);
static const note        = Color(0xFFD97706);
static const auto        = Color(0xFF9CA3AF);
static const surface0    = Color(0xFFF7F4EE); // scaffold bg
static const surface1    = Color(0xFFFFFFFF); // card bg
static const surface2    = Color(0xFFF0EDE6); // sheet bg

// Radii
static const r8  = Radius.circular(8);
static const r12 = Radius.circular(12);
static const r16 = Radius.circular(16);
static const r24 = Radius.circular(24);

// Typography: use system font (SF Pro / Roboto) for v1
// title-lg: 20–22, w600 | body: 15–16, w400 | label: 11–12, w700 uppercase
```

All spacing must follow the **8pt grid**: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64.
Minimum tap target: **44×44pt** on every interactive element.

---

*End of handoff document. The prototype is the source of truth for layout, spacing, and interactions. The codebase is the source of truth for data models, RLS rules, and business logic.*
