import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../shared/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/friend_location.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../data/repositories/location_sharing_repository.dart';
import '../../../core/location/providers/gps_provider.dart';
import '../../../core/places/place_service_provider.dart' show placeServiceForProvider;
import '../../../core/places/place_models.dart';
import '../../../core/auth/auth_provider.dart';
import 'map_drawing.dart';

const _kCheckinBlue = 0xFF2196F3;
const _kFollowedOrange = 0xFFFF9800;
const _kFollowedCheckinPink = 0xFFE91E63;

// Location broadcast thresholds (Snapchat-style: update on open + significant moves)
const _kBroadcastIntervalSec = 30;
const _kBroadcastMinDistM = 50.0;

enum MapFilter { today, week, month, year, all, custom }

enum PlaceCategory { all, cafe, food, culture, outdoor, shopping }

extension _PlaceCategoryExt on PlaceCategory {
  String get label => switch (this) {
        PlaceCategory.all => 'All',
        PlaceCategory.cafe => '☕ Café',
        PlaceCategory.food => '🍴 Food',
        PlaceCategory.culture => '🎨 Art',
        PlaceCategory.outdoor => '🌿 Nature',
        PlaceCategory.shopping => '🏬 Retail',
      };
}

extension _MapFilterExt on MapFilter {
  String get label => switch (this) {
        MapFilter.today => 'Today',
        MapFilter.week => 'Week',
        MapFilter.month => 'Month',
        MapFilter.year => 'Year',
        MapFilter.all => 'All time',
        MapFilter.custom => 'Custom',
      };
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _map;
  bool _styleLoaded = false;

  // Own data — always "today"
  List<Stamp> _myStamps = [];
  List<CheckIn> _myCheckIns = [];

  // Following data
  List<Stamp> _followedStamps = [];
  List<CheckIn> _followedCheckIns = []; // public, last 24h always

  // Friend live locations (Snap Map layer)
  List<FriendLocation> _friendLocations = [];
  final ValueNotifier<Map<String, Offset>> _friendScreenPosNotifier = ValueNotifier({});
  // Show the name/time chip on friend bubbles only when zoomed in enough.
  static const double _kFriendLabelZoom = 16.5;
  double _currentZoom = 13.0;

  // Location broadcasting state
  DateTime? _lastBroadcast;
  geo.Position? _lastBroadcastPos;

  MapFilter _filter = MapFilter.today;
  DateTimeRange? _customRange;
  bool _savedOnly = false;
  List<Stamp> _savedStamps = [];
  bool _loading = false;

  // Search bar state (Phase A)
  final _searchCtrl = TextEditingController();
  bool _searchActive = false;
  List<PlaceResult> _searchResults = [];
  PlaceResult? _selectedSearchResult;
  bool _searching = false;

  // Category filter state (Phase B)
  PlaceCategory _category = PlaceCategory.all;

  // Nearby hot list state (Phase E)
  List<PlaceStat> _nearbyPlaces = [];
  bool _nearbyLoading = false;
  bool _nearbyLoaded = false;
  String? _geocodedAddress;

  // Pinned location — long-press to set; scopes search/nearby/trending
  ({double lat, double lng})? _pinnedLocation;
  final ValueNotifier<Offset?> _pinScreenPosNotifier = ValueNotifier(null);

  double _sheetExtent = 0.26;
  late final DraggableScrollableController _sheetController = DraggableScrollableController();
  Timer? _legendTimer;
  Timer? _searchDebounce;
  bool _showLegend = false;

