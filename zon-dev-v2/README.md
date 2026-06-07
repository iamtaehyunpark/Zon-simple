# ZON

A place-based diary SNS. ZON passively collects location (foreground GPS, photo EXIF,
significant-change cell tower) and lets you turn moments into **Stamps** — cards with
photos, text, and tags that stay private by default and can be shared to a feed.

See [`CLAUDE.md`](CLAUDE.md) for the full architecture, data model, and rules.

## Features

- **Three-layer trace model:** GPS breadcrumbs (route line) → Check-ins (visit pins) → Stamps (posts)
- **Social graph:** Follows (asymmetric, private-account gated) + Friends (symmetric, Snapchat-style)
- **Live location sharing:** Snap Map–style friend bubbles on the map, ghost mode, per-friend visibility
- **Feed stories:** Public check-ins surface as 24h stories in followers' feed
- **AI diary:** One-tap daily diary generation via Gemini 3.1 flash lite (server-side Edge Function, photos resized in-memory)
- **Photo check-in:** Import geotagged photos → time-clustered check-ins → swipeable inspection/edit screen
- **Coordinate-anchored place search:** Every location editor uses `PlaceSearchField` — coordinate fixed at creation time, nearby suggestions + text search

## Stack

Flutter · Riverpod · go_router · Supabase (Postgres/Auth/Storage/Realtime/Edge Functions) ·
Mapbox · Hive · Firebase Messaging.

- **Auth:** Supabase OAuth (Apple/Google) via `flutter_web_auth_2` (native in-app
  ASWebAuthenticationSession).
- **Place search:** Kakao Local API in Korea, Google Places worldwide
  (`lib/core/places/place_service_provider.dart`).
- **AI:** Gemini 3.1 flash lite via `generate-diary` Supabase Edge Function (API key server-side only).

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
