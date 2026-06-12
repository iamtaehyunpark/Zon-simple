import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/place_entity.dart';
import '../providers/map_provider.dart';
import '../../../../data/models/place_status.dart';

/// Full-screen Mapbox map with nearby places bottom sheet (conquest-style).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  final _sheetController = DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    mapboxMap.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  Future<void> _addMarkers(List<PlaceEntity> places) async {
    if (_mapboxMap == null) return;

    _circleManager ??= await _mapboxMap!.annotations
        .createCircleAnnotationManager();
    await _circleManager!.deleteAll();

    final options = places.map((p) => CircleAnnotationOptions(
      geometry: Point(coordinates: Position(p.lng, p.lat)),
      circleRadius: 8.0,
      circleColor: p.status == PlaceStatus.confirmed
          ? const Color(0xFF1D9E75).value
          : Colors.orange.value,
      circleStrokeWidth: 2.0,
      circleStrokeColor: Colors.white.value,
      circleOpacity: 0.9,
    )).toList();

    if (options.isNotEmpty) {
      await _circleManager!.createMulti(options);
    }
  }

  void _flyTo(double lat, double lng) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 15.5,
      ),
      MapAnimationOptions(duration: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(mapNotifierProvider);
    final posAsync    = ref.watch(userPositionProvider);

    final initialLat = posAsync.valueOrNull?.latitude  ?? 37.5665;
    final initialLng = posAsync.valueOrNull?.longitude ?? 126.9780;

    // Update markers whenever places change
    placesAsync.whenData(_addMarkers);

    return Scaffold(
      body: Stack(children: [
        // ── Full-screen Mapbox ──────────────────────────────────────────
        MapWidget(
          key: const ValueKey('zon_map'),
          onMapCreated: _onMapCreated,
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(initialLng, initialLat)),
            zoom: 14.5,
          ),
          styleUri: 'mapbox://styles/mapbox/dark-v11',
        ),

        // ── Locate-me button ────────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 16,
          child: _MapButton(
            icon: Icons.my_location,
            onTap: () {
              final pos = posAsync.valueOrNull;
              if (pos != null) _flyTo(pos.latitude, pos.longitude);
            },
          ),
        ),

        // ── Register place button ───────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: _MapButton(
            icon: Icons.add_location_alt,
            onTap: () => context.pushNamed('register-place'),
          ),
        ),

        // ── Nearby places bottom sheet ─────────────────────────────────
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.25,
          minChildSize: 0.12,
          maxChildSize: 0.65,
          snap: true,
          snapSizes: const [0.12, 0.25, 0.65],
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 16)],
            ),
            child: Column(children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(children: [
                  const Text('Nearby Places',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const Spacer(),
                  placesAsync.when(
                    data: (p) => Text('${p.length} found',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                    loading: () => const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1D9E75))),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ]),
              ),
              // List
              Expanded(
                child: placesAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1D9E75))),
                  error: (e, _) => Center(
                      child: Text(e.toString(),
                          style:
                              const TextStyle(color: Colors.white38))),
                  data: (places) => places.isEmpty
                      ? const _NearbyEmpty()
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: places.length,
                          itemBuilder: (_, i) => _PlaceRow(
                            place: places[i],
                            onTap: () {
                              _flyTo(places[i].lat, places[i].lng);
                              context.pushNamed('auth-cta');
                            },
                            onLocate: () => _flyTo(places[i].lat, places[i].lng),
                          ),
                        ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child: Icon(icon, color: Colors.white70, size: 22),
        ),
      );
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.onTap,
    required this.onLocate,
  });
  final PlaceEntity place;
  final VoidCallback onTap;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: (place.status == PlaceStatus.confirmed
                        ? const Color(0xFF1D9E75)
                        : Colors.orange)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                _iconFor(place.category),
                color: place.status == PlaceStatus.confirmed
                    ? const Color(0xFF1D9E75)
                    : Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(place.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(place.category,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.near_me_outlined,
                  color: Colors.white38, size: 18),
              onPressed: onLocate,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ]),
        ),
      );

  static IconData _iconFor(String cat) => switch (cat.toLowerCase()) {
    'cafe'       => Icons.coffee,
    'park'       => Icons.park,
    'museum'     => Icons.museum,
    'restaurant' => Icons.restaurant,
    'landmark'   => Icons.account_balance,
    _            => Icons.place,
  };
}

class _NearbyEmpty extends StatelessWidget {
  const _NearbyEmpty();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.explore_off, color: Colors.white24, size: 40),
          const SizedBox(height: 10),
          const Text('No places nearby',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => context.pushNamed('register-place'),
            icon: const Icon(Icons.add_location_alt, size: 16,
                color: Color(0xFF1D9E75)),
            label: const Text('Register one',
                style: TextStyle(color: Color(0xFF1D9E75))),
          ),
        ]),
      );
}