  (DateTime, DateTime) _filterRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_filter) {
      MapFilter.today => (today, now),
      MapFilter.week => (now.subtract(const Duration(days: 7)), now),
      MapFilter.month => (DateTime(now.year, now.month - 1, now.day), now),
      MapFilter.year => (DateTime(now.year - 1, now.month, now.day), now),
      MapFilter.all => (DateTime(2020), now),
      MapFilter.custom => (
          _customRange?.start ?? today,
          (_customRange?.end ?? now).add(const Duration(days: 1)),
        ),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadNearbyPlaces();
      ref.read(gpsNotifierProvider.notifier).startTracking();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _friendScreenPosNotifier.dispose();
    _pinScreenPosNotifier.dispose();
    _legendTimer?.cancel();
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onMapTouch() {
    _legendTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _showLegend = true;
    });
    _legendTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showLegend = false;
      });
    });
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (ref.read(currentUserProvider) == null) return;
    setState(() => _loading = true);
    final stampRepo = ref.read(stampRepositoryProvider);
    final checkInRepo = ref.read(checkInRepositoryProvider);
    final (from, to) = _filterRange();

    final (myStamps, myCheckIns, followedStamps, followedCheckIns, saved) =
        await (
      stampRepo.getMyStampsForRange(from: from, to: to),
      checkInRepo.getMyCheckInsForRange(from: from, to: to),
      stampRepo.getFollowingStamps(from: from, to: to),
      checkInRepo.getFollowingPublicCheckIns(),
      stampRepo.getSavedStamps(),
    ).wait;

    if (!mounted) return;
    setState(() {
      _myStamps = myStamps.getOrElse((_) => []);
      _myCheckIns = myCheckIns.getOrElse((_) => []);
      _followedStamps = followedStamps.getOrElse((_) => []);
      _followedCheckIns = followedCheckIns.getOrElse((_) => []);
      _savedStamps = saved.getOrElse((_) => []);
      _loading = false;
    });
    _updateLayers();
  }

  void _toggleSaved() {
    setState(() => _savedOnly = !_savedOnly);
    _updateLayers();
  }

  // ── Search (Phase A) ─────────────────────────────────────────────────────

  Future<void> _runSearch() async {
    final text = _searchCtrl.text.trim();
    if (text.isEmpty && _category == PlaceCategory.all) {
      setState(() {
        _searchResults = [];
        _selectedSearchResult = null;
      });
      await _clearSearchLayer();
      return;
    }

    setState(() => _searching = true);
    final pinned = _pinnedLocation;
    final pos = ref.read(gpsNotifierProvider).valueOrNull;
    final lat = pinned?.lat ?? pos?.latitude ?? 37.5665;
    final lng = pinned?.lng ?? pos?.longitude ?? 126.9780;

    String query = text;
    if (_category != PlaceCategory.all) {
      final isKr = isKorea(lat, lng);
      final catKeyword = switch (_category) {
        PlaceCategory.cafe => isKr ? '카페' : 'cafe',
        PlaceCategory.food => isKr ? '맛집' : 'food',
        PlaceCategory.culture => isKr ? '문화' : 'culture',
        PlaceCategory.outdoor => isKr ? '자연' : 'outdoor',
        PlaceCategory.shopping => isKr ? '쇼핑' : 'shopping',
        _ => '',
      };
      if (catKeyword.isNotEmpty) {
        if (text.isEmpty) {
          query = catKeyword;
        } else {
          query = '$catKeyword $text';
        }
      }
    }

    try {
      final svc = ref.read(placeServiceForProvider(lat, lng));
      final results = await svc.search(query, lat, lng);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _runSearch);
  }

  Future<void> _selectSearchResult(PlaceResult place) async {
    setState(() {
      _selectedSearchResult = place;
      _searchActive = false;
      _searchResults = [];
      _searchCtrl.text = place.name;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    _map?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(place.lng, place.lat)),
        zoom: 16.0,
      ),
      MapAnimationOptions(duration: 500),
    );
    await _drawSearchPin(place);
  }

  Future<void> _drawSearchPin(PlaceResult place) async {
    final map = _map;
    if (map == null) return;
    await drawPins(
      map,
      sourceId: 'search-result-source',
      layerId: 'search-result-layer',
      pins: [
        MapPin(
          id: place.placeId,
          kind: 'search',
          name: place.name,
          lat: place.lat,
          lng: place.lng,
        ),
      ],
      color: 0xFF607D8B, // neutral blue-grey for search result pins
      circleRadius: 9.0,
    );
  }

  Future<void> _clearSearchLayer() async {
    final map = _map;
    if (map == null) return;
    await drawPins(
      map,
      sourceId: 'search-result-source',
      layerId: 'search-result-layer',
      pins: [],
      color: 0xFF607D8B,
    );
  }

  // ── Pinned location ───────────────────────────────────────────────────────

  void _onMapLongPress(MapContentGestureContext ctx) {
    final coords = ctx.point.coordinates;
    final lat = coords.lat.toDouble();
    final lng = coords.lng.toDouble();
    setState(() {
      _pinnedLocation = (lat: lat, lng: lng);
      _nearbyLoaded = false;
      _nearbyPlaces = [];
    });
    _updatePinScreenPosition();
    _loadNearbyPlaces();
  }

  Future<void> _updatePinScreenPosition() async {
    final pin = _pinnedLocation;
    final map = _map;
    if (pin == null || map == null) {
      _pinScreenPosNotifier.value = null;
      return;
    }
    try {
      final sc = await map.pixelForCoordinate(
        Point(coordinates: Position(pin.lng, pin.lat)),
      );
      _pinScreenPosNotifier.value = Offset(sc.x, sc.y);
    } catch (_) {
      _pinScreenPosNotifier.value = null;
    }
  }

  void _clearPinnedLocation() {
    setState(() {
      _pinnedLocation = null;
      _nearbyLoaded = false;
      _nearbyPlaces = [];
    });
    _pinScreenPosNotifier.value = null;
    _loadNearbyPlaces();
  }

  // ── Phase E: Nearby hot list ──────────────────────────────────────────────

  Future<String?> _geocodeCoords(double lat, double lng) async {
    final dio = Dio();
    try {
      if (isKorea(lat, lng)) {
        final key = dotenv.env['KAKAO_REST_API_KEY'] ?? '';
        if (key.isNotEmpty) {
          final res = await dio.get<Map<String, dynamic>>(
            'https://dapi.kakao.com/v2/local/geo/coord2regioncode.json',
            queryParameters: {'x': '$lng', 'y': '$lat'},
            options: Options(headers: {'Authorization': 'KakaoAK $key'}),
          );
          final docs = res.data?['documents'] as List? ?? [];
          if (docs.isNotEmpty) {
            final doc = docs.firstWhere(
                  (d) => (d as Map)['region_type'] == 'H',
                  orElse: () => docs.first,
                ) as Map;
            final region2 = doc['region_2depth_name'] as String? ?? '';
            final region3 = doc['region_3depth_name'] as String? ?? '';
            String name = '$region2 $region3'.trim();
            if (name.isEmpty) name = doc['address_name'] as String? ?? '';
            if (name.isNotEmpty) return name;
          }
        }
      } else {
        final token = dotenv.env['MAPBOX_TOKEN'] ?? '';
        if (token.isNotEmpty) {
          final res = await dio.get<Map<String, dynamic>>(
            'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json',
            queryParameters: {
              'types': 'neighborhood,locality,place',
              'limit': '1',
              'access_token': token,
            },
          );
          final features = res.data?['features'] as List? ?? [];
          if (features.isNotEmpty) {
            final feat = features.first as Map;
            String text = feat['text'] as String? ?? '';
            if (text.isEmpty) text = feat['place_name'] as String? ?? '';
            if (text.isNotEmpty) return text;
          }
        }
      }
    } catch (e) {
      debugPrint('[Geocode] Error geocoding ($lat, $lng): $e');
    } finally {
      dio.close();
    }
    return null;
  }

  Future<void> _loadNearbyPlaces() async {
    final pinned = _pinnedLocation;
    final pos = ref.read(gpsNotifierProvider).valueOrNull;
    final lat = pinned?.lat ?? pos?.latitude;
    final lng = pinned?.lng ?? pos?.longitude;
    if (lat == null || lng == null) return;
    setState(() {
      _nearbyLoading = true;
      _geocodedAddress = null;
    });

    _geocodeCoords(lat, lng).then((address) {
      if (mounted) {
        setState(() {
          _geocodedAddress = address;
        });
      }
    });

    final result = await ref.read(stampRepositoryProvider).getNearbyHotPlaces(
          lat, lng,
          radiusKm: 5,
        );
    if (!mounted) return;
    final places = result.getOrElse((_) => []);
    setState(() {
      _nearbyPlaces = places;
      _nearbyLoading = false;
      _nearbyLoaded = true;
    });
    // Phase C: draw hot-place circles on the map
    final map = _map;
    if (map != null && places.isNotEmpty) {
      await drawHotPlaces(
        map,
        [
          for (final p in places)
            (
              id: p.placeId,
              name: p.name,
              lat: p.lat,
              lng: p.lng,
              hotScore: p.hotScore,
            ),
        ],
      );
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _searchActive = false;
      _searchResults = [];
      _selectedSearchResult = null;
      _category = PlaceCategory.all;
    });
    _clearSearchLayer();
  }

  bool _hasCenteredOnUser = false;

  void _centerOnUserInitial(geo.Position pos) {
    if (_hasCenteredOnUser || _map == null || !_styleLoaded) return;
    _hasCenteredOnUser = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _map?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(pos.longitude, pos.latitude),
          ),
          zoom: 14.0,
        ),
        MapAnimationOptions(duration: 800),
      );
    });
  }

  // ── Friend avatar overlay ─────────────────────────────────────────────────

  void _onFriendLocationsChanged(List<FriendLocation> locations) {
    if (!mounted) return;
    setState(() => _friendLocations = locations.where((f) => !f.isStale).toList());
    _updateFriendScreenPositions();
  }

  Future<void> _updateFriendScreenPositions() async {
    final map = _map;
    if (map == null || _friendLocations.isEmpty) {
      _friendScreenPosNotifier.value = const {};
      return;
    }
    final positions = <String, Offset>{};
    for (final fl in _friendLocations) {
      try {
        final sc = await map.pixelForCoordinate(
          Point(coordinates: Position(fl.lng, fl.lat)),
        );
        positions[fl.userId] = Offset(sc.x, sc.y);
      } catch (e) {
        debugPrint('[MapScreen] pixelForCoordinate failed for ${fl.userId}: $e');
      }
    }
    _friendScreenPosNotifier.value = positions;
  }

  // ── Location broadcasting ─────────────────────────────────────────────────

  void _maybeBroadcast(geo.Position pos) {
    final now = DateTime.now();
    final last = _lastBroadcast;
    final lastPos = _lastBroadcastPos;

    bool should = last == null ||
        now.difference(last).inSeconds >= _kBroadcastIntervalSec;

    if (!should && lastPos != null) {
      final dist = geo.Geolocator.distanceBetween(
        lastPos.latitude, lastPos.longitude,
        pos.latitude, pos.longitude,
      );
      if (dist >= _kBroadcastMinDistM) should = true;
    }

    if (!should) return;
    _lastBroadcast = now;
    _lastBroadcastPos = pos;

    ref.read(locationSharingRepositoryProvider).upsertMyLocation(
          pos.latitude, pos.longitude,
          pos.accuracy > 0 ? pos.accuracy : null,
          pos.heading >= 0 ? pos.heading : null,
        );
  }

  // ── Map layers ────────────────────────────────────────────────────────────

  Future<void> _updateLayers() async {
    final map = _map;
    if (map == null) return;
    try {
      await map.location.updateSettings(LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
      ));
    } catch (e) {
      debugPrint('puck: $e');
    }

    final displayedStamps = _savedOnly ? _savedStamps : _myStamps;
    await drawPins(
      map,
      sourceId: 'my-stamps-source',
      layerId: 'my-stamps-layer',
      pins: [
        for (final s in displayedStamps)
          MapPin(id: s.id, kind: 'stamp', name: s.placeName, lat: s.lat, lng: s.lng),
      ],
      color: Z.brand.toARGB32(),
    );
    await drawPins(
      map,
      sourceId: 'my-checkins-source',
      layerId: 'my-checkins-layer',
      pins: [
        for (final c in _myCheckIns)
          if (c.source != CheckInSource.auto)
            MapPin(id: c.id, kind: 'checkin', name: c.placeName, lat: c.lat, lng: c.lng),
      ],
      color: _kCheckinBlue,
    );
    await drawPins(
      map,
      sourceId: 'my-auto-source',
      layerId: 'my-auto-layer',
      pins: [
        for (final c in _myCheckIns)
          if (c.source == CheckInSource.auto)
            MapPin(id: c.id, kind: 'checkin', name: c.placeName, lat: c.lat, lng: c.lng),
      ],
      color: 0xFF9E9E9E,
      circleRadius: 2.5,
      strokeWidth: 0.0,
      opacity: 0.55,
    );
    await drawPins(
      map,
      sourceId: 'followed-stamps-source',
      layerId: 'followed-stamps-layer',
      pins: [
        for (final s in _followedStamps)
          MapPin(id: s.id, kind: 'fstamp', name: s.placeName, lat: s.lat, lng: s.lng),
      ],
      color: _kFollowedOrange,
    );
    await drawPins(
      map,
      sourceId: 'followed-checkins-source',
      layerId: 'followed-checkins-layer',
      pins: [
        for (final c in _followedCheckIns)
          MapPin(id: c.id, kind: 'fcheckin', name: c.placeName, lat: c.lat, lng: c.lng),
      ],
      color: _kFollowedCheckinPink,
      circleRadius: 6.0,
      strokeWidth: 1.5,
      opacity: 0.85,
    );
    await _drawLive();
  }

  Future<void> _drawLive() async {
    final map = _map;
    if (map == null) return;
    final path = ref.read(gpsNotifierProvider.notifier).sessionPath;
    if (path.length < 2) {
      await removeLine(map, idPrefix: 'live-route');
      return;
    }
    await upsertLine(map, path, Z.brand.toARGB32(), idPrefix: 'live-route');
  }

  // ── Tap handling ──────────────────────────────────────────────────────────

  Future<void> _onMapTap(MapContentGestureContext ctx) async {
    final map = _map;
    if (map == null) return;
    try {
      final features = await map.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(ctx.touchPosition),
        RenderedQueryOptions(
          layerIds: const [
            'my-stamps-layer',
            'my-checkins-layer',
            'my-auto-layer',
            'followed-stamps-layer',
            'followed-checkins-layer',
            'hot-places-layer',
          ],
          filter: null,
        ),
      );
      for (final f in features) {
        final props = f?.queriedFeature.feature['properties'];
        if (props is Map) {
          final id = props['id'] as String?;
          final kind = props['kind'] as String?;
          if (id != null && kind != null) {
            _showSheet(kind, id);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('queryRenderedFeatures: $e');
    }
  }

  static T? _find<T>(List<T> list, bool Function(T) test) {
    for (final e in list) {
      if (test(e)) return e;
    }
    return null;
  }

  void _showSheet(String kind, String id) {
    // Hot place (Phase C) → navigate to place detail
    if (kind == 'hot') {
      context.push('/place/$id');
      return;
    }
    if (kind == 'stamp' || kind == 'fstamp') {
      final stamp = _find(_myStamps, (s) => s.id == id) ??
          _find(_followedStamps, (s) => s.id == id);
      if (stamp == null) return;
      showModalBottomSheet<void>(
        useRootNavigator: true,
        context: context,
        builder: (ctx) => _StampSheet(stamp: stamp),
      );
      return;
    }
    if (kind == 'checkin' || kind == 'fcheckin') {
      final mine = _find(_myCheckIns, (c) => c.id == id);
      final checkIn = mine ?? _find(_followedCheckIns, (c) => c.id == id);
      if (checkIn == null) return;
      final isMine = mine != null;
      showModalBottomSheet<void>(
        useRootNavigator: true,
        context: context,
        builder: (ctx) => _CheckInSheet(
          checkIn: checkIn,
          isMine: isMine,
          onPromote: isMine ? () => _promote(ctx, checkIn) : null,
        ),
      );
    }
  }

  void _promote(BuildContext sheetCtx, CheckIn checkIn) {
    Navigator.pop(sheetCtx);
    context.push('/checkin?fromCheckIn=${checkIn.id}');
  }

  void _showFriendSheet(String userId) {
    final fl = _find(_friendLocations, (f) => f.userId == userId);
    if (fl == null) return;
    // Center + zoom onto the selected friend.
    _map?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(fl.lng, fl.lat)),
        zoom: 17.5,
      ),
      MapAnimationOptions(duration: 600),
    );
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      builder: (ctx) => _FriendLocationSheet(
        location: fl,
        onViewProfile: () {
          Navigator.pop(ctx);
          context.push('/profile/$userId');
        },
      ),
    );
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  Future<void> _onFilterTap(MapFilter f) async {
    if (f == MapFilter.custom) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _customRange,
      );
      if (range == null) return;
      setState(() {
        _filter = MapFilter.custom;
        _customRange = range;
      });
    } else {
      setState(() => _filter = f);
    }
    _load();
  }

  // ── Ghost Mode ────────────────────────────────────────────────────────────

  Future<void> _toggleGhostMode(bool current) async {
    final next = !current;
    try {
      await ref
          .read(locationSharingRepositoryProvider)
          .setGhostMode(next);
      ref.invalidate(ghostModeProvider);
      if (next) {
        // Hide friends from view immediately while ghosting.
        _friendScreenPosNotifier.value = const {};
      } else {
        _updateFriendScreenPositions();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(next
                ? 'Ghost mode on — your location is hidden'
                : 'Ghost mode off — sharing location with friends'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update ghost mode')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(gpsNotifierProvider).valueOrNull;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final mapScreenHeight = MediaQuery.of(context).size.height - 83 - bottomPad;
    final paddingTop = MediaQuery.of(context).padding.top;
    final maxSheetSize = mapScreenHeight > 0
        ? (1.0 - (paddingTop + 130) / mapScreenHeight).clamp(0.6, 0.85)
        : 0.8;
    final effectiveExtent = _searchActive ? 0.0 : _sheetExtent;
    // GPS: draw live route + broadcast position
    ref.listen(gpsNotifierProvider, (previous, next) {
      final pos = next.valueOrNull;
      if (pos == null) return;
      _centerOnUserInitial(pos);
      _drawLive();
      _maybeBroadcast(pos);
      if (!_nearbyLoaded && !_nearbyLoading) {
        _loadNearbyPlaces();
      }
    });

    // Friend locations: subscribe to Realtime stream
    ref.listen(
      friendLocationsProvider,
      (_, next) => next.whenData(_onFriendLocationsChanged),
    );

    // Ghost Mode indicator
    final ghostMode = ref.watch(ghostModeProvider).valueOrNull ?? false;

    return Scaffold(
      body: Stack(
        children: [
          // ── Mapbox base ─────────────────────────────────────────────
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _onMapTouch(),
              child: MapWidget(
                key: const ValueKey("mapWidget"),
                styleUri: MapboxStyles.MAPBOX_STREETS,
                textureView: true,
                // ignore: deprecated_member_use
                cameraOptions: CameraOptions(
                  center: Point(
                    coordinates: Position(
                      pos?.longitude ?? 126.9780,
                      pos?.latitude ?? 37.5665,
                    ),
                  ),
                  zoom: 13.0,
                ),
                onCameraChangeListener: (data) {
                  // Read zoom synchronously from the event to avoid a race
                  // between concurrent async getCameraState() calls.
                  _currentZoom = data.cameraState.zoom;
                  _updateFriendScreenPositions();
                  _updatePinScreenPosition();
                },
                onStyleLoadedListener: (styleLoadedEventData) {
                  _styleLoaded = true;
                  final posVal = ref.read(gpsNotifierProvider).valueOrNull;
                  if (posVal != null) {
                    _centerOnUserInitial(posVal);
                  }
                },
                onMapCreated: (controller) {
                  _map = controller;
                  controller.addInteraction(TapInteraction.onMap(_onMapTap));
                  controller.addInteraction(LongTapInteraction.onMap(_onMapLongPress));
                  _updateLayers();
                  
                  // Center camera immediately if location is already resolved
                  final posVal = ref.read(gpsNotifierProvider).valueOrNull;
                  if (posVal != null) {
                    _centerOnUserInitial(posVal);
                  }
                  
                  _updateFriendScreenPositions();
                },
              ),
            ),
          ),

          // ── Friend avatar bubbles ───────────────────────────────────
          // Hidden while ghosting: if you don't share, you don't see.
          if (!ghostMode)
          ValueListenableBuilder<Map<String, Offset>>(
            valueListenable: _friendScreenPosNotifier,
            builder: (ctx, positions, _) {
              final bubbles = <Widget>[];
              for (final entry in positions.entries) {
                final fl = _find(_friendLocations, (f) => f.userId == entry.key);
                if (fl != null) {
                  bubbles.add(
                    Positioned(
                      // Anchor by the arrow tip: it sits 38px below the top of
                      // the column (avatar 28 + 2px ring ×2 = 32, + 6px tip).
                      // FractionalTranslation(-0.5 x) centers horizontally so
                      // the tip lands on the exact coordinate regardless of the
                      // name box width.
                      left: entry.value.dx,
                      top: entry.value.dy - 38,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0),
                        child: _FriendBubble(
                          location: fl,
                          showLabel: _currentZoom >= _kFriendLabelZoom,
                          onTap: () => _showFriendSheet(fl.userId),
                        ),
                      ),
                    ),
                  );
                }
              }
              return Stack(
                children: bubbles,
              );
            },
          ),

          // ── Pinned location emoji ───────────────────────────────────
          ValueListenableBuilder<Offset?>(
            valueListenable: _pinScreenPosNotifier,
            builder: (ctx, offset, _) {
              if (offset == null) return const SizedBox.shrink();
              return Positioned(
                left: offset.dx - 14,
                top: offset.dy - 30,
                child: const IgnorePointer(
                  child: Text('📍', style: TextStyle(fontSize: 28)),
                ),
              );
            },
          ),

          // ── Top header box: search + category chips (prototype layout) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Z.surface1,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 0,
                      offset: Offset(0, 1)),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search row: ZON brand + Search field + Cancel button
                      Row(
                        children: [
                          // Left ZON logo (collapses when search is active)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            width: _searchActive ? 0 : 80, // ZON text width (66) + spacing (14) = 80
                            decoration: const BoxDecoration(),
                            clipBehavior: Clip.hardEdge,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _searchActive ? 0.0 : 1.0,
                              curve: Curves.easeInOut,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: SizedBox(
                                  width: 80,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ZON',
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          color: Z.text,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Search field
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(fontSize: 14, color: Z.text),
                              decoration: InputDecoration(
                                hintText: 'Search places, areas…',
                                prefixIcon: _searching
                                    ? const Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)),
                                      )
                                    : const Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: Icon(Icons.search,
                                            size: 18, color: Z.textMuted),
                                      ),
                                prefixIconConstraints: _searchActive
                                    ? null
                                    : const BoxConstraints(
                                        minWidth: 24,
                                        minHeight: 20,
                                      ),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: _clearSearch,
                                        behavior: HitTestBehavior.opaque,
                                        child: const Padding(
                                          padding: EdgeInsets.only(left: 6),
                                          child: Icon(Icons.close, size: 16, color: Z.textMuted),
                                        ),
                                      )
                                    : null,
                                suffixIconConstraints: _searchActive
                                    ? null
                                    : const BoxConstraints(
                                        minWidth: 22,
                                        minHeight: 20,
                                      ),
                                filled: false,
                                isDense: true,
                                contentPadding: _searchActive
                                    ? const EdgeInsets.symmetric(horizontal: 4, vertical: 10)
                                    : const EdgeInsets.fromLTRB(0, 4, 0, 4),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Z.outline2),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Z.brand, width: 1.5),
                                ),
                                border: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Z.outline2),
                                ),
                              ),
                              onTap: () => setState(() => _searchActive = true),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          // Right Cancel button (expands when search is active)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            width: _searchActive ? 68 : 0, // spacing (8) + Cancel button text (60)
                            decoration: const BoxDecoration(),
                            clipBehavior: Clip.hardEdge,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _searchActive ? 1.0 : 0.0,
                              curve: Curves.easeInOut,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: SizedBox(
                                  width: 68,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          _clearSearch();
                                          FocusManager.instance.primaryFocus?.unfocus();
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Z.brand,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Category chips
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 30,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final cat in PlaceCategory.values) ...[
                                _CatPill(
                                  label: cat.label,
                                  active: _category == cat,
                                  onTap: () {
                                    setState(() {
                                      _category = cat;
                                      _searchActive = true;
                                    });
                                    _runSearch();
                                  },
                                ),
                                const SizedBox(width: 7),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Search results dropdown
                      if (_searchActive && _searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Z.surface1,
                            borderRadius: Z.r16,
                            border: Border.all(color: Z.outline),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000), // 8% opacity shadow
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length.clamp(0, 5),
                            separatorBuilder: (ctx, i) => const Divider(
                              height: 1,
                              color: Z.outline,
                              indent: 52,
                            ),
                            itemBuilder: (ctx, i) {
                              final r = _searchResults[i];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _selectSearchResult(r),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 11),
                                    child: Row(
                                      children: [
                                        // Premium circle icon wrapper
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: const BoxDecoration(
                                            color: Z.brandSoft,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.place,
                                            size: 16,
                                            color: Z.brand,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                r.name,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Z.text,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (r.address != null) ...[
                                                const SizedBox(height: 1),
                                                Text(
                                                  r.address!,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Z.textMuted,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Selected place card
                      if (_selectedSearchResult != null && !_searchActive)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Z.surface1,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Z.outline),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.place, color: Z.brand),
                            title: Text(_selectedSearchResult!.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: _selectedSearchResult!.address != null
                                ? Text(_selectedSearchResult!.address!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => context.push(
                                      '/place/${_selectedSearchResult!.placeId}'),
                                  child: const Text('Details'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: _clearSearch,
                                ),
                              ],
                            ),
                            dense: true,
                          ),
                        ),

                      // Pinned location indicator
                      if (_pinnedLocation != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _clearPinnedLocation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0x1AE53935),
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(color: const Color(0xFFE53935)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_pin, size: 12, color: Color(0xFFE53935)),
                                    SizedBox(width: 4),
                                    Text('Pinned location', style: TextStyle(fontSize: 11, color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
                                    SizedBox(width: 6),
                                    Icon(Icons.close, size: 12, color: Color(0xFFE53935)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Summary pill ──
          if (!_searchActive)
            Positioned(
              bottom: effectiveExtent * mapScreenHeight + 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Z.surface1,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: Z.outline),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_savedOnly ? '🔖' : '📍',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        _savedOnly
                            ? '${_savedStamps.length} saved'
                            : ghostMode
                                ? '${_myStamps.length} stamps  ·  Location hidden'
                                : '${_myStamps.length} stamps  ·  ${_friendLocations.length} friends live',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Z.text,
                        ),
                      ),
                      if (ghostMode) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.visibility_off, size: 14, color: Z.textMuted),
                      ],
                      if (_loading) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Z.brand),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // ── Map Legend ──
          Positioned(
            bottom: effectiveExtent * mapScreenHeight + 56,
            left: 16,
            child: AnimatedOpacity(
              opacity: _showLegend ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !_showLegend,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Z.surface1.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Z.outline.withValues(alpha: 0.75)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LegendRow(color: Z.brand, label: 'My stamps'),
                      const SizedBox(height: 4),
                      const _LegendRow(color: Color(_kCheckinBlue), label: 'My check-ins'),
                      const SizedBox(height: 4),
                      const _LegendRow(color: Color(_kFollowedOrange), label: 'Following stamps'),
                      const SizedBox(height: 4),
                      const _LegendRow(color: Color(_kFollowedCheckinPink), label: 'Stories (24h)'),
                      if (_friendLocations.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _LegendRow(
                          color: Colors.purple[300]!,
                          label: 'Friends live (${_friendLocations.length})',
                          isCircleAvatar: true,
                        ),
                      ],
                      if (ghostMode) ...[
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_off, size: 12, color: Z.textMuted),
                            SizedBox(width: 4),
                            Text('Ghost mode', style: TextStyle(fontSize: 10, color: Z.textMuted)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (!_searchActive)
            NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() {
                _sheetExtent = notification.extent;
              });
              return true;
            },
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.26,
              minChildSize: 0.09,
              maxChildSize: maxSheetSize,
              snap: true,
              snapSizes: [0.09, 0.26, 0.52, maxSheetSize],
              builder: (ctx, scrollCtrl) {
                final scheme = Theme.of(context).colorScheme;
                return Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: (details) {
                          final screenHeight = MediaQuery.of(context).size.height;
                          if (screenHeight > 0) {
                            final currentSize = _sheetController.size;
                            final delta = details.primaryDelta ?? 0.0;
                            final newSize = currentSize - (delta / screenHeight);
                            _sheetController.jumpTo(newSize.clamp(0.09, maxSheetSize));
                          }
                        },
                        onVerticalDragEnd: (details) {
                          final currentSize = _sheetController.size;
                          final targets = [0.09, 0.26, 0.52, maxSheetSize];
                          double closestTarget = targets.first;
                          double minDistance = (currentSize - closestTarget).abs();
                          for (final target in targets) {
                            final dist = (currentSize - target).abs();
                            if (dist < minDistance) {
                              minDistance = dist;
                              closestTarget = target;
                            }
                          }
                          _sheetController.animateTo(
                            closestTarget,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Handle
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 8, bottom: 4),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: scheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // Filter chips row
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // Duration filters — hidden while "Saved"
                                    // is active (Saved ignores duration).
                                    if (!_savedOnly)
                                      for (final f in [
                                        MapFilter.today,
                                        MapFilter.week,
                                        MapFilter.month,
                                        MapFilter.all,
                                      ])
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: _SheetChip(
                                            label: f.label,
                                            selected: _filter == f,
                                            onTap: () => _onFilterTap(f),
                                          ),
                                        ),
                                    _SheetChip(
                                      label: 'Saved',
                                      selected: _savedOnly,
                                      onTap: _toggleSaved,
                                      icon: Icons.bookmark,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Z.outline),
                    // Scrollable content
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          // ── Saved-only view (ignores duration) ──────────
                          if (_savedOnly) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Text('Saved',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Z.text)),
                            ),
                            if (_savedStamps.isEmpty)
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                                child: Text(
                                  'No saved stamps yet. Tap the bookmark on a stamp to save it.',
                                  style: TextStyle(
                                      fontSize: 13, color: Z.textMuted),
                                ),
                              )
                            else
                              for (final s in _savedStamps)
                                _SavedStampTile(
                                  stamp: s,
                                  onTap: () {
                                    _map?.flyTo(
                                      CameraOptions(
                                        center: Point(
                                            coordinates:
                                                Position(s.lng, s.lat)),
                                        zoom: 16.0,
                                      ),
                                      MapAnimationOptions(duration: 400),
                                    );
                                    context.push('/stamp/${s.id}');
                                  },
                                ),
                          ],
                          // ── Nearby section ──────────────────────────────
                          if (!_savedOnly &&
                              (_nearbyPlaces.isNotEmpty || _nearbyLoading)) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(
                                children: [
                                  Text(
                                      _pinnedLocation != null ? 'Nearby (pinned)' : 'Nearby',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: Z.text)),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _loadNearbyPlaces,
                                    child: const Text('See all →',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Z.brand,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                            if (_nearbyLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Z.brand)),
                              )
                            else
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: _nearbyPlaces.length,
                                  itemBuilder: (ctx, i) {
                                    final place = _nearbyPlaces[i];
                                    return _NearbyCard(
                                      place: place,
                                      onTap: () {
                                        _map?.flyTo(
                                          CameraOptions(
                                            center: Point(
                                                coordinates: Position(
                                                    place.lng, place.lat)),
                                            zoom: 16.0,
                                          ),
                                          MapAnimationOptions(duration: 400),
                                        );
                                        context.push('/place/${place.placeId}');
                                      },
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 8),
                            const Divider(height: 1, color: Z.outline),
                          ],
                          // ── Trending nearby — Naver-style photo grid ────
                          if (!_savedOnly &&
                              (_nearbyPlaces.isNotEmpty || _nearbyLoading)) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  Text(
                                    _geocodedAddress != null
                                        ? 'Trending in $_geocodedAddress'
                                        : 'Trending Nearby',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Z.text,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Z.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Live',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Z.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_nearbyLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Z.brand,
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  mainAxisExtent: 152,
                                ),
                                itemCount: _nearbyPlaces.length,
                                itemBuilder: (ctx, i) {
                                  final place = _nearbyPlaces[i];
                                  final pinned = _pinnedLocation;
                                  final refLat = pinned?.lat ?? pos?.latitude;
                                  final refLng = pinned?.lng ?? pos?.longitude;
                                  final distM = (refLat != null && refLng != null)
                                      ? geo.Geolocator.distanceBetween(
                                          refLat,
                                          refLng,
                                          place.lat,
                                          place.lng,
                                        )
                                      : 0.0;
                                  final distStr = distM < 1000
                                      ? '${distM.round()}m'
                                      : '${(distM / 1000.0).toStringAsFixed(1)}km';
                                  return _TrendingPhotoCard(
                                    place: place,
                                    index: i,
                                    distance: distStr,
                                    onTap: () {
                                      _map?.flyTo(
                                        CameraOptions(
                                          center: Point(
                                            coordinates: Position(
                                              place.lng,
                                              place.lat,
                                            ),
                                          ),
                                          zoom: 16.0,
                                        ),
                                        MapAnimationOptions(duration: 400),
                                      );
                                      context
                                          .push('/place/${place.placeId}');
                                    },
                                  );
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── Ghost Mode toggle (top-left) ──
        if (!_searchActive)
          Positioned(
            top: paddingTop + 100,
            left: 16,
            child: GestureDetector(
              onTap: () => _toggleGhostMode(ghostMode),
              child: Container(
                width: 56,
                height: 30,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  // Filled (brand) only when ghosting = clearly "on".
                  color: ghostMode ? Z.brand : Z.outline2,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  alignment:
                      ghostMode ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ghostMode ? Icons.visibility_off : Icons.visibility,
                      size: 14,
                      color: ghostMode ? Z.brand : Z.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── Locate Me Button ──
        Positioned(
          bottom: effectiveExtent * mapScreenHeight + 12,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'locate-me',
            tooltip: 'My location',
            elevation: 4,
            backgroundColor: Z.surface1,
            foregroundColor: Z.text,
            onPressed: () {
              final p = ref.read(gpsNotifierProvider).valueOrNull;
              if (p != null) {
                _map?.flyTo(
                  CameraOptions(
                    center: Point(coordinates: Position(p.longitude, p.latitude)),
                    zoom: 15.0,
                  ),
                  MapAnimationOptions(duration: 500),
                );
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ),
        ],
      ),
    );
  }
}

// ── Sheet chip (bottom sheet filter pill) ────────────────────────────────────

class _SheetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Z.brand : Z.surface2,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[ 
              Icon(icon, size: 13, color: selected ? Colors.white : Z.textMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : Z.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category pill (header chip — matches prototype Pill) ──────────────────────

class _CatPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CatPill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Z.brand : Z.surface2,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : Z.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Saved stamp tile (sheet list when "Saved" is active) ──────────────────────

class _SavedStampTile extends StatelessWidget {
  final Stamp stamp;
  final VoidCallback onTap;
  const _SavedStampTile({required this.stamp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: stamp.coverPhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: stamp.coverPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const ColoredBox(color: Z.surface2),
                        errorWidget: (_, __, ___) =>
                            const ColoredBox(color: Z.surface2),
                      )
                    : const ColoredBox(
                        color: Z.brandSoft,
                        child: Icon(Icons.bookmark, size: 20, color: Z.brand),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stamp.placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Z.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stamp.caption != null && stamp.caption!.isNotEmpty
                        ? stamp.caption!
                        : '@${stamp.username ?? 'you'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Z.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.bookmark, size: 16, color: Z.brand),
          ],
        ),
      ),
    );
  }
}

