# ZON — Initial Setup Prompt for Claude Code

Paste this entire prompt to Claude Code CLI to bootstrap the project from scratch.

---

You are setting up the ZON Flutter project from scratch. The project root already contains the development package:

```
/CLAUDE.md
/docs/schema.sql
/docs/api.md
/docs/flutter-structure.md
/docs/m0-checklist.md
/docs/permissions.md
```

**Read CLAUDE.md fully before doing anything else.** It is the source of truth for all architectural decisions, tech stack, and rules.

Then complete the following tasks in order. Do not skip steps. Do not move to the next step until the current one is verified.

---

## TASK 1 — Create Flutter Project

```bash
flutter create . --org app.getzon --platforms ios,android --project-name zon
```

If the directory is not empty, use:
```bash
flutter create --org app.getzon --platforms ios,android --project-name zon .
```

Verify: `flutter run` launches on iOS simulator without errors.

---

## TASK 2 — pubspec.yaml

Replace the contents of `pubspec.yaml` with the dependencies listed in `docs/flutter-structure.md` under "pubspec.yaml Dependencies".

Then run:
```bash
flutter pub get
```

Verify: no dependency conflicts. All packages resolve.

---

## TASK 3 — Folder Structure

Create the exact folder structure defined in `CLAUDE.md §4`. Create placeholder `README.md` or `.gitkeep` files in empty directories so they are tracked by git.

Key directories to create:
```
lib/core/location/
lib/core/photos/
lib/core/notifications/
lib/core/auth/
lib/core/errors/
lib/data/models/
lib/data/repositories/
lib/data/datasources/remote/
lib/data/datasources/local/
lib/features/feed/data/
lib/features/feed/domain/
lib/features/feed/presentation/providers/
lib/features/map/presentation/
lib/features/checkin/presentation/providers/
lib/features/photo_import/presentation/providers/
lib/features/timeline/presentation/
lib/features/profile/presentation/
lib/shared/widgets/
lib/shared/theme/
lib/shared/utils/
supabase/migrations/
supabase/functions/ingest-location/
supabase/functions/ingest-photo-exif/
supabase/functions/suggest-stamp/
supabase/functions/match-place/
test/unit/
test/widget/
test/integration/
```

---

## TASK 4 — Environment Setup

Create `.env.example`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
MAPBOX_TOKEN=pk.your-mapbox-token
KAKAO_REST_API_KEY=your-kakao-rest-api-key
GOOGLE_PLACES_API_KEY=your-google-places-key
```
(FCM uses a Firebase service account on the server, not a client key.)

Create `.env` (with actual values if available, otherwise copy .env.example).

Add to `.gitignore`:
```
.env
*.env
!.env.example
```

---

## TASK 5 — Freezed Data Models

Create the following Freezed data models in `lib/data/models/`.
Use the exact field definitions from `CLAUDE.md §7`.

Files to create:
- `lib/data/models/enums.dart` — `LocationSource`, `StampVisibility`
- `lib/data/models/raw_location_event.dart` — `RawLocationEvent`
- `lib/data/models/stamp.dart` — `Stamp`, `StampDraft`
- `lib/data/models/photo.dart` — `Photo`
- `lib/data/models/user_profile.dart` — `UserProfile`

After creating all model files, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Verify: all `.freezed.dart` and `.g.dart` files generated without errors.

---

## TASK 6 — app.dart + go_router

Create `lib/app.dart` with:
- `MaterialApp.router` setup
- All routes from `docs/flutter-structure.md` under "Navigation (go_router)"
- `MainShell` widget with 5-tab bottom bar (feed / map / checkin CTA / timeline / profile)
- Center FAB button for checkin CTA tab

Create stub screen widgets for all 5 tabs (just `Scaffold` with centered tab name text):
- `lib/features/feed/presentation/feed_screen.dart`
- `lib/features/map/presentation/map_screen.dart`
- `lib/features/checkin/presentation/checkin_entry.dart`
- `lib/features/timeline/presentation/timeline_screen.dart`
- `lib/features/profile/presentation/profile_screen.dart`

Create `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const ProviderScope(child: ZonApp()));
}
```

Verify: `flutter run` shows 5-tab navigation working on iOS simulator.

---

## TASK 7 — Riverpod Provider Skeletons

Create skeleton providers (no business logic yet, just state types and empty implementations) for:

- `lib/features/feed/presentation/providers/feed_provider.dart`
- `lib/features/map/presentation/providers/map_provider.dart`
- `lib/features/checkin/presentation/providers/checkin_provider.dart` — include `CheckinState` sealed class from `docs/flutter-structure.md`
- `lib/features/timeline/presentation/providers/timeline_provider.dart`
- `lib/features/profile/presentation/providers/profile_provider.dart`
- `lib/core/location/providers/gps_provider.dart` — include `GpsNotifier` and `LocationBatcher` skeletons from `docs/flutter-structure.md`

Run build_runner again after adding providers:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## TASK 8 — GitHub Actions CI

Create `.github/workflows/ci.yml`:
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  analyze-and-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.0'
          channel: 'stable'
      - name: Install dependencies
        run: flutter pub get
      - name: Analyze
        run: flutter analyze
      - name: Test
        run: flutter test
```

---

## TASK 9 — Core Service Skeletons

Create skeleton implementations (empty methods with TODO comments) for:

**`lib/core/auth/auth_service.dart`**
```dart
// Supabase auth: signInWithApple(), signInWithGoogle(), signOut(), currentUser
```

**`lib/core/location/gps_service.dart`**
```dart
// startTracking(), stopTracking(), currentPosition()
// See CLAUDE.md §6.1 for rules
```

**`lib/core/location/significant_change.dart`**
```dart
// initialize(), onSignificantChange()
// See CLAUDE.md §6.2 for rules
```

**`lib/core/photos/photo_service.dart`**
```dart
// checkForNewPhotos(), processAsset()
// See CLAUDE.md §6.3 for rules
// See docs/flutter-structure.md "Photo Manager Integration" for implementation
```

**`lib/core/notifications/notification_service.dart`**
```dart
// initialize(), sendLocalNotification(), requestPermission()
```

**`lib/core/errors/app_exception.dart`**
```dart
// AppException sealed class: NetworkError, AuthError, LocationError, PhotoError, NotFoundError
```

---

## TASK 10 — Final Verification

Run all checks:

```bash
flutter analyze
# Expected: 0 issues

flutter test
# Expected: all tests pass (only generated tests at this point)

flutter build ios --no-codesign
# Expected: builds successfully
```

Check the following manually:
- [ ] All 5 tabs navigable
- [ ] No red screens or missing widget errors
- [ ] `flutter analyze` → 0 issues
- [ ] No `.env` file in git staging (`git status` should not show `.env`)
- [ ] All folders from CLAUDE.md §4 exist

---

## What NOT to Do

- Do NOT implement Supabase queries yet (that's M1)
- Do NOT implement location tracking logic yet (verify first in M0 W2)
- Do NOT implement photo EXIF parsing yet (verify first in M0 W2)
- Do NOT add any AI/ML dependencies (tflite_flutter, onnxruntime) — see CLAUDE.md §2
- Do NOT request "Always Allow" location permission anywhere in the code

---

## Done

When all 10 tasks are complete, report:
1. Flutter version used
2. Total generated files from build_runner
3. Any dependencies that failed to resolve and how they were handled
4. Result of `flutter analyze`
5. Confirmation that 5-tab navigation works on simulator

Then proceed to M0 Week 2 tasks from `docs/m0-checklist.md`.
