import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/diary_repository.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/utils/format.dart';
import 'providers/profile_provider.dart';
import '../../../core/auth/auth_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/photos/photo_service.dart';

// ── Profile Screen — zon-screens-sub.jsx ProfileScreen ───────────────────────
class ProfileScreen extends ConsumerWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final targetId = userId ?? currentUser?.id;
    if (targetId == null) return const Scaffold(body: LoadingView());

    final isOwnProfile = targetId == currentUser?.id;
    final profileState = ref.watch(profileNotifierProvider(targetId));

    return profileState.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) =>
          Scaffold(body: ErrorView(message: errorMessage(e))),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
              body: EmptyView(
                  icon: Icons.person_off_outlined,
                  message: 'Profile not found'));
        }

        final canView = isOwnProfile ||
            !profile.isPrivate ||
            (ref.watch(followStateProvider(targetId)).valueOrNull ??
                    FollowState.none) ==
                FollowState.following ||
            (ref.watch(friendStateProvider(targetId)).valueOrNull ??
                    FriendState.none) ==
                FriendState.friends;

        final tabCount = isOwnProfile ? 3 : 2;

        return DefaultTabController(
          length: tabCount,
          child: Scaffold(
            backgroundColor: Z.surface0,
            body: Column(
              children: [
                // ── Header block (surface1) ──────────────────────────
                Container(
                  color: Z.surface1,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // AppBar row: username + settings/more
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
                          child: SizedBox(
                            height: 44,
                            child: Row(
                              children: [
                                if (!isOwnProfile)
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: const Icon(Icons.arrow_back,
                                        size: 24, color: Z.text),
                                  ),
                                if (!isOwnProfile)
                                  const SizedBox(width: 8),
                                Expanded(
                                  child: Text('@${profile.username}',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Z.text)),
                                ),
                                if (isOwnProfile)
                                  GestureDetector(
                                    onTap: () => context.push('/activity'),
                                    child: const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.notifications_outlined,
                                        size: 22,
                                        color: Z.text,
                                      ),
                                    ),
                                  ),
                                if (isOwnProfile)
                                  GestureDetector(
                                    onTap: () => context.push('/check-ins'),
                                    child: const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.place_outlined,
                                        size: 22,
                                        color: Z.text,
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () => isOwnProfile
                                      ? context.push('/settings')
                                      : null,
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      isOwnProfile
                                          ? Icons.settings
                                          : Icons.more_vert,
                                      size: 22,
                                      color: Z.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Z.outline),

                        // Identity row: small avatar + name + edit/friend buttons
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 58,
                                height: 58,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Z.surface2),
                                clipBehavior: Clip.antiAlias,
                                child: profile.avatarUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: profile.avatarUrl!,
                                        fit: BoxFit.cover)
                                    : Center(
                                        child: Text(
                                          (profile.displayName?.isNotEmpty ==
                                                  true
                                              ? profile.displayName![0]
                                              : profile.username[0])
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: Z.textMuted),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.displayName?.isNotEmpty == true
                                          ? profile.displayName!
                                          : profile.username,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Z.text,
                                          height: 1.2),
                                    ),
                                    if (profile.bio != null &&
                                        profile.bio!.isNotEmpty)
                                      Text(profile.bio!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Z.textMuted,
                                              height: 1.4),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Action buttons
                              if (isOwnProfile)
                                _OutlineBtn(
                                    label: 'Edit',
                                    onTap: () {
                                      showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Z.surface1,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(24)),
                                        ),
                                        builder: (_) => _EditProfileSheet(profile: profile),
                                      );
                                    })
                              else
                                _SocialButtons(targetId: targetId),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Z.outline),

                        // Stats: Stamps · Friends · Followers
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              _StatItem(
                                  label: 'Stamps',
                                  value: profile.stampCount),
                              _vDivider(),
                              _StatItem(
                                  label: 'Friends',
                                  value: profile.friendCount,
                                  onTap: () => context
                                      .push('/profile/$targetId/friends')),
                              _vDivider(),
                              _StatItem(
                                  label: 'Followers',
                                  value: profile.followerCount,
                                  onTap: () => context
                                      .push('/profile/$targetId/followers')),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Z.outline),

                        // Tab switcher: Stamps | Saved | Diaries
                        TabBar(
                          labelStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          unselectedLabelStyle:
                              const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                          labelColor: Z.brand,
                          unselectedLabelColor: Z.textMuted,
                          indicatorColor: Z.brand,
                          indicatorWeight: 2.5,
                          tabs: [
                            const Tab(text: 'Stamps'),
                            if (isOwnProfile) const Tab(text: 'Saved'),
                            const Tab(text: 'Diaries'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tab content ───────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    children: [
                      // Stamps
                      !canView
                          ? const _LockedGrid()
                          : _StampsGrid(
                              targetId: targetId,
                              isOwnProfile: isOwnProfile),
                      // Saved
                      if (isOwnProfile)
                        !canView
                            ? const _LockedGrid()
                            : _StampsGrid(
                                targetId: targetId,
                                isOwnProfile: isOwnProfile,
                                savedOnly: true),
                      // Diaries
                      _DiariesTab(
                          userId: targetId,
                          isOwnProfile: isOwnProfile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _vDivider() => const VerticalDivider(
        width: 1, thickness: 1, color: Z.outline, indent: 12, endIndent: 12);
}

// ── Stat item ─────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;
  const _StatItem({required this.label, required this.value, this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(compactCount(value),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Z.brand,
                        height: 1.15)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Z.textMuted)),
              ],
            ),
          ),
        ),
      );
}

