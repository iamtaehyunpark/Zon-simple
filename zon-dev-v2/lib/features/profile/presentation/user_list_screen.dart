import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/user_tile.dart';

/// Followers, following, or friends list for a user.
class UserListScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool followers;
  final bool friends;
  const UserListScreen({
    super.key,
    required this.userId,
    required this.followers,
    this.friends = false,
  });

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  List<UserProfile> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(profileRepositoryProvider);
    final users = widget.friends
        ? await repo.getFriends(widget.userId)
        : widget.followers
            ? await repo.getFollowers(widget.userId)
            : await repo.getFollowing(widget.userId);
    if (mounted) {
      setState(() {
        _users = users;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.friends
              ? 'Friends'
              : widget.followers
                  ? 'Followers'
                  : 'Following')),
      body: _loading
          ? const LoadingView()
          : _users.isEmpty
              ? EmptyView(
                  icon: Icons.people_outline,
                  message: widget.friends
                      ? 'No friends yet'
                      : widget.followers
                          ? 'No followers yet'
                          : 'Not following anyone yet',
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (ctx, i) => UserTile(user: _users[i]),
                ),
    );
  }
}
