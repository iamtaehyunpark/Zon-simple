# ZON — UI/UX Design Guide

> Version 1.0 · 2026-06-07 
> This is a ground-up design guide. The current app is a debugging POC — ignore it entirely.
> Map discovery features (Phase A–E from `map-discovery-plan.md`) are not yet built;
> their design considerations are marked **[MAP PLACEHOLDER]** throughout.

---

## 1. Design Philosophy

### 1.1 Three principles

**Personal first, social second.**
ZON records where you've been before it shares anything. Every screen should feel like opening
a personal diary, not scrolling a social feed. Social features are layered on top of a private
core, not the reverse.

**Place is the hero.**
Every interaction is anchored to a real location. Photos, notes, friends, memories — they all
hang on a place. Design should constantly reinforce this: names of places, map context, distance
cues. A post without a visible place reference is a design failure.

**Layers, not tabs.**
ZON's data model has three layers (breadcrumb → check-in → stamp). The UI should let users move
between these layers fluidly rather than siloing them into separate apps. A stamp is just a
check-in with more effort; a check-in is just a breadcrumb the user chose to name.

---

### 1.2 Personality

| Dimension | Direction                                                    |
| --------- | ------------------------------------------------------------ |
| Tone      | Personal, warm, slightly quiet — a journal, not a billboard |
| Energy    | Calm with moments of delight (not flat, not loud)            |
| Trust     | Privacy-first by default; sharing is always an explicit act  |
| Density   | Generous whitespace in feed/timeline; dense in map mode      |

---

## 2. Visual Foundation

### 2.1 Color system

Define the full palette before choosing a brand color. Exact hex values are left to the visual
designer; these are roles.

