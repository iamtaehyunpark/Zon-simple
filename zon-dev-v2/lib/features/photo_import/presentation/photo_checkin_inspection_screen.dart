import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/photos/photo_service.dart';
import '../../../data/models/check_in.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../shared/widgets/place_search_field.dart';
import '../../timeline/presentation/providers/timeline_provider.dart';

// ── Shared data model ─────────────────────────────────────────────────────────

/// One candidate check-in built from sequentially-clustered photos.
/// Mutable so the user can edit place/note and merge nodes.
class InspectionGroup {
  final List<AssetEntity> assets; // from photo library (photo_manager)
  final List<File> files;         // from share extension (alternative source)
  final double lat;
  final double lng;
  DateTime takenAt;
  String placeName;
  String note;

  InspectionGroup({
    List<AssetEntity>? assets,
    List<File>? files,
    required this.lat,
    required this.lng,
    required this.takenAt,
    required this.placeName,
    this.note = '',
  })  : assets = assets ?? [],
        files = files ?? [];

  int get photoCount => assets.length + files.length;
}

// ── Screen ────────────────────────────────────────────────────────────────────

/// Swipeable review/edit screen that appears between photo selection and
/// DB write. User can edit place/note per slide, merge adjacent slides, or
/// delete a slide before confirming the batch upload.
class PhotoCheckInInspectionScreen extends ConsumerStatefulWidget {
  final List<InspectionGroup> groups;
  const PhotoCheckInInspectionScreen({super.key, required this.groups});

  @override
  ConsumerState<PhotoCheckInInspectionScreen> createState() =>
      _PhotoCheckInInspectionScreenState();
}

