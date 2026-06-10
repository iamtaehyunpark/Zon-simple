# ZON — Ultimate Flutter Redesign Prompt
> Hand this entire file to Claude Code CLI as a single task.
> Codebase: `zon-dev-v2/` · Design source: JSX prototype embedded below.

---

## MISSION

Translate the JSX prototype screens (embedded in full below) into Flutter, screen by screen.
**Keep all existing business logic, providers, repositories, and routing untouched.**
Replace ONLY the widget trees returned from each screen's `build()` method.

Read `zon-dev-v2/CLAUDE.md` first to understand the full architecture before touching any file.

---

## STEP 0 — Design Tokens (do this first, one file)

Create or replace `zon-dev-v2/lib/shared/theme/app_theme.dart` with these exact values:

```dart
import 'package:flutter/material.dart';

class ZonColors {
  // Brand
  static const brand       = Color(0xFF8B6EC4);
  static const brandDark   = Color(0xFF6B50A4);
  static const brandSoft   = Color(0x218B6EC4); // ~13% opacity
  static const brandSoft2  = Color(0x0F8B6EC4); // ~6% opacity

  // Semantic
  static const checkin     = Color(0xFF3B82F6);
  static const checkinSoft = Color(0x1F3B82F6);
  static const following   = Color(0xFFF59E0B);
  static const story       = Color(0xFFEC4899);
  static const note        = Color(0xFFD97706);
  static const noteSoft    = Color(0x1AD97706);
  static const auto        = Color(0xFF9CA3AF);
  static const error       = Color(0xFFEF4444);

  // Surfaces
  static const surface0    = Color(0xFFF7F4EE); // scaffold bg
  static const surface1    = Color(0xFFFFFFFF); // card bg
  static const surface2    = Color(0xFFF0EDE6); // sheet bg
  static const surface3    = Color(0xFFE8E4DC); // toggle off bg

  // Text
  static const textPrimary = Color(0xFF1A1714);
  static const textMuted   = Color(0xFF8A8278);
  static const textFaint   = Color(0xFFC0BAB2);

  // Borders
  static const outline     = Color(0xFFE8E4DC);
  static const outline2    = Color(0xFFC8C2BA);
}

class ZonRadii {
  static const r8   = BorderRadius.all(Radius.circular(8));
  static const r12  = BorderRadius.all(Radius.circular(12));
  static const r16  = BorderRadius.all(Radius.circular(16));
  static const r24  = BorderRadius.all(Radius.circular(24));
  static const r32  = BorderRadius.all(Radius.circular(32));
  static const full = BorderRadius.all(Radius.circular(9999));
}

class ZonType {
  static const display   = TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.2);
  static const titleLg   = TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.2);
  static const titleMd   = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2);
  static const titleSm   = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3);
  static const body      = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.55);
  static const bodySm    = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);
  static const label     = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5);
}

class AppTheme {
  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(seedColor: ZonColors.brand);
    return ThemeData(
      colorScheme: scheme.copyWith(
        primary:   ZonColors.brand,
        surface:   ZonColors.surface1,
        error:     ZonColors.error,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: ZonColors.surface0,
      appBarTheme: const AppBarTheme(
        centerTitle: false, elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: ZonColors.surface1,
        foregroundColor: ZonColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: ZonColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ZonColors.outline),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ZonColors.surface0,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ZonColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ZonColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ZonColors.brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ZonColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ZonColors.brand,
          side: const BorderSide(color: ZonColors.brand, width: 1.5),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ZonColors.surface2,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
        side: const BorderSide(color: ZonColors.outline),
      ),
      dividerTheme: const DividerThemeData(
        color: ZonColors.outline, thickness: 1, space: 0,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
```

Then in `app.dart`, replace `AppTheme.theme(kBrandGreen)` (or similar) with `AppTheme.theme()`.
Also change `initialLocation: '/feed'` → `initialLocation: '/map'`.