// ── Outline button helper ─────────────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
              border: Border.all(color: Z.outline2, width: 1.5),
              borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Z.text)),
        ),
      );
}

enum _FriendAction { unfriend }

// ── Social buttons (Add Friend + Follow) ──────────────────────────────────────
class _SocialButtons extends ConsumerStatefulWidget {
  final String targetId;
  const _SocialButtons({required this.targetId});

  @override
  ConsumerState<_SocialButtons> createState() => _SocialButtonsState();
}

class _SocialButtonsState extends ConsumerState<_SocialButtons> {
  bool _friendLoading = false;
  bool _followLoading = false;

  void _showRespondMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Confirm'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                setState(() => _friendLoading = true);
                try {
                  final res = await ref
                      .read(profileRepositoryProvider)
                      .acceptFriendRequest(widget.targetId);
                  res.fold(
                    (err) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to accept request: ${err.message}')),
                      );
                    },
                    (_) {
                      ref.invalidate(friendStateProvider(widget.targetId));
                      ref.invalidate(friendRequestsProvider);
                    },
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error accepting request: $e')),
                  );
                } finally {
                  if (mounted) setState(() => _friendLoading = false);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text('Delete'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                setState(() => _friendLoading = true);
                try {
                  final res = await ref
                      .read(profileRepositoryProvider)
                      .denyFriendRequest(widget.targetId);
                  res.fold(
                    (err) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to deny request: ${err.message}')),
                      );
                    },
                    (_) {
                      ref.invalidate(friendStateProvider(widget.targetId));
                      ref.invalidate(friendRequestsProvider);
                    },
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error denying request: $e')),
                  );
                } finally {
                  if (mounted) setState(() => _friendLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Run a social mutation with a loading flag, surfacing failures as a snackbar.
  Future<void> _run(
    Future<void> Function() action,
    String errorLabel, {
    required bool friend,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => friend ? _friendLoading = true : _followLoading = true);
    try {
      await action();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$errorLabel: $e')));
    } finally {
      if (mounted) {
        setState(() => friend ? _friendLoading = false : _followLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = ref.watch(friendStateProvider(widget.targetId)).valueOrNull ??
        FriendState.none;
    final fw = ref.watch(followStateProvider(widget.targetId)).valueOrNull ??
        FollowState.none;
    final notifier = ref.read(profileNotifierProvider(widget.targetId).notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Friend button
        if (fs == FriendState.friends)
          PopupMenuButton<_FriendAction>(
            enabled: !_friendLoading,
            onSelected: (a) {
              if (a == _FriendAction.unfriend) {
                _run(notifier.unfriend, 'Failed to unfriend', friend: true);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _FriendAction.unfriend,
                child: Text('Unfriend'),
              ),
            ],
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Z.surface2,
                border: Border.all(color: Z.outline2, width: 1.5),
                borderRadius: BorderRadius.circular(9999),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _friendLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Z.text,
                        ),
                      )
                    : const Text(
                        'Friends',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Z.text),
                      ),
              ),
            ),
          )
        else
          GestureDetector(
            onTap: _friendLoading
                ? null
                : () {
                    if (fs == FriendState.none) {
                      _run(notifier.sendFriendRequest,
                          'Failed to send friend request', friend: true);
                    } else if (fs == FriendState.requestedByMe) {
                      _run(notifier.cancelFriendRequest,
                          'Failed to cancel request', friend: true);
                    } else if (fs == FriendState.requestedByThem) {
                      _showRespondMenu(context, ref);
                    }
                  },
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Z.brand,
                borderRadius: BorderRadius.circular(9999),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _friendLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        fs == FriendState.requestedByMe
                            ? 'Requested'
                            : fs == FriendState.requestedByThem
                                ? 'Respond'
                                : '+ Friend',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
              ),
            ),
          ),
        const SizedBox(width: 7),
        // Follow button
        GestureDetector(
          onTap: _followLoading
              ? null
              : () => _run(() => notifier.toggleFollow(widget.targetId),
                  'Failed to update follow status', friend: false),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Z.outline2, width: 1.5),
              borderRadius: BorderRadius.circular(9999),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _followLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Z.text,
                      ),
                    )
                  : Text(
                      fw == FollowState.following
                          ? 'Following'
                          : fw == FollowState.requested
                              ? 'Requested'
                              : 'Follow',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Z.text),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Locked grid (private account) ─────────────────────────────────────────────