// ── Place emoji / category helpers ────────────────────────────────────────────

String _placeEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('café') || n.contains('cafe') || n.contains('coffee')) { return '☕'; }
  if (n.contains('restaurant') || n.contains('food') || n.contains('eat') ||
      n.contains('pasta') || n.contains('pub')) { return '🍴'; }
  if (n.contains('park') || n.contains('nature') || n.contains('garden')) { return '🌿'; }
  if (n.contains('art') || n.contains('museum') || n.contains('gallery')) { return '🎨'; }
  if (n.contains('shop') || n.contains('market') || n.contains('store')) { return '🏬'; }
  if (n.contains('bar') || n.contains('club')) { return '🍺'; }
  if (n.contains('book')) { return '📚'; }
  return '📍';
}

String _placeCategory(String name) {
  final n = name.toLowerCase();
  if (n.contains('café') || n.contains('cafe') || n.contains('coffee')) { return 'Café'; }
  if (n.contains('restaurant') || n.contains('food') || n.contains('eat') ||
      n.contains('pasta') || n.contains('bar') || n.contains('pub')) { return 'Dining'; }
  if (n.contains('park') || n.contains('nature') || n.contains('garden')) { return 'Nature'; }
  if (n.contains('art') || n.contains('museum') || n.contains('gallery')) { return 'Art'; }
  if (n.contains('shop') || n.contains('market') || n.contains('store')) { return 'Retail'; }
  return 'Place';
}