---

## JSX → Flutter Translation Rules

Apply these rules mechanically when reading each JSX screen below:

| JSX pattern | Flutter equivalent |
|---|---|
| `display:'flex', flexDirection:'column'` | `Column(children: [...])` |
| `display:'flex', flexDirection:'row'` (default) | `Row(children: [...])` |
| `gap: N` between flex children | `SizedBox(height/width: N)` or `Column/Row` with `gap:` if using Flutter 3.7+ |
| `flex: 1` on a child | Wrap child in `Expanded(child: ...)` |
| `flexShrink: 0` | `mainAxisSize: MainAxisSize.min` or just don't wrap in Expanded |
| `position:'absolute', inset:0` | `Positioned.fill(child: ...)` inside a `Stack` |
| `position:'absolute', top:X, left:Y` | `Positioned(top: X, left: Y, child: ...)` inside a `Stack` |
| `position:'relative'` | `Stack(children: [...])` |
| `overflowX:'auto'` | `SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(...))` |
| `overflowY:'auto'` | `SingleChildScrollView(child: Column(...))` or `ListView` |
| `background: '#RRGGBB'` | `color: Color(0xFFRRGGBB)` on Container/BoxDecoration |
| `rgba(r,g,b,a)` | `Color.fromRGBO(r, g, b, a)` |
| `borderRadius: N` | `BorderRadius.circular(N)` |
| `border: '1.5px solid #color'` | `Border.all(color: Color(0xFF...), width: 1.5)` |
| `boxShadow: '0 4px 16px rgba(0,0,0,0.1)'` | `BoxShadow(offset: Offset(0,4), blurRadius: 16, color: Color.fromRGBO(0,0,0,0.1))` |
| `fontWeight: 700` | `FontWeight.w700` |
| `fontSize: 14` | `fontSize: 14` |
| `lineHeight: 1.55` | `height: 1.55` in TextStyle |
| `fontStyle:'italic'` | `fontStyle: FontStyle.italic` |
| `letterSpacing: '0.05em'` | `letterSpacing: 0.7` (approx, for 14px font) |
| `textTransform:'uppercase'` | `.toUpperCase()` on string |
| `color: T.brand` | `color: ZonColors.brand` |
| `color: T.textMuted` | `color: ZonColors.textMuted` |
| `color: T.outline` | `color: ZonColors.outline` |
| `background: T.surface1` | `color: ZonColors.surface1` |
| `background: T.brandSoft` | `color: ZonColors.brandSoft` |
| `onClick / onTap` | `onTap:` on `GestureDetector` or `InkWell` |
| `cursor:'pointer'` | wrap in `InkWell` or `GestureDetector` |
| `display:grid, gridTemplateColumns: repeat(3,1fr), gap:2` | `GridView.count(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2, ...)` |
| `useState(x)` (local UI state) | `StatefulWidget` with `setState` or `useState` from flutter_hooks |
| `useRef` | `late` field in State class |
| `useEffect(() => ..., [])` | `initState()` |
| `window.addEventListener(...)` | `WidgetsBinding.instance.addPostFrameCallback` or direct listener |
| `animation: 'slideUp 0.22s'` | `AnimatedContainer` or `SlideTransition` |
| `transition: 'all 0.15s'` | `AnimatedContainer(duration: Duration(milliseconds: 150))` |
| `img placeholder (ImgPlaceholder)` | `CachedNetworkImage` (keep existing) or `Container(color: ...)` with aspect ratio |
| `Avatar` component | `CircleAvatar` with `backgroundImage` or initials fallback |
| `BottomHandle` | `Center(child: Container(width:40, height:4, decoration: BoxDecoration(color: ZonColors.outline2, borderRadius: BorderRadius.circular(2))))` |
| `Divider` | `const Divider(height: 1, thickness: 1)` |
| `Material Symbols icon name` | `Icons.location_on`, `Icons.favorite`, `Icons.bookmark`, etc. (map by name) |

