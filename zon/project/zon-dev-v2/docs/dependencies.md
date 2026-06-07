# Dependencies 

Rationale for packages in `pubspec.yaml`. Keep this in sync when adding/removing packages.

## Core framework

| Package                                                                         | Why                                                                                                                                                                        |
| ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`         | State management throughout the app.`@riverpod` codegen generates `*Provider` and `*Ref` types. Run `dart run build_runner build` after adding/changing providers. |
| `go_router`                                                                   | Declarative routing. All routes defined in `lib/app.dart`. Passes IDs (not objects) between routes.                                                                      |
| `freezed` + `freezed_annotation` + `json_serializable` + `build_runner` | Immutable data models with `copyWith`, equality, and JSON. Run build_runner after changing any `@freezed` class.                                                       |
| `fpdart`                                                                      | `Either<AppException, T>` for repo return types — explicit error handling without try/catch at call sites.                                                              |

## Backend / auth

| Package                | Why                                                                                                                                                                                                                                                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `supabase_flutter`   | The backend: Postgres queries, RLS, Auth, Storage, Realtime.                                                                                                                                                                                                                                                    |
| `flutter_web_auth_2` | Drives OAuth login (Apple/Google) via native `ASWebAuthenticationSession` on iOS. Handles the `app.getzon://` callback automatically. We call `getOAuthSignInUrl` + `getSessionFromUrl` manually and set `detectSessionInUri: false` in `Supabase.initialize` to prevent a duplicate code exchange. |
| `dio`                | HTTP client with auth interceptors for Kakao/Google Places calls.                                                                                                                                                                                                                                               |

## Maps + location

| Package                 | Why                                                                                                                                                                                       |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `mapbox_maps_flutter` | Full-screen Mapbox map. Used via `GeoJsonSource` + `CircleLayer` + `LineLayer` for pins and route lines. `upsertLine()` updates source data in-place for smooth live path growth. |
| `geolocator`          | Foreground GPS stream.`distanceBetween` for auto-anchor dedup. `LocationPermission.whileInUse` only.                                                                                  |

## Photos / media

| Package                    | Why                                                                                                                                     |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `photo_manager`          | iOS Photos Framework access + EXIF parsing (lat, lng, taken_at). Scans today's new geotagged photos for the check-in suggestion banner. |
| `image_picker`           | In-app photo picker for attaching photos to check-ins/stamps during creation/editing.                                                   |
| `flutter_image_compress` | Compress before upload to reduce storage costs.                                                                                         |
| `cached_network_image`   | Network image display with disk + memory cache. Used everywhere photos appear.                                                          |

## Local storage / notifications

| Package                                    | Why                                                                                                                                           |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `hive` + `hive_flutter`                | Local queue for GPS events before batch upload. Draft state persistence.                                                                      |
| `firebase_core` + `firebase_messaging` | FCM for remote push notifications. Remote push currently blocked on Apple paid enrollment (no APNs key). Routing seams exist in `app.dart`. |
| `flutter_local_notifications`            | Local notifications for photo suggestions. Fires when `todayPhotoSuggestionsProvider` detects new geotagged photos.                         |

## Utilities

| Package           | Why                                                                                                                                           |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `intl`          | `DateFormat` for consistent date/time display across the app.                                                                               |
| `equatable`     | Value equality for non-freezed classes.                                                                                                       |
| `envied`        | Typed `.env` access. Keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `MAPBOX_ACCESS_TOKEN`, `KAKAO_REST_API_KEY`. Never commit `.env`. |
| `path_provider` | Hive init — finds the app documents directory.                                                                                               |
| `url_launcher`  | External links (e.g. settings deep-links).                                                                                                    |

## Dev-only

| Package          | Why                              |
| ---------------- | -------------------------------- |
| `mockito`      | Test doubles in `test/unit/`.  |
| `flutter_test` | Standard Flutter widget testing. |

---

## Place search routing

Kakao Local API and Google Places are called via `Dio`, not a Flutter package:

- **Korea** (lat/lng within bounding box): Kakao Local API — coordinate-grounded nearby search. Returns `mapx`/`mapy` as WGS84 × 1e7. Auth: `KAKAO_REST_API_KEY` header.
- **Worldwide**: Google Places Nearby Search. Auth: `GOOGLE_PLACES_API_KEY`.
- Router: `placeServiceFor(lat, lng)` in `lib/core/places/place_service_provider.dart`.

Naver APIs are available in `lib/core/places/` (reverse geocoding, local search) for reference but the primary routing is Kakao → Google.
