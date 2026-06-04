import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/photos/photo_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/stamp_repository.dart';

class EditStampScreen extends ConsumerStatefulWidget {
  final String stampId;
  const EditStampScreen({super.key, required this.stampId});

  @override
  ConsumerState<EditStampScreen> createState() => _EditStampScreenState();
}

class _EditStampScreenState extends ConsumerState<EditStampScreen> {
  static const _sensoryOptions = [
    'Cozy', 'Lively', 'Quiet', 'Scenic', 'Crowded',
    'Romantic', 'Family-friendly', 'Trendy', 'Historic', 'Hidden gem',
  ];

  final _placeCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  List<({String id, String url})> _existing = [];
  final Set<String> _removedIds = {};
  final List<String> _newPaths = [];
  List<String> _tags = [];
  StampVisibility _visibility = StampVisibility.private;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(stampRepositoryProvider);
    final stampRes = await repo.getStamp(widget.stampId);
    final photos = await repo.getStampPhotos(widget.stampId);
    stampRes.fold((_) {}, (s) {
      _placeCtrl.text = s.placeName;
      _captionCtrl.text = s.caption ?? '';
      _tags = List.of(s.sensoryTags);
      _visibility = s.visibility;
    });
    if (mounted) {
      setState(() {
        _existing = photos;
        _loading = false;
      });
    }
  }

  Future<void> _addPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    setState(() => _newPaths.addAll(picked.map((x) => x.path)));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(stampRepositoryProvider);
    final photoService = PhotoService();

    for (final id in _removedIds) {
      await repo.deletePhoto(id);
    }
    final newUrls = <String>[];
    for (final p in _newPaths) {
      final u = await photoService.uploadFile(File(p));
      if (u != null) newUrls.add(u);
    }
    await repo.addStampPhotos(widget.stampId, newUrls);

    final remaining =
        _existing.where((e) => !_removedIds.contains(e.id)).toList();
    final cover = remaining.isNotEmpty
        ? remaining.first.url
        : (newUrls.isNotEmpty ? newUrls.first : null);

    await repo.updateStamp(widget.stampId, {
      'place_name': _placeCtrl.text.trim(),
      'normalized_place_name': _placeCtrl.text.trim().toLowerCase(),
      'caption': _captionCtrl.text.trim(),
      'sensory_tags': _tags,
      'visibility': _visibility.name,
      'cover_photo_url': cover,
    });

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        _existing.where((e) => !_removedIds.contains(e.id)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Stamp'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _placeCtrl.text.trim().isEmpty ? null : _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _placeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Place name',
                      prefixIcon: Icon(Icons.place),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _captionCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "What's the story?",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Photos', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 88,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        GestureDetector(
                          onTap: _addPhotos,
                          child: Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined,
                                color: Colors.grey),
                          ),
                        ),
                        for (final e in remaining)
                          _Thumb(
                            child: CachedNetworkImage(
                                imageUrl: e.url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover),
                            onRemove: () =>
                                setState(() => _removedIds.add(e.id)),
                          ),
                        for (int i = 0; i < _newPaths.length; i++)
                          _Thumb(
                            child: Image.file(File(_newPaths[i]),
                                width: 80, height: 80, fit: BoxFit.cover),
                            onRemove: () =>
                                setState(() => _newPaths.removeAt(i)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Vibe', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _sensoryOptions.map((tag) {
                      final selected = _tags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          v ? _tags.add(tag) : _tags.remove(tag);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Visibility',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<StampVisibility>(
                    segments: const [
                      ButtonSegment(
                        value: StampVisibility.private,
                        label: Text('Private'),
                        icon: Icon(Icons.lock),
                      ),
                      ButtonSegment(
                        value: StampVisibility.public,
                        label: Text('Public'),
                        icon: Icon(Icons.public),
                      ),
                    ],
                    selected: {_visibility},
                    onSelectionChanged: (s) =>
                        setState(() => _visibility = s.first),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  const _Thumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