| Token                  | Role                                          | Notes                                                                                                                                                                                        |
| ---------------------- | --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--brand`            | Primary interactive + trail color             | Should read on both white backgrounds and satellite map tiles. A warm deep teal or forest green works; avoid pure blue (conflicts with map water) and pure red (conflicts with error states) |
| `--brand-soft`       | Check-in pins, stories ring, selection states | ~20% opacity of `--brand`                                                                                                                                                                  |
| `--stamp`            | Stamp-specific accent                         | Can be the same as `--brand` or a warmer sibling; stamps are promoted check-ins                                                                                                            |
| `--checkin`          | Manual check-in pins                          | Differentiated from stamp but in the same family                                                                                                                                             |
| `--auto`             | Auto / passive check-in pins                  | Muted grey; these are GPS breadcrumbs, not user-chosen moments                                                                                                                               |
| `--note`             | Timeline free-text notes                      | Warm amber — connotes handwriting                                                                                                                                                           |
| `--surface-0`        | Page/sheet background                         | Near-white in light mode                                                                                                                                                                     |
| `--surface-1`        | Card background                               | Slight elevation from surface-0                                                                                                                                                              |
| `--surface-2`        | Elevated sheet, modal                         |                                                                                                                                                                                              |
| `--on-surface`       | Primary text                                  |                                                                                                                                                                                              |
| `--on-surface-muted` | Secondary text, timestamps                    |                                                                                                                                                                                              |
| `--outline`          | Borders, dividers                             |                                                                                                                                                                                              |
| `--error`            | Destructive actions, error states             | Standard red                                                                                                                                                                                 |
| `--map-dark`         | Map background (dark mode / night mode)       | Near-black; map SDK handles tile theming                                                                                                                                                     |

**Light / Dark:** Design both. The map is naturally dark-mode-friendly (satellite/dark tile
styles look better at night). The diary/feed sections should have a clean light default but
support dark.

---

### 2.2 Typography

One typeface family is enough. Use weight and size for hierarchy; avoid mixing families.

| Style        | Usage                               | Size / Weight                         |
| ------------ | ----------------------------------- | ------------------------------------- |
| `display`  | Hero place names on detail pages    | 28–32 / Bold                         |
| `title-lg` | Screen titles, place names in cards | 20–22 / SemiBold                     |
| `title-md` | Section headers, sheet titles       | 17–18 / SemiBold                     |
| `title-sm` | Card metadata labels                | 14 / SemiBold                         |
| `body`     | Captions, notes, diary text         | 15–16 / Regular                      |
| `body-sm`  | Secondary metadata, timestamps      | 13 / Regular                          |
| `label`    | Chips, buttons, kind badges         | 11–12 / SemiBold, uppercase tracking |
| `mono`     | Coordinates, IDs if shown           | System mono                           |

Line height: 1.4× for body, 1.2× for titles.
Minimum tap-target text: 44pt height, regardless of font size.

---

### 2.3 Spacing scale

8pt base grid. Every margin, padding, and gap is a multiple of 4 or 8.

`4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64`

Corner radii: `8` (chips, small cards) · `12` (input fields) · `16` (sheets, cards) · `24`
(large hero cards) · `full` (avatars, pills).

---

### 2.4 Elevation & shadow

Map is ground zero. Everything floating above the map uses elevation shadows.

| Level | Usage                                               |
| ----- | --------------------------------------------------- |
| 0     | Map surface                                         |
| 1     | Floating search bar, filter strip (4dp shadow)      |
| 2     | Bottom snap panel, place preview cards (8dp shadow) |
| 3     | Full modal sheets (16dp shadow + dim backdrop)      |

Avoid drop shadows in feed/timeline — those sections use background color to separate layers.

---

### 2.5 Iconography

Use a single icon set throughout (e.g. Material Symbols, rounded variant, or a custom set).
Do not mix outline and filled icons at the same hierarchy level.

Filled icon = active / selected state.
Outlined icon = inactive / unselected.

Custom icons needed for ZON-specific concepts:

- Stamp (a stylized postage stamp or wax seal)
- Check-in pin (distinct from Google Maps pin)
- Trail/breadcrumb
- Ghost mode

---

## 3. Navigation Architecture

### 3.1 Shell

5-tab bottom navigation with a center FAB.

```
[ Feed ]  [ Map ]  [ ⊕ ]  [ Timeline ]  [ Profile ]
```

- **Feed** — social content from people you follow
- **Map** — live map + discovery (the "explore" layer)
- **⊕** — primary creation action; expands to: Check in / Photo check-in / Create stamp
- **Timeline** — personal diary: your day, your route, your notes
- **Profile** — own profile; long-press or swipe → other user profiles

The center FAB should be visually prominent — it is the most important action in the app.
Consider a pill shape or oversized circle with a subtle brand-color glow.

### 3.2 Navigation patterns

| Pattern                   | When to use                                                          |
| ------------------------- | -------------------------------------------------------------------- |
| Bottom sheet (snap panel) | Quick detail view that doesn't break map context                     |
| Full-screen push          | Detail pages with rich content (stamp detail, profile, place detail) |
| Modal sheet               | Creation flows, editors, pickers                                     |
| In-place expand           | Inline editors on the timeline (do not push for a quick note edit)   |

Avoid nested push navigation deeper than 3 levels. Prefer bottom sheets over push for
contextual detail so the user never loses their map/timeline position.

---

## 4. Screens

---

### 4.1 Map Screen

**Purpose:** Live personal trace + social stamps + friend locations + **[MAP PLACEHOLDER] place discovery.**

#### Layout

```
┌─────────────────────────────────────┐
│  [MAP PLACEHOLDER] Search bar       │  ← Phase A; floating, rounded, elevation 1
│  [MAP PLACEHOLDER] Category chips   │  ← Phase B; horizontal scroll strip
├─────────────────────────────────────┤
│                                     │
│          Full-bleed map             │
│                                     │
│   • Own route line (brand color)    │
│   • Own check-in pins (blue)        │
│   • Own stamp pins (brand)          │
│   • Auto anchor dots (grey, tiny)   │
│   • Following stamps (orange)       │
│   • Following stories (pink)        │
│   • Friend location bubbles         │
│   • [MAP PLACEHOLDER] Hot places    │  ← Phase C; sized circles by score
│                                     │
│  [Ghost mode indicator — top right] │
├─────────────────────────────────────┤
│  Bottom snap panel                  │  ← collapsed: handle + summary
│  (my stats / [MAP PLACEHOLDER]      │  ← Phase E; expanded: nearby hot list
│   nearby hot list)                  │
└─────────────────────────────────────┘
```

#### Design considerations

**Map style:** Offer at least two tile styles — standard (clean vector) and satellite. Let
the user's system dark mode preference switch automatically to a dark vector tile style.

**Pin hierarchy:** The user's own pins always read above followed-user content, which reads
above hot-places discovery content. Use size and opacity to enforce this: own pins 100%
opacity, followed pins 80%, hot-places bubbles 60%.

**Friend location bubbles:** Avatar circle (user photo or initials) + small tooltip with
username + "Xm ago." Stale (≥8h) bubbles fade out entirely. Tapping opens `_FriendLocationSheet`.
Do not clutter — if many friends are at the same location, cluster them with a count badge.

**[MAP PLACEHOLDER] Search bar (Phase A):** Always visible at top. On tap, keyboard appears
and map dims slightly. Results appear as a distinct pin layer (not mixed with social content).
Recent searches shown before typing. Clear button to dismiss.

**[MAP PLACEHOLDER] Category filter (Phase B):** Horizontal chip strip immediately below the
search bar (collapses when map is panned). Categories: All · Cafe · Food · Culture · Outdoor
· Shopping. Active category highlights in brand color. Filter applies to hot-places layer and
the nearby list simultaneously.

**[MAP PLACEHOLDER] Hot places layer (Phase C):** Circle markers; radius ∝ `log(hot_score)`;
color-coded by category. They appear only when zoomed in enough (zoom ≥ 13). At lower zoom,
show density heatmap only. Tapping a hot-place circle opens a place preview card (see §4.6).

**[MAP PLACEHOLDER] Nearby list (Phase E):** Bottom snap panel, expanded state. Ranked list:
place name, category icon, distance, stamp count, "N friends been here" if applicable. Tapping
a list item flies the map to the place and opens the preview card.

**Time filter:** Applies to the following-stamps layer only (today/week/month/year/custom).
Move this into the bottom panel or a secondary control — it should not compete with the
category filter for visual priority.

---

### 4.2 Feed Screen

**Purpose:** Social content from followed users. Stamps as posts; public check-ins as stories.

#### Layout

```
┌─────────────────────────────────────┐
│  ZON          [search] [bell badge] │  ← AppBar
├─────────────────────────────────────┤
│  Stories rail                       │  ← horizontal avatars with gradient rings
├─────────────────────────────────────┤
│  Stamp card                         │
│  Stamp card                         │
│  Stamp card                         │
│  ...                                │
└─────────────────────────────────────┘
```

#### Stamp card design

The stamp card is the main content unit. Design it photo-first.

```
┌────────────────────────────┐
│                            │
│     Cover photo            │  ← 4:3 or 3:4 aspect; full-width; no rounded top corners
│     (full bleed)           │
│                            │
│  📍 Place name       time  │  ← overlay on bottom of photo (gradient scrim)
│  @username                 │
└────────────────────────────┘
│  Caption text              │  ← below photo, in card body
│  Vibe tags  ·  ·  ·        │
│  ♥ 12   💬 3   🔖          │  ← like, comment, save
└────────────────────────────┘
```

No card border radius on the photo (feels editorial). Radius only on the overall card container.
Vibe tags as small pills, not large chips.

#### Stories rail

Avatar circle + ring (gradient brand color = has unseen story; grey = seen).
Own story / check-in first. Tap → full-screen story viewer.
Story viewer: full-screen photo with place name + timestamp overlay, left/right tap to navigate,
top progress segments per check-in.

---

### 4.3 Timeline Screen

**Purpose:** Personal diary. One day at a time. Route + events + notes + AI diary.

#### Layout

```
┌─────────────────────────────────────┐
│  ‹ [Wed, Jun 7 ▼]              📅  │  ← date navigation
├─────────────────────────────────────┤
│                                     │
│     Day's route map                 │  ← Mapbox; route line + check-in pins
│     (upper ~40% of screen)          │
│                                     │
├─────────────────────────────────────┤
│  ══════ (drag handle)               │
│  Timeline list  (scrollable)        │
│    ● 10:30  Check-in · Cafe Bora    │
│    ★ 11:15  Stamp · Blue Bottle     │
│    ✎ 13:00  Note · "felt cozy..."   │
│    ● 15:40  Auto check-in           │
│    ...                              │
│  + Add a note                       │
│  ─────────────────────────────────  │
│  📖 Diary  [✨ Generate]   [Edit]   │
└─────────────────────────────────────┘
```

#### Design considerations

**Date header:** Shows day label ("Today", "Yesterday", "Wed Jun 7"). Arrow chevrons for
prev/next. Tap the date label → calendar picker. Never show a full week strip — it adds
visual noise for a single-day app. Calendar picker is sufficient.

**Map section:** This is a read-only mini-map. Route line in brand color. Check-in pins as
small dots (consistent with the pin system from the main map). Auto anchors as tiny grey dots.
Tapping a pin highlights the corresponding list item — and vice versa (list → map camera flies).

**Timeline list nodes:** Three visual types with distinct colors and icons:

- **Check-in** (blue) — pin icon; place name prominent; note and photos below
- **Stamp** (brand) — star/wax-seal icon; slight brand-color tint on the row
- **Note** (amber) — pencil/note icon; text body prominent; no place name
- **Auto** (grey) — smaller, less visual weight; same shape as check-in but muted

Node connector line runs through the left rail. This is the "spine" of the diary —
it should feel like a physical journal page.

**Diary section:** Always at the bottom of the scroll. Card with a subtle texture or
background that distinguishes it from the list. "Generate with AI" button (sparkle icon).
If diary is empty, show a soft prompt ("How was your day?"). If generated/written, show
the full text.

**Inline editing:** Long-press a node → it expands in place (no push navigation) with a text
field. This keeps the user in the diary context. Swipe left to delete.

---

### 4.4 Check-in Creation Flow

**Purpose:** Record a visit. Fast, location-aware, low friction.

#### Flow

```
Open from FAB
  ↓