class _PhotoCheckInInspectionScreenState
    extends ConsumerState<PhotoCheckInInspectionScreen> {
  late final List<InspectionGroup> _groups;
  late final PageController _page;
  late List<TextEditingController> _placeCtrl;
  late List<TextEditingController> _noteCtrl;
  int _current = 0;
  bool _uploading = false;
  int _uploadedGroups = 0;

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
    _page = PageController();
    _placeCtrl = [for (final g in _groups) TextEditingController(text: g.placeName)];
    _noteCtrl = [for (final g in _groups) TextEditingController(text: g.note)];
  }

  @override
  void dispose() {
    _page.dispose();
    for (final c in _placeCtrl) { c.dispose(); }
    for (final c in _noteCtrl) { c.dispose(); }
    super.dispose();
  }

  // ── Merge ──────────────────────────────────────────────────────────────────

  /// Merge [removeIndex] into [keepIndex]. The earlier timestamp is kept.
  void _merge(int keepIndex, int removeIndex) {
    final keep = _groups[keepIndex];
    final remove = _groups[removeIndex];

    keep.assets.addAll(remove.assets);
    keep.files.addAll(remove.files);
    if (remove.takenAt.isBefore(keep.takenAt)) keep.takenAt = remove.takenAt;

    final keepNote = _noteCtrl[keepIndex].text.trim();
    final removeNote = _noteCtrl[removeIndex].text.trim();
    _noteCtrl[keepIndex].text =
        [keepNote, removeNote].where((n) => n.isNotEmpty).join('\n');

    _placeCtrl[removeIndex].dispose();
    _noteCtrl[removeIndex].dispose();

    setState(() {
      _groups.removeAt(removeIndex);
      _placeCtrl.removeAt(removeIndex);
      _noteCtrl.removeAt(removeIndex);
      _current = keepIndex < removeIndex ? keepIndex : keepIndex - 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_page.hasClients) {
        _page.jumpToPage(_current);
      }
    });
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  void _deleteGroup(int index) {
    if (_groups.length == 1) {
      Navigator.pop(context, false);
      return;
    }
    _placeCtrl[index].dispose();
    _noteCtrl[index].dispose();
    setState(() {
      _groups.removeAt(index);
      _placeCtrl.removeAt(index);
      _noteCtrl.removeAt(index);
      _current = _current.clamp(0, _groups.length - 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_page.hasClients) _page.jumpToPage(_current);
    });
  }

  // ── Confirm ────────────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    // Flush text-field values into group objects before uploading.
    for (var i = 0; i < _groups.length; i++) {
      final place = _placeCtrl[i].text.trim();
      _groups[i].placeName = place.isEmpty ? 'Photo location' : place;
      _groups[i].note = _noteCtrl[i].text.trim();
    }

    setState(() { _uploading = true; _uploadedGroups = 0; });

    try {
      final repo = ref.read(checkInRepositoryProvider);
      for (final g in _groups) {
        // Upload all photos for this group in parallel (supports both sources).
        final results = await Future.wait<String?>([
          for (final asset in g.assets) _uploadAsset(asset),
          for (final file in g.files) PhotoService().uploadFile(file),
        ]);
        final urls = [for (final u in results) if (u != null) u];

        await repo.createCheckIn(
          CheckInDraft(
            placeName: g.placeName,
            lat: g.lat,
            lng: g.lng,
            source: CheckInSource.photo,
            note: g.note.isEmpty ? null : g.note,
          ),
          photoUrls: urls,
          visitedAt: g.takenAt,
        );

        if (mounted) setState(() => _uploadedGroups++);
      }

      ref.invalidate(timelineNotifierProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<String?> _uploadAsset(AssetEntity asset) async {
    final file = await asset.originFile;
    if (file == null) return null;
    return PhotoService().uploadFile(file);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _groups.length == 1
              ? 'Review check-in'
              : 'Review check-ins (${_current + 1} / ${_groups.length})',
        ),
        actions: [
          TextButton(
            onPressed: _uploading ? null : _confirm,
            child: const Text('Add all'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: _groups.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (_, i) => _GroupPage(
                    group: _groups[i],
                    placeCtrl: _placeCtrl[i],
                    noteCtrl: _noteCtrl[i],
                    hasPrev: i > 0,
                    hasNext: i < _groups.length - 1,
                    canDelete: _groups.length > 1,
                    onMergeWithPrev: () => _merge(i - 1, i),
                    onMergeWithNext: () => _merge(i, i + 1),
                    onDelete: () => _deleteGroup(i),
                  ),
                ),
              ),
              // Page dots
              if (_groups.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _groups.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _current ? 10 : 6,
                          height: i == _current ? 10 : 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _current
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          // Upload overlay
          if (_uploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Adding check-in ${_uploadedGroups + 1} of ${_groups.length}…',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Single group slide ────────────────────────────────────────────────────────

class _GroupPage extends StatelessWidget {
  final InspectionGroup group;
  final TextEditingController placeCtrl;
  final TextEditingController noteCtrl;
  final bool hasPrev;
  final bool hasNext;
  final bool canDelete;
  final VoidCallback onMergeWithPrev;
  final VoidCallback onMergeWithNext;
  final VoidCallback onDelete;

  const _GroupPage({
    required this.group,
    required this.placeCtrl,
    required this.noteCtrl,
    required this.hasPrev,
    required this.hasNext,
    required this.canDelete,
    required this.onMergeWithPrev,
    required this.onMergeWithNext,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo thumbnails ──────────────────────────────────────────────
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: group.photoCount,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                if (i < group.assets.length) {
                  return _AssetThumb(asset: group.assets[i]);
                }
                return _FileThumb(file: group.files[i - group.assets.length]);
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${group.photoCount} photo${group.photoCount == 1 ? '' : 's'} · '
            '${DateFormat('EEE, MMM d · h:mm a').format(group.takenAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // ── Place name ────────────────────────────────────────────────────
          PlaceSearchField(
            controller: placeCtrl,
            lat: group.lat,
            lng: group.lng,
            labelText: 'Place',
          ),
          const SizedBox(height: 12),

          // ── Note ──────────────────────────────────────────────────────────
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.notes_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Merge ─────────────────────────────────────────────────────────
          if (hasPrev || hasNext) ...[
            Text('Merge with adjacent stop',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                if (hasPrev)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMergeWithPrev,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Previous'),
                    ),
                  ),
                if (hasPrev && hasNext) const SizedBox(width: 8),
                if (hasNext)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMergeWithNext,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Next'),
                      iconAlignment: IconAlignment.end,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Delete ────────────────────────────────────────────────────────
          if (canDelete)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                label: const Text('Remove this stop',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Asset thumbnail ───────────────────────────────────────────────────────────

class _AssetThumb extends StatefulWidget {
  final AssetEntity asset;
  const _AssetThumb({required this.asset});

  @override
  State<_AssetThumb> createState() => _AssetThumbState();
}

class _AssetThumbState extends State<_AssetThumb> {
  late final Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.asset.thumbnailDataWithSize(const ThumbnailSize(220, 220));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (_, snap) {
        if (snap.data == null) {
          return Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8)));
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(snap.data!,
              width: 110, height: 110, fit: BoxFit.cover),
        );
      },
    );
  }
}

// ── File thumbnail (shared from Photos.app) ───────────────────────────────────

class _FileThumb extends StatelessWidget {
  final File file;
  const _FileThumb({required this.file});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 110,
            height: 110,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
      );
}