**Icon name mapping** (JSX Material Symbols → Flutter Icons):
- `location_on` → `Icons.location_on`
- `favorite` → `Icons.favorite` / `Icons.favorite_border`
- `bookmark` → `Icons.bookmark` / `Icons.bookmark_border`
- `chat_bubble_outline` → `Icons.chat_bubble_outline`
- `search` → `Icons.search`
- `notifications` → `Icons.notifications`
- `person` → `Icons.person`
- `settings` → `Icons.settings`
- `more_vert` → `Icons.more_vert`
- `arrow_back` → `Icons.arrow_back`
- `chevron_left` → `Icons.chevron_left`
- `chevron_right` → `Icons.chevron_right`
- `expand_more` → `Icons.expand_more`
- `calendar_month` → `Icons.calendar_month`
- `add` → `Icons.add`
- `close` → `Icons.close`
- `visibility_off` → `Icons.visibility_off`
- `auto_awesome` → `Icons.auto_awesome`
- `menu_book` → `Icons.menu_book`
- `my_location` → `Icons.my_location`
- `edit_note` → `Icons.edit_note`
- `workspace_premium` → `Icons.workspace_premium`
- `radio_button_unchecked` → `Icons.radio_button_unchecked`
- `lock` → `Icons.lock`
- `public` → `Icons.public`
- `logout` → `Icons.logout`
- `delete` → `Icons.delete`
- `people` → `Icons.people`
- `person_add` → `Icons.person_add`
- `check_circle` → `Icons.check_circle`
- `add_photo_alternate` → `Icons.add_photo_alternate`
- `photo_camera` → `Icons.photo_camera`
- `timeline` → `Icons.timeline`
- `article` → `Icons.article`
- `map` → `Icons.map`

---

## TASK 1 — Feed Screen
**File:** `lib/features/feed/presentation/feed_screen.dart`
**Keep:** All `ref.watch(...)` calls, `feedNotifierProvider`, `feedStoriesProvider`, `context.push(...)` routing, `_PhotoSuggestionBanner`, `_StoryView` dialog logic.
**Replace:** The widget tree structure to match this JSX:

