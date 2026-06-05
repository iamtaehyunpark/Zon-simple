import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/enums.dart';
import 'photo_strip.dart';
import 'user_tag_field.dart';

class StampEditorBody extends ConsumerStatefulWidget {
  final StampDraft draft;
  final List<Stamp> nearbyStamps;
  final void Function(StampDraft) onUpdate;
  final VoidCallback onSave;

  const StampEditorBody({
    super.key,
    required this.draft,
    required this.nearbyStamps,
    required this.onUpdate,
    required this.onSave,
  });

  @override
  ConsumerState<StampEditorBody> createState() => _StampEditorBodyState();
}

class _StampEditorBodyState extends ConsumerState<StampEditorBody> {
  late TextEditingController _captionCtrl;
  late TextEditingController _placeNameCtrl;
  late StampDraft _draft;

  static const _sensoryOptions = [
    'Cozy', 'Lively', 'Quiet', 'Scenic', 'Crowded',
    'Romantic', 'Family-friendly', 'Trendy', 'Historic', 'Hidden gem',
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _captionCtrl = TextEditingController(text: _draft.caption);
    _placeNameCtrl = TextEditingController(text: _draft.placeName);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _placeNameCtrl.dispose();
    super.dispose();
  }

  void _update(StampDraft updated) {
    setState(() => _draft = updated);
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _placeNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Place name',
                    prefixIcon: Icon(Icons.place),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _update(_draft.copyWith(placeName: v)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _captionCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "What's the story?",
                    hintText: 'Write something about this place...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => _update(_draft.copyWith(caption: v)),
                ),
                const SizedBox(height: 16),
                Text('Photos', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_draft.existingPhotoUrls.isNotEmpty) ...[
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final url in _draft.existingPhotoUrls)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                  imageUrl: url,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Carried over from your check-in',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                ],
                PhotoStrip(
                  paths: _draft.selectedPhotoPaths,
                  onChanged: (p) => _update(_draft.copyWith(
                    selectedPhotoPaths: p,
                    coverPhotoPath: p.isNotEmpty ? p.first : null,
                  )),
                ),
                const SizedBox(height: 16),
                Text('Vibe', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _sensoryOptions.map((tag) {
                    final selected = _draft.sensoryTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (v) {
                        final tags = List<String>.from(_draft.sensoryTags);
                        v ? tags.add(tag) : tags.remove(tag);
                        _update(_draft.copyWith(sensoryTags: tags));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Visibility', style: Theme.of(context).textTheme.titleSmall),
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
                  selected: {_draft.visibility},
                  onSelectionChanged: (s) =>
                      _update(_draft.copyWith(visibility: s.first)),
                ),
                const SizedBox(height: 8),
                Text(
                  _draft.visibility == StampVisibility.private
                      ? 'Only you can see this stamp'
                      : 'Your followers can see this stamp',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text('Tag people',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                UserTagField(
                  taggedUserIds: _draft.taggedUserIds,
                  onChanged: (ids) =>
                      _update(_draft.copyWith(taggedUserIds: ids)),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed:
                  _placeNameCtrl.text.trim().isEmpty ? null : widget.onSave,
              child: const Text('Save Stamp'),
            ),
          ),
        ),
      ],
    );
  }
}

