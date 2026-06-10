import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_profile.dart';

/// A user row: avatar, display name (falling back to username), and @handle.
/// Taps open the user's profile unless [onTap] overrides it; [trailing] adds
/// per-context actions (e.g. follow / confirm buttons).
class UserTile extends StatelessWidget {
  final UserProfile user;
  final Widget? trailing;
  final VoidCallback? onTap;
  const UserTile({super.key, required this.user, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(
        user.displayName?.isNotEmpty == true ? user.displayName! : user.username,
      ),
      subtitle: Text('@${user.username}'),
      onTap: onTap ?? () => context.push('/profile/${user.id}'),
      trailing: trailing,
    );
  }
}
