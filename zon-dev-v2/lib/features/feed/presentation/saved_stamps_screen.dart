import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/stamp.dart';
import '../../../data/repositories/stamp_repository.dart';
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
          ? const Center(child: CircularProgressIndicator())
          : _stamps.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No saved stamps yet'),
                    ],
                  ),
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