```jsx
// FEED SCREEN JSX SOURCE
// AppBar: "ZON" title (fontWeight:900, letterSpacing:1.5) + search icon + bell icon with red dot badge
// Filter tabs: ['Following', 'Nearby', 'Trending'] — underline style, brand color when active
// Stories rail: horizontal scroll, 76px wide items, 54px avatar with gradient ring, username below
// Stamp cards: see StampCard JSX below — photo-first, 222px image, gradient scrim, place+user overlay

// FeedScreen
<div style={{ background:T.surface0, display:'flex', flexDirection:'column' }}>
  <div style={{ background:T.surface1 }}>
    {/* AppBar */}
    <div style={{ padding:'0 6px 0 16px', display:'flex', justifyContent:'space-between', alignItems:'center', height:48 }}>
      <span style={{ fontSize:24, fontWeight:900, letterSpacing:1.5 }}>ZON</span>
      <div style={{ display:'flex' }}>
        <button /* search → context.push('/search') */ />
        <button /* bell → context.push('/activity'), show red dot if unread */ />
      </div>
    </div>
    {/* Filter tabs */}
    <div style={{ display:'flex', borderBottom:`1px solid ${T.outline}` }}>
      {['Following','Nearby','Trending'].map(t => (
        <button style={{ flex:1, padding:'10px 0', fontSize:14, fontWeight: active?700:400,
          color: active?T.brand:T.textMuted, borderBottom: active?`2.5px solid ${T.brand}`:'2.5px solid transparent' }}>{t}</button>
      ))}
    </div>
  </div>
  {/* Scrollable body */}
  <div style={{ flex:1, overflowY:'auto', paddingBottom:83 }}>
    {/* Stories rail */}
    <div style={{ borderBottom:`1px solid ${T.outline}`, padding:'10px 4px 12px', display:'flex', overflowX:'auto' }}>
      {stories.map(s => (
        <button style={{ width:76, display:'flex', flexDirection:'column', alignItems:'center', gap:5 }}>
          {/* Avatar 54px with gradient ring (brand→story) if hasStory */}
          {/* Username below, 11px */}
        </button>
      ))}
    </div>
    {/* Stamp cards */}
    <div style={{ padding:'14px 14px 0' }}>
      {stamps.map(s => <StampCard stamp={s}/>)}
    </div>
  </div>
</div>

// StampCard JSX
<div style={{ background:T.surface1, borderRadius:16, overflow:'hidden', marginBottom:12, border:`1px solid ${T.outline}` }}>
  {/* Photo area — Stack */}
  <div style={{ position:'relative' }}>
    <img height={222} width="100%" style={{ objectFit:'cover' }}/>
    {/* Gradient scrim: bottom 88px, transparent→rgba(20,16,12,0.62) */}
    <div style={{ position:'absolute', bottom:0, left:0, right:0, height:88, background:'linear-gradient(transparent,rgba(20,16,12,0.62))' }}/>
    {/* Place + user overlay — bottom:10, left:13, right:13 */}
    <div style={{ position:'absolute', bottom:10, left:13, right:13, display:'flex', justifyContent:'space-between', alignItems:'flex-end' }}>
      <div>
        <div style={{ display:'flex', alignItems:'center', gap:5, marginBottom:2 }}>
          {/* location_on icon, 14px, white */}
          <span style={{ fontSize:14, fontWeight:700, color:'white' }}>{place}</span>
        </div>
        <span style={{ fontSize:12, color:'rgba(255,255,255,0.78)' }}>@{user}</span>
      </div>
      <span style={{ fontSize:11, color:'rgba(255,255,255,0.65)' }}>{time}</span>
    </div>
  </div>
  {/* Card body — padding:12 14 14 */}
  <div>
    {/* caption: italic, fontSize:14, lineHeight:1.58, marginBottom:10 */}
    {/* tags: brand color pills, fontSize:11, fontWeight:600, brandSoft bg, padding:2px 10px */}
    {/* actions row: like (fills red when liked) + count, comment + count, bookmark (fills brand when saved) */}
  </div>
</div>
```

**Specific Flutter notes for Feed:**
- The 3 filter tabs are LOCAL state (`_selectedTab`), not backed by different providers yet (Following uses existing feed, Nearby/Trending can show same data with a placeholder "coming soon" state for now)
- The stories rail already exists as `_StoriesRail` — just restyle it: 54px `CircleAvatar`, gradient border ring via `Container` with gradient + inner `CircleAvatar`, 76px wide column
- `StampCard` in the feed: replace with the photo-first card above. The image area uses `CachedNetworkImage` (keep). The actions row keeps all existing `toggleLike` / `toggleSave` logic.

---

## TASK 2 — Map Screen
**File:** `lib/features/map/presentation/map_screen.dart`
**Keep:** ALL `MapboxMap` widget, all pin layers, `GpsNotifier`, location broadcast logic, `_FriendLocationSheet`, all data loading methods.
**Replace:** The overall screen layout — specifically, replace the static `Column` below the map with a `DraggableScrollableSheet`.

