# ZON

A place-based diary SNS. ZON passively collects location (foreground GPS, photo EXIF,
significant-change cell tower) and lets you turn moments into **Stamps** — cards with
photos, text, and tags that stay private by default and can be shared to a feed.

See [`CLAUDE.md`](CLAUDE.md) for the full architecture, data model, and rules.

## Stack

Flutter · Riverpod · go_router · Supabase (Postgres/Auth/Storage/Edge Functions) ·
Mapbox · Hive · Firebase Messaging.

- **Auth:** Supabase OAuth (Apple/Google) via `flutter_web_auth_2` (native in-app
  ASWebAuthenticationSession).
- **Place search:** Kakao Local API in Korea, Google Places worldwide
  (`lib/core/places/place_service_provider.dart`).

## Setup

```bash
flutter pub get
cp .env.example .env   # then fill in the keys
dart run build_runner build --delete-conflicting-outputs
flutter run
```

`.env` keys are documented in [`.env.example`](.env.example); dependency rationale lives
in [`docs/dependencies.md`](docs/dependencies.md).

## Develop

```bash
flutter analyze
flutter test
```
