import 'package:flutter/material.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/place_search_field.dart';
import 'photo_strip.dart';
import 'user_tag_field.dart';

/// Lightweight editor for a check-in: place name + optional note + optional
/// photos. (Tagging is added in Phase 5.)
class CheckInEditorBody extends StatefulWidget {
  final CheckInDraft draft;
  final void Function(CheckInDraft) onUpdate;
  final VoidCallback onSave;

  const CheckInEditorBody({
    super.key,
    required this.draft,
    required this.onUpdate,
    required this.onSave,
  });

  @override
  State<CheckInEditorBody> createState() => _CheckInEditorBodyState();
}

class _CheckInEditorBodyState extends State<CheckInEditorBody> {
  late TextEditingController _placeCtrl;
  late TextEditingController _noteCtrl;
  late CheckInDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _placeCtrl = TextEditingController(text: _draft.placeName);
    _noteCtrl = TextEditingController(text: _draft.note);
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _update(CheckInDraft updated) {
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
                PlaceSearchField(
                  controller: _placeCtrl,
                  lat: _draft.lat,
                  lng: _draft.lng,
                  labelText: 'Place name',
                  onChanged: (v) => _update(_draft.copyWith(placeName: v)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'A quick note about this visit...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => _update(_draft.copyWith(note: v)),
                ),
                const SizedBox(height: 16),
                Text('Photos (optional)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                PhotoStrip(
                  paths: _draft.photoPaths,
                  onChanged: (p) => _update(_draft.copyWith(photoPaths: p)),
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
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Share as a story'),
                  subtitle: const Text(
                      'Public for 24h in your followers’ feed. Off = private trace.'),
                  value: _draft.visibility == StampVisibility.public,
                  onChanged: (v) => _update(_draft.copyWith(
                    visibility:
                        v ? StampVisibility.public : StampVisibility.private,
                  )),
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
              onPressed: _placeCtrl.text.trim().isEmpty ? null : widget.onSave,
              child: const Text('Check in'),
            ),
          ),
        ),
      ],
    );
  }
}
