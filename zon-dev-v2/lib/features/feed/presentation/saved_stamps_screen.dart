import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/stamp.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../shared/widgets/app_states.dart';
import 'feed_screen.dart' show StampCard;

class SavedStampsScreen extends ConsumerStatefulWidget {
  const SavedStampsScreen({super.key});

  @override
  ConsumerState<SavedStampsScreen> createState() => _SavedStampsScreenState();
}

class _SavedStampsScreenState extends ConsumerState<SavedStampsScreen> {
  List<Stamp> _stamps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ref.read(stampRepositoryProvider).getSavedStamps();
    if (mounted) {
      setState(() {
        _stamps = res.getOrElse((_) => []);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: _loading
          ? const LoadingView()
          : _stamps.isEmpty
              ? const EmptyView(
                  icon: Icons.bookmark_border,
                  message: 'No saved stamps yet',
                  subtitle: 'Stamps you bookmark show up here.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _stamps.length,
                    itemBuilder: (ctx, i) => StampCard(stamp: _stamps[i]),
                  ),
                ),
    );
  }
}