// ── Nearby card (horizontal scroll card) ──────────────────────────────────────

class _NearbyCard extends StatelessWidget {
  final PlaceStat place;
  final VoidCallback onTap;
  const _NearbyCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stamps = place.stampCount;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Z.surface1,
          border: Border.all(color: Z.outline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_placeEmoji(place.name), style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              place.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Z.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$stamps stamp${stamps != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 11, color: Z.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Friend avatar bubble (Snapchat-style) ─────────────────────────────────────


class _FriendBubble extends StatelessWidget {
  final FriendLocation location;
  final bool showLabel;
  final VoidCallback onTap;
  const _FriendBubble({
    required this.location,
    required this.onTap,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular avatar with white ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: location.avatarUrl != null
                  ? CachedNetworkImageProvider(location.avatarUrl!)
                  : null,
              backgroundColor: Colors.purple[100],
              child: location.avatarUrl == null
                  ? Text(
                      location.username[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
          ),
          // Small downward pointer (speech bubble tip)
          CustomPaint(
            size: const Size(10, 6),
            painter: _BubbleTipPainter(),
          ),
          // Name + time chip — only when zoomed in enough
          if (showLabel)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    location.username,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    location.timeLabel,
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BubbleTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Friend location bottom sheet ──────────────────────────────────────────────

class _FriendLocationSheet extends StatelessWidget {
  final FriendLocation location;
  final VoidCallback onViewProfile;
  const _FriendLocationSheet(
      {required this.location, required this.onViewProfile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: location.avatarUrl != null
                      ? CachedNetworkImageProvider(location.avatarUrl!)
                      : null,
                  backgroundColor: Colors.purple[100],
                  child: location.avatarUrl == null
                      ? Text(location.username[0].toUpperCase(),
                          style: const TextStyle(fontSize: 20))
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${location.username}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8,
                            color: location.timeLabel == 'Just now'
                                ? Colors.green
                                : Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          location.timeLabel == 'Just now'
                              ? 'Active now'
                              : location.timeLabel,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onViewProfile,
                child: const Text('View profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stamp sheet ───────────────────────────────────────────────────────────────

class _StampSheet extends StatelessWidget {
  final Stamp stamp;
  const _StampSheet({required this.stamp});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stamp.username != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('@${stamp.username}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: stamp.externalPlaceId != null
                  ? () {
                      Navigator.pop(context);
                      context.push(
                          '/place/${Uri.encodeComponent(stamp.externalPlaceId!)}');
                    }
                  : null,
              child: Text(stamp.placeName,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 4),
            Text(DateFormat('EEE, MMM d').format(stamp.visitedAt),
                style: const TextStyle(color: Colors.grey)),
            if (stamp.caption != null && stamp.caption!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(stamp.caption!, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/stamp/${stamp.id}');
                },
                child: const Text('View stamp'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legend row ────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final bool isCircleAvatar;
  const _LegendRow(
      {required this.color, required this.label, this.isCircleAvatar = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isCircleAvatar
            ? CircleAvatar(radius: 5, backgroundColor: color)
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ── Check-in sheet ────────────────────────────────────────────────────────────

class _CheckInSheet extends StatelessWidget {
  final CheckIn checkIn;
  final bool isMine;
  final VoidCallback? onPromote;
  const _CheckInSheet({
    required this.checkIn,
    required this.isMine,
    this.onPromote,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pin_drop,
                    color: Color(isMine ? _kCheckinBlue : _kFollowedCheckinPink)),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: checkIn.externalPlaceId != null
                        ? () {
                            Navigator.pop(context);
                            context.push(
                                '/place/${Uri.encodeComponent(checkIn.externalPlaceId!)}');
                          }
                        : null,
                    child: Text(checkIn.placeName,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(DateFormat('EEE, MMM d · h:mm a').format(checkIn.visitedAt),
                style: const TextStyle(color: Colors.grey)),
            if (checkIn.note != null && checkIn.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(checkIn.note!, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/check-in/${checkIn.id}');
                    },
                    child: const Text('View details'),
                  ),
                ),
                if (onPromote != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onPromote,
                      child: const Text('Make a stamp'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trending photo card (Naver Map-style ranking grid) ────────────────────────

class _TrendingPhotoCard extends StatelessWidget {
  final PlaceStat place;
  final int index;
  final String distance;
  final VoidCallback onTap;

  const _TrendingPhotoCard({
    required this.place,
    required this.index,
    required this.distance,
    required this.onTap,
  });

  String get _scoreText {
    if (index == 0) return '🔥 Hot';
    if (index == 1 || index == 2) return '⬆ Rising';
    return 'New';
  }

  // Deterministic muted tint so cards look varied without real cover photos.
  Color get _tint {
    const palette = [
      Color(0xFFD0C8CC),
      Color(0xFFC4CCC0),
      Color(0xFFCCC8C0),
      Color(0xFFC0C4CC),
      Color(0xFFC8C8C0),
      Color(0xFFCCC0C8),
    ];
    return palette[place.placeId.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder "photo" — tinted surface + faint category emoji
            ColoredBox(
              color: _tint,
              child: Center(
                child: Text(
                  _placeEmoji(place.name),
                  style: TextStyle(
                    fontSize: 46,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            // Gradient scrim: black 22% → transparent → black 68%
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.38, 0.8],
                  colors: [
                    Color(0x38000000),
                    Colors.transparent,
                    Color(0xAD000000),
                  ],
                ),
              ),
            ),
            // Rank number
            Positioned(
              top: 6,
              left: 9,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            // Score badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x61000000),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  _scoreText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Place name + category · distance
            Positioned(
              left: 9,
              right: 9,
              bottom: 9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_placeCategory(place.name)} · $distance',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xBFFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