class _LockedGrid extends StatelessWidget {
  const _LockedGrid();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Z.textFaint),
              SizedBox(height: 12),
              Text('This account is private',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Z.text)),
              SizedBox(height: 4),
              Text('Follow to see their stamps',
                  style: TextStyle(color: Z.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );
}

final _profileSavedStampsProvider = FutureProvider.autoDispose<List<Stamp>>((ref) async {
  final res = await ref.watch(stampRepositoryProvider).getSavedStamps();
  return res.fold((err) => throw err, (stamps) => stamps);
});

// ── Stamp grid (stamps tab + saved tab) ───────────────────────────────────────
class _StampsGrid extends ConsumerWidget {
  final String targetId;
  final bool isOwnProfile;
  final bool savedOnly;
  const _StampsGrid({
    required this.targetId,
    required this.isOwnProfile,
    this.savedOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (savedOnly) {
      final savedState = ref.watch(_profileSavedStampsProvider);
      return savedState.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
        data: (stamps) {
          if (stamps.isEmpty) {
            return const EmptyView(
              icon: Icons.bookmark_border,
              message: 'No saved stamps yet',
              subtitle: 'Stamps you bookmark show up here.',
            );
          }
          return GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2),
            itemCount: stamps.length,
            itemBuilder: (ctx, i) {
              return _GridItem(stamp: stamps[i], isOwnProfile: isOwnProfile);
            },
          );
        },
      );
    }

    final stampsState = ref.watch(
        profileStampsNotifierProvider(targetId, publicOnly: !isOwnProfile));
    return stampsState.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: errorMessage(e)),
      data: (stamps) {
        if (stamps.isEmpty) {
          return EmptyView(
            icon: Icons.auto_awesome_outlined,
            message: isOwnProfile ? 'No stamps yet' : 'No public stamps yet',
            action: isOwnProfile
                ? FilledButton.icon(
                    onPressed: () =>
                        context.push('/checkin?mode=stamp'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create a stamp'),
                  )
                : null,
          );
        }
        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2),
          itemCount: stamps.length,
          itemBuilder: (ctx, i) {
            if (i == stamps.length - 3) {
              ref
                  .read(profileStampsNotifierProvider(targetId,
                          publicOnly: !isOwnProfile)
                      .notifier)
                  .loadMore(targetId, publicOnly: !isOwnProfile);
            }
            return _GridItem(stamp: stamps[i], isOwnProfile: isOwnProfile);
          },
        );
      },
    );
  }
}