```jsx
// MAP SCREEN LAYOUT JSX
<div style={{ position:'relative', overflow:'hidden' }}>
  {/* HEADER: fixed at top, zIndex 20, background surface1, shadow */}
  <div style={{ position:'relative', zIndex:20, background:T.surface1, boxShadow:'0 2px 8px rgba(0,0,0,0.06)' }}>
    {/* Search bar: rounded pill, height:44, border outline, search icon left */}
    <SearchBar placeholder="Search places…"/>
    {/* Category chips: horizontal scroll — ['All','☕ Café','🍴 Food','🌿 Nature','🎨 Art','🏬 Retail'] */}
    {/* Active chip: brand bg, white text. Inactive: surface1, outline border */}
    <div style={{ display:'flex', gap:7, overflowX:'auto' }}>
      {cats.map(c => <Pill active={selected===c}>{c}</Pill>)}
    </div>
  </div>

  {/* FULL-BLEED MAP: position absolute, top=headerHeight, bottom=0 */}
  {/* MapboxMap fills this area — keep existing */}
  {/* Ghost mode toggle button: top-right, 36px circle */}
  {/* Summary pill: position absolute, bottom = sheetHeight + 12, centered */}
  {/* 📍 3 stamps  ·  3.8 km today */}
  {/* Map legend: bottom-left, small, surface1 bg with border-radius */}

  {/* DRAGGABLE BOTTOM SHEET: position absolute, bottom=navBarHeight */}
  {/* Snap: COLLAPSED=196dp, EXPANDED=390dp */}
  {/* borderRadius: 24 24 0 0, surface1 bg, shadow top */}
  <DraggableScrollableSheet>
    {/* Drag handle: 40×4px centered pill, outline2 color */}
    {/* Filter chips: ['Today','Week','Month','All time','Saved'] — same pill style */}
    {/* "Nearby" section header + "See all →" button */}
    {/* Horizontal scroll of NearbyCards */}
    {/* When expanded: "Trending nearby" list with name/category/distance/score */}
  </DraggableScrollableSheet>
</div>
```

**Flutter implementation for the bottom sheet:**
```dart
// Replace the static bottom panel with:
DraggableScrollableSheet(
  initialChildSize: 0.26,  // ~196/844 * 2 ≈ collapsed
  minChildSize: 0.17,
  maxChildSize: 0.52,       // ~390/844 * 2 ≈ expanded
  snap: true,
  snapSizes: const [0.26, 0.52],
  builder: (context, scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: ZonColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(offset: Offset(0,-4), blurRadius: 20, color: Color.fromRGBO(0,0,0,0.10))],
      ),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // drag handle
          // filter chips row (Today/Week/Month/All time/Saved)
          // nearby cards horizontal list
          // trending list (shows when expanded)
        ],
      ),
    );
  },
)
```

**NearbyCard widget** (new, add to map_screen.dart or shared/widgets/):
```dart
// Card: border outline, borderRadius 14, padding 10/12, surface1
// Row layout: large emoji (24px), then Column(place name w700 13px, "N stamps · Xm" muted 11px)
// min-width: 128, tappable → context.push('/place/${place.id}') (route placeholder)
```

---

## TASK 3 — Timeline Screen
**File:** `lib/features/timeline/presentation/timeline_screen.dart`
**Keep:** All `_day`, `_items`, `_diary`, `_sheetController`, `DraggableScrollableSheet`, `DayRouteMap`, `DiaryRepository.generateDiary()`, `CheckInRepository`, all data loading.
**Replace:** Visual layer only.