Place search field (auto-focused, keyboard up)
  → Nearby suggestions immediately visible (no typing required)
  → Top option: "Use current location" with coordinate-resolved name
  → Typing filters suggestions (coordinate-weighted)
  ↓
Editor (place confirmed)
  → Note field (optional, multiline)
  → Photo strip (optional)
  → "Share as story" toggle (default off)
  ↓
Save → Check-in created
  → Offer "Make it a stamp?" card at the bottom (non-blocking)
```

#### Design considerations

**Place search is the first and most important step.** The search field should be
auto-focused and large. Suggestions appear in a floating card below (not a full-screen
overlay). The top result is always the coordinate-resolved nearby place.

**After saving:** Do not navigate away. Show a confirmation card that slides up from the
bottom with options: "View timeline", "Make a stamp", "Done." This preserves the user's
context — they might be mid-session and want to keep moving.

**Photo check-in path:** FAB → "Photo check-in" → photo picker → inspection screen
(swipeable nodes) → confirm all → timeline. This is a distinct flow from the real-time
check-in above.

---

### 4.5 Stamp Creation / Promotion

**Purpose:** Elevate a check-in into a shareable post.

#### Flow

```
From: check-in detail "Make a stamp" CTA
  OR: Timeline node "Promote"
  OR: FAB "Create stamp" (asks which check-in to promote)
  ↓
