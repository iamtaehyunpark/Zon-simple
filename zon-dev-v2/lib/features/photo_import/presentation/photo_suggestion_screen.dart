import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/photos/photo_service.dart';
import '../../../core/places/place_service_provider.dart';
import '../../../data/models/check_in.dart';
import '../../../data/repositories/check_in_repository.dart';
import 'photo_checkin_inspection_screen.dart';

// ignore_for_file: use_build_context_synchronously

class PhotoSuggestionScreen extends ConsumerStatefulWidget {
  const PhotoSuggestionScreen({super.key});

  @override
  ConsumerState<PhotoSuggestionScreen> createState() =>
      _PhotoSuggestionScreenState();
}

class _PhotoSuggestionScreenState extends ConsumerState<PhotoSuggestionScreen> {
  final _photoService = PhotoService();
  List<AssetEntity> _photos = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _analyzing = false; // building groups + resolving places

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final photos = await _photoService.getPhotosWithLocation(days: 30);
    if (mounted) {
      setState(() {
        _photos = photos;
        _loading = false;
      });
    }
  }

  Future<ImageProvider?> _thumbProvider(AssetEntity asset) async {
    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );
    if (data == null) return null;
    return MemoryImage(data);
  }

  // Sequential photos within this distance (metres) are merged into one check-in.
  static const _kSequentialMergeMeters = 150.0;

  Future<void> _importSelected() async {
    if (_selected.isEmpty) return;
    setState(() => _analyzing = true);

    // 1. Sort chronologically.
    final assets = _photos.where((p) => _selected.contains(p.id)).toList()
      ..sort((a, b) => a.createDateTime.compareTo(b.createDateTime));

    // 2. Fetch existing check-ins to detect visit breaks.
    final existingRes =
        await ref.read(checkInRepositoryProvider).getMyCheckIns(limit: 500);
    final existing = existingRes.getOrElse((_) => <CheckIn>[]);

    // 3. Cluster sequentially (same logic as before, but no upload yet).
    final groups = <InspectionGroup>[];
    DateTime? prevTime;

    for (final asset in assets) {
      final latLng = await asset.latlngAsync();
      if (latLng == null ||
          (latLng.latitude == 0.0 && latLng.longitude == 0.0)) {
        continue;
      }

      final photoTime = asset.createDateTime;
      final last = groups.isEmpty ? null : groups.last;
      bool merge = false;

      if (last != null && prevTime != null) {
        final dist = Geolocator.distanceBetween(
            last.lat, last.lng, latLng.latitude, latLng.longitude);
        final hasBreak = existing.any((c) =>
            c.visitedAt.isAfter(prevTime!) && c.visitedAt.isBefore(photoTime));
        merge = dist < _kSequentialMergeMeters && !hasBreak;
      }

      if (merge) {
        last!.assets.add(asset);
        if (photoTime.isBefore(last.takenAt)) last.takenAt = photoTime;
      } else {
        groups.add(InspectionGroup(
          assets: [asset],
          lat: latLng.latitude,
          lng: latLng.longitude,
          takenAt: photoTime,
          placeName: 'Photo location',
        ));
      }

      prevTime = photoTime;
    }

    // 4. Resolve place names in parallel.
    await Future.wait([
      for (final g in groups)
        _resolvePlace(g.lat, g.lng).then((name) => g.placeName = name),
    ]);

    if (!mounted) return;
    setState(() => _analyzing = false);

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid geotagged photos selected')),
      );
      return;
    }

    // 5. Hand off to inspection screen; upload + create happens there.
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoCheckInInspectionScreen(groups: groups),
      ),
    );

    if (confirmed == true && mounted) {
      final n = groups.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$n check-in${n == 1 ? '' : 's'} added')),
      );
      context.pop();
    }
  }

  Future<String> _resolvePlace(double lat, double lng) async {
    try {
      final service = ref.read(placeServiceForProvider(lat, lng));
      final results = await service.nearby(lat, lng);
      if (results.isNotEmpty) return results.first.name;
    } catch (_) {/* fall through */}
    return 'Photo location';
  }

  /// Full-screen state view shown instead of the grid, or null when the grid
  /// should render (photos loaded and not mid-analysis).
  Widget? _stateOverlay() {
    if (_loading) return _busy('Scanning your photos for locations...');
    if (_analyzing) {
      return _busy('Analyzing photos…', style: const TextStyle(fontSize: 16));
    }
    if (_photos.isEmpty) return _emptyState();
    return null;
  }

  Widget _busy(String text, {TextStyle? style}) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(text, style: style),
          ],
        ),
      );

  Widget _emptyState() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No geotagged photos found', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Photos need location data to appear here.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Suggestions'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: _analyzing ? null : _importSelected,
              child: Text('Review ${_selected.length}'),
            ),
        ],
      ),
      body: _stateOverlay() ??
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_photos.length} photos with location data from the past 30 days',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selected.length == _photos.length) {
                            _selected.clear();
                          } else {
                            _selected.addAll(_photos.map((p) => p.id));
                          }
                        });
                      },
                      child: Text(
                        _selected.length == _photos.length
                            ? 'Deselect all'
                            : 'Select all',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (ctx, i) {
                    final asset = _photos[i];
                    final isSelected = _selected.contains(asset.id);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected) {
                          _selected.remove(asset.id);
                        } else {
                          _selected.add(asset.id);
                        }
                      }),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FutureBuilder<ImageProvider?>(
                            future: _thumbProvider(asset),
                            builder: (ctx, snap) {
                              if (snap.data == null) {
                                return Container(color: Colors.grey[200]);
                              }
                              return Image(
                                image: snap.data!,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                          if (isSelected)
                            Container(
                              color: kBrandPurple.withValues(alpha: 0.5),
                              child: const Icon(Icons.check_circle,
                                  color: Colors.white, size: 32),
                            ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                DateFormat('MMM d')
                                    .format(asset.createDateTime),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_selected.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _analyzing ? null : _importSelected,
                      child: Text(
                          'Review ${_selected.length} photo${_selected.length == 1 ? '' : 's'}'),
                    ),
                  ),
                ),
            ],
          ),
    );
  }
}