```jsx
// TIMELINE SCREEN LAYOUT JSX

// DATE HEADER (AppBar area):
<div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', padding:'4px 16px 8px' }}>
  <button /* chevron_left — previous day *//>
  <button style={{ fontSize:17, fontWeight:700, display:'flex', alignItems:'center', gap:5 }}>
    Today {/* or "Jun 6" etc */}
    {/* expand_more icon */}
  </button>
  <button /* calendar_month icon — calendar picker *//>
</div>

// WEEK STRIP — 7 day buttons:
<div style={{ display:'flex', gap:3, padding:'0 12px 12px' }}>
  {['S','M','T','W','T','F','S'].map((d, i) => (
    <button style={{
      flex:1, display:'flex', flexDirection:'column', alignItems:'center',
      gap:3, padding:'7px 2px 6px', borderRadius:12,
      background: isSelected ? T.brand : 'none'
    }}>
      <span style={{ fontSize:10, fontWeight:600, color: isSelected?'rgba(255,255,255,0.8)':T.textMuted }}>{d}</span>
      <span style={{ fontSize:15, fontWeight: isSelected?700:400, color: isSelected?'white':T.text }}>{date}</span>
      {/* 4px dot below date if hasActivity and not selected (brand color, 65% opacity) */}
    </button>
  ))}
</div>

// MINI ROUTE MAP (inside a Card with borderRadius:16):
// MapboxMap or DayRouteMap — keep existing, just add border/radius container
// Below the map: "Jun 6 · 3.8 km" (muted) + "3 stamps" (brand, bold) in a row

// TIMELINE NODES — for each _TlItem:
<div style={{ display:'flex', gap:0 }}>
  {/* LEFT RAIL — width:52 */}
  <div style={{ width:52, display:'flex', flexDirection:'column', alignItems:'center' }}>
    {/* Node circle: 28px, borderRadius:14, soft bg + 2px border in node color */}
    {/* Icon inside: 14px, filled, node color */}
    {/* Connector line: 2px wide, outline color, flex:1 (not on last item) */}
  </div>
  {/* CONTENT — flex:1 */}
  <div style={{ flex:1, paddingTop:12, paddingRight:16, paddingBottom:16 }}>
    {/* Row: time (12px muted) + KindChip */}
    {/* Place name: 15px w700 (if not note) */}
    {/* Text: 14px, italic+amber if note, muted if checkin */}
    {/* Photo thumbs: 60×60px, borderRadius:8, gap:6 */}
    {/* "Promote to stamp →" button: brandSoft bg, brand text, pill, 12px — only on non-auto checkins */}
  </div>
</div>

// KindChip values:
// checkin → blue bg, "Check-in", location_on icon
// stamp   → brandSoft bg, brand color, "Stamp", workspace_premium icon
// note    → amber soft bg, amber color, "Note", edit_note icon
// auto    → grey soft bg, grey color, "Auto", radio_button_unchecked icon

// ADD NOTE button (dashed border, full width):
<button style={{ border:`1.5px dashed ${T.outline2}`, borderRadius:12, padding:'10px 14px', width:'100%' }}>
  {/* add icon + "Add a note" */}
</button>

// DIARY CARD (at bottom of scroll):
<div style={{ background:T.surface1, borderRadius:16, border:`1px solid ${T.outline}` }}>
  {/* Header: menu_book icon (brand) + "Diary" title + "Edit" button + "Generate" button */}
  {/* Generate button: brand bg, white, auto_awesome icon, "Generate" / "Writing…" / "Generated" */}
  {/* Body: italic diary text, or placeholder "How was your day?" in textFaint */}
  {/* Loading state: 4 skeleton lines (100%/88%/72%/55% widths) */}
</div>
```

---

## TASK 4 — Profile Screen
**File:** `lib/features/profile/presentation/profile_screen.dart`
**Keep:** All `profileStampsNotifier`, `currentUserProvider`, `ProfileRepository` calls, avatar upload, existing navigation.
**Replace:** The widget tree to match this design:

```jsx
// PROFILE SCREEN JSX

// APPBAR:
<div style={{ padding:'2px 8px 2px 16px', display:'flex', alignItems:'center', minHeight:44 }}>
  {/* Back button if not own profile */}
  <span style={{ flex:1, fontSize:15, fontWeight:700 }}>@username</span>
  {/* settings icon (own) or more_vert (other) */}
</div>

// IDENTITY ROW (the most important change — NOT Instagram layout):
<div style={{ padding:'16px 18px', display:'flex', alignItems:'center', gap:14, borderBottom:`1px solid ${T.outline}` }}>
  {/* CircleAvatar: 58px — NO gradient ring on this screen */}
  <div style={{ flex:1 }}>
    <div style={{ fontSize:18, fontWeight:700 }}>Display Name</div>
    <div style={{ fontSize:13, color:T.textMuted }}>Seoul, Korea</div>
  </div>
  {/* Own profile: "Edit" outlined button, borderRadius:8, padding:6 16 */}
  {/* Other profile: "+ Friend" (brand filled pill) + "Follow" (outlined pill) */}
</div>

// STATS ROW — 3 stats only: Stamps · Places · Friends
// (NOT followers/following — keep those numbers internally but don't show here)
<div style={{ display:'flex', borderBottom:`1px solid ${T.outline}`, padding:'14px 0' }}>
  {[['34','Stamps'],['12','Places'],['8','Friends']].map(([n,l], i) => (
    <div style={{ flex:1, textAlign:'center', borderRight: i<2 ? `1px solid ${T.outline}` : 'none' }}>
      <div style={{ fontSize:22, fontWeight:800, color:T.brand }}>{n}</div>
      <div style={{ fontSize:12, color:T.textMuted }}>{l}</div>
    </div>
  ))}
</div>

// TAB BAR — text only, no icons: Stamps | Saved | Diaries
<div style={{ display:'flex', borderBottom:`1px solid ${T.outline}` }}>
  {['Stamps','Saved','Diaries'].map(label => (
    <button style={{ flex:1, padding:'10px 0', fontSize:14,
      fontWeight: active?700:400, color: active?T.brand:T.textMuted,
      borderBottom: active?`2.5px solid ${T.brand}`:'2.5px solid transparent' }}>{label}</button>
  ))}
</div>

// CONTENT:
// Stamps/Saved → 3-column GridView, 126px height cells, gap:2, no padding
//   Private stamps: small lock icon overlay (top-right, 18px circle, rgba(0,0,0,0.45) bg)
// Diaries → ListView of diary entries, each:
//   date label: 11px brand color uppercase w700, marginBottom:8
//   text: 14px italic, lineHeight:1.72
//   padding:18px 20px, borderBottom outline
```

**Flutter-specific notes:**
- For "Diaries" tab: query `TimelineNoteRepository` (or diary repo) with `isDiary: true`, filtered by user
- For Stamps/Saved: keep existing `profileStampsNotifier`
- The 3 stat numbers must come from real profile data

---

## TASK 5 — Check-in Flow (CheckinEntry)
**File:** `lib/features/checkin/presentation/checkin_entry.dart`
**Keep:** All place search logic, `PlaceSearchField`, GPS resolution, photo upload, `CheckInRepository.createCheckIn()`, `promoteToStamp()`.
**Replace:** Present as a bottom sheet modal (not a full-screen push).

```jsx
// CHECK-IN SHEET — 3 steps: search → editor → confirm

// STEP 1: SEARCH
<div style={{ background:T.surface1, borderRadius:'24px 24px 0 0', maxHeight:'72vh' }}>
  {/* Drag handle */}
  {/* "Add a Check-in" title + close X */}
  {/* PlaceSearchField — large, auto-focused */}
  {/* "Use current location" CTA: dashed brand border, my_location icon in brand circle */}
  {/* Nearby list: emoji + place name + distance, chevron_right */}
</div>

// STEP 2: EDITOR (place selected)
{/* Back button + selected place name */}
{/* Note textarea: surface0 bg, outline border, 80px min height */}
{/* Photos strip: 72×72 add button with dashed outline2 border */}
{/* "Share as story" toggle row: 48×28 pill toggle */}
{/* "Save Check-in" button: full width, 50px, brand bg, borderRadius:16 */}

// STEP 3: CONFIRM
{/* Centered: brand circle with check_circle icon */}
{/* "Checked in!" title + place name */}
{/* 3 buttons: "Make it a stamp →" (brand), "View in Timeline" (outlined), "Done" (text) */}
```

---

## TASK 6 — Activity Screen
**File:** `lib/features/profile/presentation/activity_screen.dart`
**Keep:** All `NotificationRepository`, notification data fetching.
**Replace:** Visual layout.

