import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/location_sharing_repository.dart';

class LocationVisibilityScreen extends ConsumerStatefulWidget {
  const LocationVisibilityScreen({super.key});

  @override
  ConsumerState<LocationVisibilityScreen> createState() =>
      _LocationVisibilityScreenState();
}

class _LocationVisibilityScreenState
    extends ConsumerState<LocationVisibilityScreen> {
  List<UserProfile> _friends = [];
  Set<String> _hiddenFrom = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profileRepo = ref.read(profileRepositoryProvider);
    final locRepo = ref.read(locationSharingRepositoryProvider);
    final myId = ref.read(profileRepositoryProvider).userId ?? '';

    final (friends, hidden) = await (
      profileRepo.getFriends(myId),
      locRepo.getHiddenFromIds(),
    ).wait;

    if (!mounted) return;
    setState(() {
      _friends = friends;
      _hiddenFrom = hidden;
      _loading = false;
    });
  }

  Future<void> _toggle(String friendId, bool currentlyHidden) async {
    final repo = ref.read(locationSharingRepositoryProvider);
    setState(() {
      if (currentlyHidden) {
        _hiddenFrom.remove(friendId);
      } else {
        _hiddenFrom.add(friendId);
      }
    });
    if (currentlyHidden) {
      await repo.showToFriend(friendId);
    } else {
      await repo.hideFromFriend(friendId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Who can see my location')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No friends yet',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Your location is visible to all mutual friends by default. '
                        'Toggle off to hide from a specific friend.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (ctx, i) {
                          final friend = _friends[i];
                          final isHidden = _hiddenFrom.contains(friend.id);
                          return SwitchListTile(
                            secondary: CircleAvatar(
                              radius: 20,
                              backgroundImage: friend.avatarUrl != null
                                  ? CachedNetworkImageProvider(
                                      friend.avatarUrl!)
                                  : null,
                              child: friend.avatarUrl == null
                                  ? Text(
                                      friend.username[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 14),
                                    )
                                  : null,
                            ),
                            title: Text(friend.displayName ?? friend.username),
                            subtitle: Text('@${friend.username}'),
                            value: !isHidden,
                            onChanged: (_) => _toggle(friend.id, isHidden),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