Stamp editor
  → Photo carousel (carry-over from check-in + option to add more)
  → Place name (pre-filled, editable with PlaceSearchField)
  → Caption (multiline, generous)
  → Vibe tags (multi-select chips)
  → Visibility toggle (Private / Public story)
  → Tag people
  ↓
Post
```

#### Design considerations

**Photos first.** Open the editor scrolled to the photo section. If no photos exist on the
check-in, show a large photo-add CTA as the first element.

**Caption:** Give it more vertical space than a typical note field — stamps are meant to have
more thoughtful text than check-in notes.

**Vibe tags:** Show all options as a wrap of chips. Selected = filled/brand-color; unselected
= outlined. Limit to 3 selected max to encourage precision over tag-stuffing.

---

### 4.6 Place Detail Page `[MAP PLACEHOLDER — Phase D]`

**Purpose:** A review page per real-world place, backed by ZON stamps.

#### Layout

```
┌─────────────────────────────────────┐
│  ‹                        [Check in]│
│  Photo header (from top stamp)      │
│  Place name                         │
│  Category · Distance                │
│  Address · Hours · Phone            │
├─────────────────────────────────────┤
│  ZON activity                       │
│  N stamps · M visitors · Last: 2d   │
│  [friend avatars who been here]     │
├─────────────────────────────────────┤
│  Photos grid (from public stamps)   │
├─────────────────────────────────────┤
│  Stamps from this place             │
│  [StampCard] [StampCard] …          │
└─────────────────────────────────────┘
```

Reserve this screen's route (`/place/:id`) and its entry points (map pin tap, hot-places
list item, check-in detail) now, even if the implementation is behind a feature flag or
empty state screen.

---

### 4.7 Profile Screen

**Purpose:** Personal portfolio of places visited; social graph.

#### Layout

```
┌─────────────────────────────────────┐
│  ‹   @username              [⋯ menu]│
│  [Avatar]  Stamps  Friends  Followers│  ← stat row
│  Display name                       │
│  Bio                                │
│  [Add Friend]  [Follow]             │  ← own profile: [Edit profile]
├─────────────────────────────────────┤
│  Stamp grid (3-col)                 │
│  □ □ □                              │
│  □ □ □                              │
└─────────────────────────────────────┘
```

#### Design considerations

**Avatar:** Large (88pt), circular, with a brand-color ring if the user has shared a recent
public check-in (mirrors the stories ring pattern).

**Stats:** Stamps / Friends / Followers. "Places visited" can be derived from check-in count
and added here when the places DB is ready. Tapping each stat opens the relevant list.

**Stamp grid:** Standard Instagram-style 3-column grid. Square cells, no gap or 1px gap.
Tapping opens the stamp detail. Private stamps (own profile only) shown with a small lock
overlay in the corner.

**Friends vs followers distinction:** Consider labeling the "Add Friend" button distinctly
from "Follow" to reinforce that they are different relationships — a small icon difference
(person+ vs person-check) is enough.

---

### 4.8 Settings Screen

**Purpose:** Account control. Not a dumping ground.

Sections:

1. **Profile** — Edit name, bio, avatar
2. **Privacy** — Private account toggle, Ghost mode toggle (live location), Location visibility (per-friend)
3. **Notifications** — Toggle types
4. **Account** — Sign out, Delete account

Ghost mode and location visibility live under Privacy, not under a separate "Location" section.
Keep settings shallow — max 2 levels deep.

---

### 4.9 Activity / Notifications Screen

**Purpose:** Stay informed without being overwhelmed.

Group by day. Each notification row: avatar + action text + timestamp + content thumbnail.
At the top: pending friend requests section (if any), then pending follow requests, then
chronological notifications.

Notification types to design rows for:

- Someone liked your stamp
- Someone commented
- Someone started following you / follow request
- Someone accepted your follow
- Friend request sent/accepted
- You were tagged in a stamp/check-in
- @mention in a comment

---

## 5. Component System

### 5.1 Bottom snap panel

Used on map (social layer) and map (nearby list — placeholder). Consistent pattern:

- **Collapsed:** 64pt high; handle (40×4pt pill) centered at top; one-line summary text
- **Mid-snap:** ~40% screen height; header row + scrollable content
- **Expanded:** 85% screen height; full list

The handle area is the only drag target. Content below is independently scrollable.

### 5.2 Place search dropdown

Used everywhere a place is being selected (check-in creation, stamp edit, photo inspection).
Consistent behavior regardless of context:

- Attached below the text field (not full-screen overlay)
- Top item: "Use coordinate" — always shown, auto-resolves nearby name
- Remaining: nearby or search results (max 5)
- Loading spinner inline (not blocking)

### 5.3 Pin system

All map pins use a consistent visual language:

| Type                                      | Shape          | Color          | Size     |
| ----------------------------------------- | -------------- | -------------- | -------- |
| Own check-in                              | Filled circle  | Blue           | 14pt     |
| Own stamp                                 | Teardrop / pin | Brand          | 16pt     |
| Auto anchor                               | Filled dot     | Grey           | 6pt      |
| Following stamp                           | Filled circle  | Orange         | 12pt     |
| Following story                           | Ring + dot     | Pink           | 12pt     |
| Friend location                           | Avatar circle  | —             | 32pt     |
| **[MAP PLACEHOLDER]** Search result | Outlined pin   | Neutral        | 14pt     |
| **[MAP PLACEHOLDER]** Hot place     | Sized circle   | Category color | 16–40pt |

Selected state: white ring + drop shadow on any pin type.

### 5.4 Kind chips

The small "Check-in / Stamp / Note / Auto" badges in the timeline list. Tiny pill shape,
color matches the node type, 11pt label. Used only in the timeline — not in feed or map.

### 5.5 Sheets and modals

All bottom sheets: rounded top corners (24pt radius), surface-2 background, handle at top.
All confirmations (delete, merge): `AlertDialog` with destructive action in red, cancel in
neutral. Never use a confirmation for non-destructive actions.

---

## 6. Motion & Animation

**Rule:** Animation aids understanding; it never shows off.

| Interaction         | Motion                                                                 |
| ------------------- | ---------------------------------------------------------------------- |
| Tab switch          | Cross-fade (150ms); never slide — tabs are not hierarchical           |
| Push navigation     | Standard slide right (300ms ease-out)                                  |
| Bottom sheet appear | Slide up + fade (250ms ease-out)                                       |
| Map camera fly      | 400–500ms ease-in-out; not instant                                    |
| Pin appear on map   | Scale from 0 → 1 with slight spring (spring stiffness = 200)          |
| Story progress bar  | Linear, matches media duration                                         |
| Like button         | Micro-bounce on tap (scale 1 → 1.3 → 1, 200ms)                       |
| FAB expand          | Reveal sub-options with staggered fade-up (80ms stagger between items) |
| Stamp card load     | Skeleton → fade in (not placeholder-pop)                              |

Do not animate list scroll, pagination loading, or simple visibility toggles unless there is a
clear spatial relationship to communicate.

---

## 7. Empty & Loading States

Every screen that fetches data needs three states:

**Loading:** Skeleton screens (not spinners) for content-heavy screens (feed, profile grid,
timeline). Spinner only for quick confirmations and creation actions.

**Empty:** Specific message + illustration + CTA. Never show "No data." Examples:

- Feed empty: "You're not following anyone yet. Find people to follow." → [Search people]
- Timeline empty day: "Nothing logged this day." On today: "Check in to start your trace." → [Check in]
- Profile stamps empty: "No stamps yet. Create your first." → [Check in]

**[MAP PLACEHOLDER] Hot places empty:** "Not enough ZON activity in this area yet. Be the
first to check in!" — shown when `place_stats` returns 0 results for the current viewport.

**Error:** Friendly message (not the raw error). Retry button. Never show exception class names.

---

## 8. Accessibility

- Minimum touch target: 44×44pt for all interactive elements
- Color is never the only differentiator (pin types use both color AND shape)
- All icons have tooltips / semantic labels
- Contrast: WCAG AA minimum (4.5:1 for body text, 3:1 for large/bold)
- Respect `reduceMotion` system setting — disable spring/bounce animations, keep simple fades
- Map accessibility: friend bubbles and pin layers must have semantic descriptions for
  screen readers (Mapbox accessibility API)
- Font scale: test all layouts at 1.5× system font size; avoid fixed-height text containers

---

## 9. Design Decisions Still Open

These need a designer's decision before implementation:

| Decision                                 | Options                                          | Recommendation                                                       |
| ---------------------------------------- | ------------------------------------------------ | -------------------------------------------------------------------- |
| Brand color                              | Teal, forest green, deep olive, warm coral       | Avoid pure blue and pure red (conflicts with map semantics)          |
| Map tile default                         | Standard vector, dark vector, satellite          | Standard by default; user-switchable                                 |
| Stamp card aspect ratio                  | 1:1, 4:3, 3:4, variable                          | Fixed 4:3 portrait simplest; variable (like Instagram) most flexible |
| Typography family                        | System (SF Pro / Roboto), custom                 | System is safest for first version; custom brand font later          |
| Stamp icon                               | Wax seal, postage stamp, star, custom            | Custom icon strongly recommended — it's the core metaphor           |
| Tab bar style                            | Standard labels, icons-only, floating pill       | Floating pill is distinctive; standard is safest for accessibility   |
| [MAP PLACEHOLDER] Hot place bubble style | Proportional circles, hexagons, numbered markers | Proportional circles are most map-native                             |