```jsx
// Each notification row:
<div style={{ display:'flex', gap:12, padding:'12px 16px', borderBottom:`1px solid ${T.outline}` }}>
  {/* CircleAvatar 40px with initials */}
  <div style={{ flex:1 }}>
    <div style={{ fontSize:14, lineHeight:1.5 }}>
      <span style={{ fontWeight:700 }}>@user</span> action text
    </div>
    <div style={{ fontSize:12, color:T.textMuted }}>time</div>
    {/* If friend request: Accept (brand) + Decline (outlined) buttons */}
  </div>
  {/* Right: 44×44 thumbnail if applicable */}
</div>

// Sections: "Friend Requests" uppercase label → then requests
// "Today" uppercase label → then rest
// Section labels: 12px w700 textMuted uppercase letterSpacing 0.06em
```

---

## TASK 7 — Settings Screen
**File:** `lib/features/profile/presentation/settings_screen.dart`
**Keep:** All toggle state, `PrivacyRepository`, `deleteAccount()`, navigation.
**Replace:** Layout.

```jsx
// Each section: section title (12px uppercase muted) then a Card of rows
// Each row: 34×34 rounded-10 icon box (brandSoft bg, brand icon) + label + subtitle (optional) + toggle OR chevron
// Destructive rows (Sign out, Delete): red icon box, red label
// Toggle: 48×28 pill, brand when on / surface3 when off, white circle slides
// Sections: Profile · Privacy · Notifications · Account
// Privacy section must include: Private account toggle, Ghost mode toggle + sub "Hide your live location", Location visibility row → /location-visibility
```

---

## TASK 8 — Stamp Detail Screen
**File:** `lib/features/feed/presentation/stamp_detail_screen.dart`
**Keep:** All like/save/comment logic, `stampDetailProvider`, `commentListProvider`.
**Replace:** Layout.

```jsx
// Hero area: full-width CachedNetworkImage, 340px, gradient scrim (transparent 50% → rgba dark 70%)
// Overlay: back button (dark circle) top-left, more_vert top-right
// Bottom of hero: avatar(30px) + @username + time | location_on icon + place name (18px w700 white)
// Body (scrollable):
//   caption: italic 15px, lineHeight:1.65
//   tags: brand pills, 12px w600
//   actions: like + count, comment + count, bookmark (right-aligned)
// Comments section header
// Comment rows: avatar(34px) + bubble (surface1 bg, outline border, borderRadius:12)
// Comment input: avatar(34px) + pill input box
```

---

## EXECUTION ORDER

Run these tasks in order. After each task, run `flutter analyze` — fix any errors before moving on.

1. `app_theme.dart` → design tokens
2. `app.dart` → initialLocation + theme call
3. `feed_screen.dart` → StampCard + StoriesRail + filter tabs
4. `map_screen.dart` → DraggableScrollableSheet + search bar
5. `timeline_screen.dart` → week strip + node visual
6. `profile_screen.dart` → identity row + 3 stats + text tabs + diaries
7. `activity_screen.dart` → notification rows
8. `settings_screen.dart` → section rows + toggles
9. `stamp_detail_screen.dart` → hero + actions + comments
10. `checkin_entry.dart` → bottom sheet layout

After all tasks: run `flutter analyze` + `flutter test` to confirm 0 issues.

---

## CONSTRAINTS

- Do NOT change any `Repository`, `Provider`, `Notifier`, or database/Supabase call
- Do NOT change any GoRouter route definitions
- Do NOT change any data model (`.dart` files in `lib/data/`)
- Do NOT remove any existing feature functionality
- Every interactive element must have a minimum tap target of 44×44dp
- All new `Container` widgets holding text must NOT use fixed heights that clip text at 1.5× font scale
- Use `const` constructors wherever possible

---

*Source prototype: `Zon Prototype.html` (open in browser to verify visual output)*
*Design system reference: `zon-dev-v2/docs/design-guide.md`*
