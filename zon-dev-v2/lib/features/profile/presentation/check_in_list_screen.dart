import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/check_in_repository.dart';

class CheckInListScreen extends ConsumerStatefulWidget {
  const CheckInListScreen({super.key});

  @override
  ConsumerState<CheckInListScreen> createState() => _CheckInListScreenState();
}

class _CheckInListScreenState extends ConsumerState<CheckInListScreen> {
  List<CheckIn> _checkIns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ref.read(checkInRepositoryProvider).getMyCheckIns();
    if (mounted) {
      setState(() {
        _checkIns = res.getOrElse((_) => []);
        _loading = false;
      });
    }
  }

  Future<void> _promote(CheckIn checkIn) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PromoteSheet(checkIn: checkIn),
    );
    if (result != null && mounted) context.push('/stamp/$result');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My check-ins')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _checkIns.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pin_drop_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No check-ins yet'),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _checkIns.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final c = _checkIns[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(ctx).colorScheme.primaryContainer,
                        child: const Icon(Icons.place),
                      ),
                      title: Text(c.placeName),
                      subtitle: Text(
                        '${DateFormat('EEE, MMM d').format(c.visitedAt)}'
                        '${c.photoCount > 0 ? ' · ${c.photoCount} photo${c.photoCount == 1 ? '' : 's'}' : ''}',
                      ),
                      trailing: TextButton(
                        onPressed: () => _promote(c),
                        child: const Text('Make stamp'),
                      ),
                      onTap: () => _promote(c),
                    );
                  },
                ),
    );
  }
}

class _PromoteSheet extends ConsumerStatefulWidget {
  final CheckIn checkIn;
  const _PromoteSheet({required this.checkIn});

  @override
  ConsumerState<_PromoteSheet> createState() => _PromoteSheetState();
}

class _PromoteSheetState extends ConsumerState<_PromoteSheet> {
  final _captionCtrl = TextEditingController();
  StampVisibility _visibility = StampVisibility.public;
  bool _saving = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _saving = true);
    final res = await ref.read(checkInRepositoryProvider).promoteToStamp(
          widget.checkIn.id,
          visibility: _visibility,
          caption: _captionCtrl.text.trim(),
        );
    res.fold(
      (err) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err.toString())));
      },
      (stampId) => Navigator.pop(context, stampId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Make a stamp from "${widget.checkIn.placeName}"',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _captionCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "What's the story? (optional)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<StampVisibility>(
            segments: const [
              ButtonSegment(
                  value: StampVisibility.private,
                  label: Text('Private'),
                  icon: Icon(Icons.lock)),
              ButtonSegment(
                  value: StampVisibility.public,
                  label: Text('Public'),
                  icon: Icon(Icons.public)),
            ],
            selected: {_visibility},
            onSelectionChanged: (s) => setState(() => _visibility = s.first),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _saving ? null : _create,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create stamp'),
            ),
          ),
        ],
      ),
    );
  }
}
