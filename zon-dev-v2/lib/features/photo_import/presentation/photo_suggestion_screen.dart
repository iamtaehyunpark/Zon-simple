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

// ignore_for_file: use_build_context_synchronously

/// Photos clustered at one spot during import → one check-in.
class _PhotoGroup {
  final double lat;
  final double lng;
  DateTime takenAt;
  final List<String> urls = [];
  _PhotoGroup(this.lat, this.lng, this.takenAt);
}

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
  bool _uploading = false;
  int _uploadedCount = 0;

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

  // Photos within this distance of each other are treated as the same place.
  // (A bit above 5m because EXIF GPS jitter would otherwise split one spot.)
  static const _kSamePlaceMeters = 20.0;

  Future<void> _importSelected() async {
    if (_selected.isEmpty) return;
    setState(() { _uploading = true; _uploadedCount = 0; });
    final assets = _photos.where((p) => _selected.contains(p.id)).toList();

    // Cluster photos by coordinate proximity → one check-in per cluster, so
    // photos taken at the same spot don't create duplicate check-ins.
    final clusters = <_PhotoGroup>[];
    for (final asset in assets) {
      final latLng = await asset.latlngAsync();
      if (latLng != null &&
          !(latLng.latitude == 0.0 && latLng.longitude == 0.0)) {
        final file = await asset.originFile;
        final url = file == null ? null : await _photoService.uploadFile(file);
        if (url != null) {
          _PhotoGroup? target;
          for (final c in clusters) {
            if (Geolocator.distanceBetween(
                    c.lat, c.lng, latLng.latitude, latLng.longitude) <
                _kSamePlaceMeters) {
              target = c;
              break;
            }
          }
          if (target == null) {
            target = _PhotoGroup(
                latLng.latitude, latLng.longitude, asset.createDateTime);
            clusters.add(target);
          }
          target.urls.add(url);
          if (asset.createDateTime.isBefore(target.takenAt)) {
            target.takenAt = asset.createDateTime;
          }
        }
      }
      if (mounted) setState(() => _uploadedCount++);
    }

    final repo = ref.read(checkInRepositoryProvider);
    for (final c in clusters) {
      final name = await _resolvePlace(c.lat, c.lng);
      await repo.createCheckIn(
        CheckInDraft(
          placeName: name,
          lat: c.lat,
          lng: c.lng,
          source: CheckInSource.photo,
        ),
        photoUrls: c.urls,
        visitedAt: c.takenAt,
      );
    }

    if (mounted) {
      final n = clusters.length;
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
              onPressed: _uploading ? null : _importSelected,
              child: Text('Add ${_selected.length}'),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning your photos for locations...'),
                ],
              ),
            )
          : _uploading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Uploading $_uploadedCount / ${_selected.length}...',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : _photos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No geotagged photos found',
                              style: TextStyle(fontSize: 18)),
                          SizedBox(height: 8),
                          Text(
                            'Photos need location data to appear here.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Column(
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
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
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
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    FutureBuilder<
                                        ImageProvider?>(
                                      future: _thumbProvider(asset),
                                      builder: (ctx, snap) {
                                        if (snap.data == null) {
                                          return Container(
                                              color: Colors.grey[200]);
                                        }
                                        return Image(
                                          image: snap.data!,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                    if (isSelected)
                                      Container(
                                        color: kBrandGreen.withValues(alpha: 0.5),
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
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          DateFormat('MMM d')
                                              .format(asset.createDateTime),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
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
                                16,
                                8,
                                16,
                                MediaQuery.of(context).padding.bottom + 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: _importSelected,
                                child: Text(
                                    'Add ${_selected.length} photos to my map'),
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
