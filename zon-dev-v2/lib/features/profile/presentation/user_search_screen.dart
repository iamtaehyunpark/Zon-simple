import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _ctrl = TextEditingController();
  List<UserProfile> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
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
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (v) {
            if (v.trim().length >= 2) _search(v);
          },
          onSubmitted: _search,
          decoration: const InputDecoration(
            hintText: 'Search people…',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (ctx, i) {
          final u = _results[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: u.avatarUrl != null
                  ? CachedNetworkImageProvider(u.avatarUrl!)
                  : null,
              child: u.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(u.displayName?.isNotEmpty == true
                ? u.displayName!
                : u.username),
            subtitle: Text('@${u.username}'),
            onTap: () => context.push('/profile/${u.id}'),
          );
        },
      ),
    );
  }
}
