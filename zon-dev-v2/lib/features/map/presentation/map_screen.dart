import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/raw_location_event.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../core/location/providers/gps_provider.dart';
import '../../../core/auth/auth_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _mapController;
  DateTime _selectedDate = DateTime.now();
  List<Stamp> _stamps = [];
  List<RawLocationEvent> _routeEvents = [];
  bool _loading = false;

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      ref.read(gpsNotifierProvider.notifier).startTracking();
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final stampRepo = ref.read(stampRepositoryProvider);
    final locationRepo = ref.read(locationRepositoryProvider);

    final (stampsResult, routeResult) = await (
      stampRepo.getMyStamps(limit: 100),
      locationRepo.getRouteForDay(_selectedDate),
    ).wait;

    if (mounted) {
      setState(() {
        _stamps = stampsResult.getOrElse((_) => []);
        _routeEvents = routeResult.getOrElse((_) => []);
        _loading = false;
      });
      _updateMapLayers();
    }
  }

  Future<void> _updateMapLayers() async {
    final map = _mapController;
    if (map == null) return;

    // Enable location puck/blue dot
    try {
      await map.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: true,
        ),
      );
    } catch (e) {
      debugPrint('Error enabling Mapbox location puck: $e');
    }

    // Draw route polyline
    if (_routeEvents.length >= 2) {
      await _drawRoute(map);
    }

    // Add stamp pins
    await _drawStampPins(map);
  }

  Future<void> _drawRoute(MapboxMap map) async {
    try {
      final coordinates = _routeEvents
          .map((e) => [e.lng, e.lat])
          .toList();

      final sourceExists = await map.style.styleSourceExists('route-source');
      if (sourceExists) {
        await map.style.removeStyleSource('route-source');
      }
      final layerExists = await map.style.styleLayerExists('route-layer');
      if (layerExists) {
        await map.style.removeStyleLayer('route-layer');
      }

      await map.style.addSource(GeoJsonSource(
        id: 'route-source',
        data: '''{
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": ${coordinates.map((c) => '[${c[0]},${c[1]}]').join(',')}
          }
        }''',
      ));

      await map.style.addLayer(LineLayer(
        id: 'route-layer',
        sourceId: 'route-source',
        lineColor: kBrandGreen.toARGB32(),
        lineWidth: 3.0,
        lineOpacity: 0.8,
      ));
    } catch (e) {
      debugPrint('Route draw error: $e');
    }
  }

  Future<void> _drawStampPins(MapboxMap map) async {
    try {
      final sourceExists = await map.style.styleSourceExists('stamps-source');
      if (sourceExists) await map.style.removeStyleSource('stamps-source');
      final layerExists = await map.style.styleLayerExists('stamps-layer');
      if (layerExists) await map.style.removeStyleLayer('stamps-layer');

      if (_stamps.isEmpty) return;

      final features = _stamps.map((s) => '''{
        "type": "Feature",
        "properties": {"id": "${s.id}", "name": "${s.placeName.replaceAll('"', '\\"')}", "public": ${s.visibility == StampVisibility.public}},
        "geometry": {"type": "Point", "coordinates": [${s.lng}, ${s.lat}]}
      }''').join(',');

      await map.style.addSource(GeoJsonSource(
        id: 'stamps-source',
        data: '{"type":"FeatureCollection","features":[$features]}',
      ));

      await map.style.addLayer(CircleLayer(
        id: 'stamps-layer',
        sourceId: 'stamps-source',
        circleRadius: 8.0,
        circleColor: kBrandGreen.toARGB32(),
        circleStrokeWidth: 2.0,
        circleStrokeColor: Colors.white.toARGB32(),
      ));
    } catch (e) {
      debugPrint('Stamp pins error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to GPS position updates to auto-center the camera on first load
    ref.listen(gpsNotifierProvider, (previous, next) {
      final pos = next.valueOrNull;
      if (pos != null && (previous == null || previous.valueOrNull == null)) {
        _mapController?.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(pos.longitude, pos.latitude),
            ),
            zoom: 14.0,
          ),
          MapAnimationOptions(duration: 800),
        );
      }
    });

    final gpsState = ref.watch(gpsNotifierProvider);
    final currentPosition = gpsState.valueOrNull;

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapbox-map'),
            viewport: CameraViewportState(
              center: Point(
                coordinates: Position(
                  currentPosition?.longitude ?? 126.9780,
                  currentPosition?.latitude ?? 37.5665,
                ),
              ),
              zoom: 13.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _updateMapLayers();
            },
          ),

          // Top overlay: date picker
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate
                              .subtract(const Duration(days: 1));
                        });
                        _loadData();
                      },
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _isToday(_selectedDate)
                          ? null
                          : () {
                              setState(() {
                                _selectedDate =
                                    _selectedDate.add(const Duration(days: 1));
                              });
                              _loadData();
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_loading)
            const Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),

          // Bottom overlay: stamp list
          if (_stamps.isNotEmpty)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _stamps.length,
                  itemBuilder: (ctx, i) {
                    final stamp = _stamps[i];
                    return GestureDetector(
                      onTap: () {
                        context.push('/stamp/${stamp.id}');
                        _mapController?.flyTo(
                          CameraOptions(
                            center: Point(
                              coordinates: Position(stamp.lng, stamp.lat),
                            ),
                            zoom: 15.0,
                          ),
                          MapAnimationOptions(duration: 500),
                        );
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              stamp.placeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d').format(stamp.visitedAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'locate-me',
        onPressed: () async {
          final pos = ref.read(gpsNotifierProvider).valueOrNull;
          if (pos != null) {
            _mapController?.flyTo(
              CameraOptions(
                center: Point(
                  coordinates: Position(pos.longitude, pos.latitude),
                ),
                zoom: 15.0,
              ),
              MapAnimationOptions(duration: 500),
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
