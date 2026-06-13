import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';

/// Present the user picker and return the chosen profile (or null).
Future<UserProfile?> showUserPicker(BuildContext context) =>
    showModalBottomSheet<UserProfile>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _UserPickerSheet(),
    );

/// Tag people (Instagram-style). Emits the selected user ids via [onChanged];
/// keeps usernames locally just for the chips.
class UserTagField extends ConsumerStatefulWidget {
  final List<String> taggedUserIds;
  final ValueChanged<List<String>> onChanged;
  const UserTagField({
    super.key,
    required this.taggedUserIds,
    required this.onChanged,
  });

  @override
  ConsumerState<UserTagField> createState() => _UserTagFieldState();
}

class _UserTagFieldState extends ConsumerState<UserTagField> {
  final Map<String, String> _names = {}; // id -> username

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  @override
  void didUpdateWidget(UserTagField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.taggedUserIds != oldWidget.taggedUserIds) {
      _loadNames();
    }
  }

  Future<void> _loadNames() async {
    final ids = widget.taggedUserIds.where((id) => !_names.containsKey(id)).toList();
    if (ids.isEmpty) return;
    try {
      final profiles = await ref.read(profileRepositoryProvider).getProfilesByIds(ids);
      if (mounted) {
        setState(() {
          for (final p in profiles) {
            _names[p.id] = p.username;
          }
        });
      }
    } catch (e) {
      debugPrint('[UserTagField] failed to load tagged user names: $e');
    }
  }

  Future<void> _pick() async {
    final picked = await showModalBottomSheet<UserProfile>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _UserPickerSheet(),
    );
    if (picked == null) return;
    if (widget.taggedUserIds.contains(picked.id)) return;
    setState(() => _names[picked.id] = picked.username);
    widget.onChanged([...widget.taggedUserIds, picked.id]);
  }

  void _remove(String id) {
    setState(() => _names.remove(id));
    widget.onChanged(widget.taggedUserIds.where((e) => e != id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final id in widget.taggedUserIds)
          Chip(
            label: Text('@${_names[id] ?? 'user'}'),
            onDeleted: () => _remove(id),
          ),
        ActionChip(
          avatar: const Icon(Icons.person_add_alt, size: 18),
          label: const Text('Tag people'),
          onPressed: _pick,
        ),
      ],
    );
  }
}

class _UserPickerSheet extends ConsumerStatefulWidget {
  const _UserPickerSheet();

  @override
  ConsumerState<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends ConsumerState<_UserPickerSheet> {
  List<UserProfile> _results = [];
  bool _searching = false;

  Future<void> _search(String q) async {
    if (q.trim().length < 2) return;
    setState(() => _searching = true);
    final results = await ref.read(profileRepositoryProvider).searchUsers(q);
    if (mounted) {
      setState(() {
        _results = results;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Search people…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final u = _results[i];
                return ListTile(
                  title: Text('@${u.username}'),
                  onTap: () => Navigator.pop(context, u),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
