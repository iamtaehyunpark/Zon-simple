import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Step 1 of the Auth CTA flow: choose the Place to verify at.
/// Fetches nearby places via the Supabase `places_within_radius` RPC.
class PlaceSelectScreen extends ConsumerStatefulWidget {
  const PlaceSelectScreen({super.key});

  @override
  ConsumerState<PlaceSelectScreen> createState() => _PlaceSelectScreenState();
}

class _PlaceSelectScreenState extends ConsumerState<PlaceSelectScreen> {
  List<_NearbyPlace> _places = [];
  bool _loading = true;
  String? _error;
  double _radiusM = 500;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final pos = await _getLocation();
      final rows = await Supabase.instance.client.rpc(
        'places_within_radius',
        params: {
          'user_lat': pos.latitude,
          'user_lng': pos.longitude,
          'radius_m': _radiusM,
        },
      ) as List<dynamic>;

      setState(() {
        _places = rows.map((r) => _NearbyPlace.fromJson(r as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Where are you?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Radius selector
          _RadiusChips(
            current: _radiusM,
            onChanged: (r) { _radiusM = r; _load(); },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('register-place'),
        backgroundColor: const Color(0xFF1D9E75),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Register new place'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1D9E75)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }
    if (_places.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.explore_off, color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          Text('No places within ${_radiusM.toInt()} m',
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 4),
          const Text('Try a larger radius or register this place.',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _PlaceCard(
        place: _places[i],
        onTap: () => context.pushNamed(
          'video-sweep',
          pathParameters: {'id': _places[i].id},
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _RadiusChips extends StatelessWidget {
  const _RadiusChips({required this.current, required this.onChanged});
  final double current;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [100, 300, 500, 1000, 2000].map((m) {
            final selected = current == m.toDouble();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${m >= 1000 ? '${m ~/ 1000}km' : '${m}m'}'),
                selected: selected,
                onSelected: (_) => onChanged(m.toDouble()),
                selectedColor: const Color(0xFF1D9E75),
                labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white60),
                backgroundColor: const Color(0xFF1A1A1A),
                side: BorderSide(
                    color: selected
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFF333333)),
              ),
            );
          }).toList(),
        ),
      );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.onTap});
  final _NearbyPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(place.category),
                  color: const Color(0xFF1D9E75), size: 22),
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
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(place.category,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_distanceLabel(place.distanceM),
                  style: const TextStyle(
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 2),
              _StatusBadge(status: place.status),
            ]),
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

  static String _distanceLabel(double? m) {
    if (m == null) return '';
    if (m < 1000) return '${m.toInt()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'confirmed' => ('✓ Verified', const Color(0xFF1D9E75)),
      'pending'   => ('Pending', Colors.orange),
      _           => ('External', Colors.blue),
    };
    return Text(label,
        style: TextStyle(color: color, fontSize: 10,
            fontWeight: FontWeight.w600));
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _NearbyPlace {
  const _NearbyPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.distanceM,
  });

  factory _NearbyPlace.fromJson(Map<String, dynamic> j) => _NearbyPlace(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        status: j['status'] as String,
        distanceM: (j['st_distance'] as num?)?.toDouble(),
      );

  final String id;
  final String name;
  final String category;
  final String status;
  final double? distanceM;
}
