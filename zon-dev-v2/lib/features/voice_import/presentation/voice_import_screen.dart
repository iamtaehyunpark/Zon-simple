import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/audio/voice_memo_service.dart';
import '../../../core/sharing/shared_voice_service.dart';
import '../../../data/repositories/timeline_note_repository.dart';
import '../../../features/timeline/presentation/providers/timeline_provider.dart';
import '../../../shared/theme/app_theme.dart';

/// One shared recording being reviewed before it lands on the timeline.
class _ImportItem {
  final File file;
  final TextEditingController transcript;
  DateTime recordedAt;
  bool transcribing;
  bool include;
  _ImportItem(this.file, this.recordedAt)
      : transcript = TextEditingController(),
        transcribing = true,
        include = true;
}

/// Batch-import shared voice memos. Mirrors the photo check-in inspection flow:
/// review each item (transcript + date/time), then commit them all to the
/// timeline as voice/note nodes. No coordinates — date + time + audio only.
class VoiceImportScreen extends ConsumerStatefulWidget {
  final List<SharedVoiceMemo> memos;
  const VoiceImportScreen({super.key, required this.memos});

  @override
  ConsumerState<VoiceImportScreen> createState() => _VoiceImportScreenState();
}

class _VoiceImportScreenState extends ConsumerState<VoiceImportScreen> {
  final _service = VoiceMemoService();
  final _player = AudioPlayer();
  late final List<_ImportItem> _items;
  StreamSubscription<void>? _completeSub;
  String? _playingPath;
  bool _saving = false;
  int _saved = 0;

  @override
  void initState() {
    super.initState();
    // recordedAt comes from the Share Extension (the recording's real date).
    _items = [
      for (final m in widget.memos) _ImportItem(File(m.path), m.recordedAt),
    ];
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingPath = null);
    });
    _transcribeAll();
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    for (final i in _items) {
      i.transcript.dispose();
    }
    _player.dispose();
    _service.dispose();
    super.dispose();
  }

  // Transcribe sequentially — the on-device recognizer handles one file at a time.
  Future<void> _transcribeAll() async {
    for (final item in _items) {
      final text = await _service.transcribe(item.file);
      if (!mounted) return;
      setState(() {
        item.transcript.text = text;
        item.transcribing = false;
      });
    }
  }

  Future<void> _togglePlay(_ImportItem item) async {
    if (_playingPath == item.file.path) {
      await _player.stop();
      if (mounted) setState(() => _playingPath = null);
    } else {
      await _player.stop();
      await _player.play(DeviceFileSource(item.file.path));
      if (mounted) setState(() => _playingPath = item.file.path);
    }
  }

  Future<void> _pickDateTime(_ImportItem item) async {
    final date = await showDatePicker(
      context: context,
      initialDate: item.recordedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(item.recordedAt),
    );
    if (!mounted) return;
    setState(() {
      item.recordedAt = DateTime(date.year, date.month, date.day,
          time?.hour ?? item.recordedAt.hour, time?.minute ?? item.recordedAt.minute);
    });
  }

  Future<void> _save() async {
    final chosen = _items.where((i) => i.include).toList();
    if (chosen.isEmpty) return;
    setState(() {
      _saving = true;
      _saved = 0;
    });
    final repo = ref.read(timelineNoteRepositoryProvider);
    final affectedDays = <DateTime>{};
    for (final item in chosen) {
      final url = await _service.upload(item.file);
      if (url == null) continue; // skip on upload failure, keep going
      final text = item.transcript.text.trim();
      final body = text.isEmpty ? '🎙 Voice memo' : text;
      final day = DateTime(
          item.recordedAt.year, item.recordedAt.month, item.recordedAt.day);
      await repo.add(day, body, item.recordedAt, audioUrl: url);
      affectedDays.add(day);
      // Drop the copy out of the App Group container now it's uploaded.
      try {
        await item.file.delete();
      } catch (_) {}
      if (mounted) setState(() => _saved++);
    }

    // Refresh the timeline if the user is sitting on one of the days we touched.
    final current = ref.read(timelineNotifierProvider).valueOrNull?.date;
    if (current != null && affectedDays.contains(current)) {
      ref.read(timelineNotifierProvider.notifier).loadDay(current);
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
        content: Text('Added $_saved voice ${_saved == 1 ? 'memo' : 'memos'} to your timeline')));
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final count = _items.where((i) => i.include).length;
    return Scaffold(
      backgroundColor: Z.surface0,
      appBar: AppBar(
        backgroundColor: Z.surface1,
        title: Text('Import ${_items.length} voice ${_items.length == 1 ? 'memo' : 'memos'}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => context.canPop() ? context.pop() : null,
        ),
      ),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ImportCard(
              item: _items[i],
              playing: _playingPath == _items[i].file.path,
              onPlay: () => _togglePlay(_items[i]),
              onPickTime: () => _pickDateTime(_items[i]),
              onToggleInclude: (v) => setState(() => _items[i].include = v),
            ),
          ),
          if (_saving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Z.brand),
                    const SizedBox(height: 16),
                    Text('Adding ${_saved + 1} of $count…',
                        style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomSheet: _saving
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Z.brand,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: count == 0 ? null : _save,
                    child: Text(
                      count == 0
                          ? 'Select at least one'
                          : 'Add $count to timeline',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  final _ImportItem item;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onPickTime;
  final ValueChanged<bool> onToggleInclude;
  const _ImportCard({
    required this.item,
    required this.playing,
    required this.onPlay,
    required this.onPickTime,
    required this.onToggleInclude,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Z.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: item.include ? Z.brand.withValues(alpha: 0.4) : Z.outline),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onPlay,
                child: Icon(
                    playing ? Icons.stop_circle : Icons.play_circle_fill,
                    size: 36,
                    color: Z.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onPickTime,
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 15, color: Z.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        DateFormat('MMM d, H:mm').format(item.recordedAt),
                        style: const TextStyle(
                            fontSize: 13,
                            color: Z.text,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 13, color: Z.textFaint),
                    ],
                  ),
                ),
              ),
              Checkbox(
                value: item.include,
                activeColor: Z.brand,
                onChanged: (v) => onToggleInclude(v ?? false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (item.transcribing)
            const Row(
              children: [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Transcribing…',
                    style: TextStyle(fontSize: 13, color: Z.textMuted)),
              ],
            )
          else
            TextField(
              controller: item.transcript,
              maxLines: null,
              minLines: 1,
              style: const TextStyle(fontSize: 14, color: Z.text, height: 1.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'No speech detected — add a note',
                hintStyle: const TextStyle(color: Z.textFaint),
                filled: true,
                fillColor: Z.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }
}