class _GridItem extends StatelessWidget {
  final Stamp stamp;
  final bool isOwnProfile;
  const _GridItem({required this.stamp, required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/stamp/${stamp.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          stamp.coverPhotoUrl != null
              ? CachedNetworkImage(
                  imageUrl: stamp.coverPhotoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const ColoredBox(color: Z.surface2),
                )
              : Container(
                  color: Z.surface2,
                  alignment: Alignment.center,
                  child: Text(stamp.placeName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: Z.textMuted)),
                ),
          // Private stamp lock badge
          if (isOwnProfile && stamp.visibility == StampVisibility.private)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0x72000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock,
                    size: 11, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Diaries tab ───────────────────────────────────────────────────────────────
class _DiariesTab extends ConsumerStatefulWidget {
  final String userId;
  final bool isOwnProfile;
  const _DiariesTab(
      {required this.userId, required this.isOwnProfile});

  @override
  ConsumerState<_DiariesTab> createState() => _DiariesTabState();
}

class _DiariesTabState extends ConsumerState<_DiariesTab>
    with AutomaticKeepAliveClientMixin {
  List<({DateTime date, String body})> _entries = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.isOwnProfile) {
      _load();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    final entries =
        await ref.read(diaryRepositoryProvider).getDiaries();
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!widget.isOwnProfile) {
      return const Center(
          child: Text('Diaries are private',
              style: TextStyle(color: Z.textMuted)));
    }
    if (_loading) return const LoadingView();
    if (_entries.isEmpty) {
      return const EmptyView(
          icon: Icons.book_outlined,
          message: 'No diary entries yet',
          subtitle:
              'Use the Timeline tab to generate your first diary.');
    }
    return RefreshIndicator(
      color: Z.brand,
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _entries.length,
        itemBuilder: (ctx, i) {
          final e = _entries[i];
          return Container(
            decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Z.outline))),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, MMM d').format(e.date).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Z.brand,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(e.body,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Z.text,
                        height: 1.72,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Edit Profile Sheet ────────────────────────────────────────────────────────
class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _EditProfileSheet({required this.profile});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _bioCtrl;
  String? _avatarUrl;
  bool _uploadingAvatar = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController(text: widget.profile.displayName ?? '');
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? '');
    _avatarUrl = widget.profile.avatarUrl;
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final url = await PhotoService().uploadFile(File(picked.path), bucket: 'avatars');
      if (url != null) {
        setState(() {
          _avatarUrl = url;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);
    final res = await repo.updateProfile({
      'display_name': _displayNameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'avatar_url': _avatarUrl,
    });
    
    res.fold(
      (err) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile: ${err.message}')),
          );
        }
      },
      (updatedProfile) {
        if (mounted) {
          ref.invalidate(profileNotifierProvider(widget.profile.id));
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Z.text),
              ),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Z.outline,
                      backgroundImage: _avatarUrl != null
                          ? CachedNetworkImageProvider(_avatarUrl!)
                          : null,
                      child: _avatarUrl == null
                          ? const Icon(Icons.person, size: 40, color: Z.textMuted)
                          : null,
                    ),
                    if (_uploadingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploadingAvatar || _saving ? null : _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Z.brand,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _displayNameCtrl,
                style: const TextStyle(fontSize: 14, color: Z.text),
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  labelStyle: TextStyle(color: Z.textMuted),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Z.brand, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, color: Z.text),
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: Z.textMuted),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Z.brand, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving || _uploadingAvatar ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: Z.brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Z.brandSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

