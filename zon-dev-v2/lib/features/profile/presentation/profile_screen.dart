import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/diary_repository.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/mini_map.dart';
import '../../../shared/utils/format.dart';
import 'providers/profile_provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/location/providers/gps_provider.dart';
import 'dart:io';
import 'dart:math' show cos, pi;
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

        // Map · Stamps · [Saved] · Diaries
        final tabCount = isOwnProfile ? 4 : 3;

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
                                Text('ZON',
                                    style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: Z.text)),
                                if (!isOwnProfile) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: const Icon(Icons.arrow_back,
                                        size: 24, color: Z.text),
                                  ),
                                ],
                                const Spacer(),
                                if (isOwnProfile) ...[
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
                                    onTap: () => context.push('/settings'),
                                    child: const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.settings,
                                        size: 22,
                                        color: Z.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Z.outline),

                        // Identity row: small avatar + name + edit/friend buttons
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
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
                                      '@${profile.username}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Z.textMuted),
                                    ),
                                    const SizedBox(height: 3),
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
                                        profile.bio!.isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text(profile.bio!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Z.textMuted,
                                              height: 1.4),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                    ],
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
                                        useRootNavigator: true,
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
                              Builder(
                                builder: (builderCtx) => _StatItem(
                                  label: 'Stamps',
                                  value: profile.stampCount,
                                  onTap: () => DefaultTabController.of(builderCtx)
                                      .animateTo(1),
                                ),
                              ),
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
                            const Tab(text: 'Map'),
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
                      // Map (first / default)
                      !canView
                          ? const _LockedGrid()
                          : _MapTab(
                              targetId: targetId,
                              isOwnProfile: isOwnProfile,
                              stampCount: profile.stampCount),
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
          behavior: HitTestBehavior.opaque,
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
      useRootNavigator: true,
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
            onSelected: (a) async {
              if (a == _FriendAction.unfriend) {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Unfriend?'),
                    content: const Text('You will no longer share live location with each other.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unfriend', style: TextStyle(color: Z.error))),
                    ],
                  ),
                );
                if (ok == true) _run(notifier.unfriend, 'Failed to unfriend', friend: true);
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
              : () async {
                  if (fw == FollowState.following) {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Unfollow?'),
                        content: const Text('You will stop seeing their stamps in your feed.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unfollow', style: TextStyle(color: Z.error))),
                        ],
                      ),
                    );
                    if (ok != true) return;
                  }
                  _run(() => notifier.toggleFollow(widget.targetId),
                      'Failed to update follow status', friend: false);
                },
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref
                    .read(profileStampsNotifierProvider(targetId,
                            publicOnly: !isOwnProfile)
                        .notifier)
                    .loadMore(targetId, publicOnly: !isOwnProfile);
              });
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

// ── Map tab — user's stamps + check-ins plotted, with aggregates ──────────────
class _MapTab extends ConsumerStatefulWidget {
  final String targetId;
  final bool isOwnProfile;
  final int stampCount;
  const _MapTab({
    required this.targetId,
    required this.isOwnProfile,
    required this.stampCount,
  });

  @override
  ConsumerState<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<_MapTab>
    with AutomaticKeepAliveClientMixin {
  List<Stamp> _stamps = [];
  List<CheckIn> _checkIns = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stampRes = await ref.read(stampRepositoryProvider).getUserStamps(
          widget.targetId,
          publicOnly: !widget.isOwnProfile,
          limit: 200,
        );
    List<CheckIn> checkIns = const [];
    if (widget.isOwnProfile) {
      final ciRes =
          await ref.read(checkInRepositoryProvider).getMyCheckIns(limit: 200);
      checkIns = ciRes
          .getOrElse((_) => const [])
          .where((c) => c.source != CheckInSource.auto)
          .toList();
    }
    if (!mounted) return;
    setState(() {
      _stamps = stampRes.getOrElse((_) => const []);
      _checkIns = checkIns;
      _loading = false;
    });
  }

  /// Convex hull of all stamp + check-in pins as [[lng, lat], ...] pairs (open ring).
  /// Returns empty list when fewer than 3 distinct points exist.
  List<List<double>> get _hullLngLat {
    final raw = <List<double>>[
      for (final s in _stamps) [s.lng, s.lat],
      for (final c in _checkIns) [c.lng, c.lat],
    ];
    if (raw.length < 3) return [];
    raw.sort((a, b) => a[0] != b[0] ? a[0].compareTo(b[0]) : a[1].compareTo(b[1]));

    double cross(List<double> o, List<double> a, List<double> b) =>
        (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);

    final lower = <List<double>>[];
    for (final p in raw) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }
    final upper = <List<double>>[];
    for (final p in raw.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }
    final hull = [...lower.take(lower.length - 1), ...upper.take(upper.length - 1)];
    return hull.length >= 3 ? hull : [];
  }

  /// Area (km²) enclosed by the convex hull of all stamp + check-in pins.
  double get _coverageKm2 {
    final hull = _hullLngLat;
    if (hull.length < 3) return 0;

    // Project to metres relative to centroid (flat-earth, good enough for city-scale)
    final cLat = hull.map((p) => p[1]).reduce((a, b) => a + b) / hull.length;
    final cLng = hull.map((p) => p[0]).reduce((a, b) => a + b) / hull.length;
    const mPerDegLat = 111320.0;
    final mPerDegLng = 111320.0 * cos(cLat * pi / 180.0);

    final pts = hull
        .map((p) => (
              x: (p[0] - cLng) * mPerDegLng,
              y: (p[1] - cLat) * mPerDegLat,
            ))
        .toList();

    // Shoelace formula → area in m²
    double area = 0;
    for (int i = 0; i < pts.length; i++) {
      final j = (i + 1) % pts.length;
      area += pts[i].x * pts[j].y;
      area -= pts[j].x * pts[i].y;
    }
    return area.abs() / 2.0 / 1e6;
  }

  String get _coverageLabel {
    final km2 = _coverageKm2;
    if (km2 == 0) return '—';
    if (km2 < 1) return '${(km2 * 100).round() / 100} km²';
    if (km2 < 10) return '${km2.toStringAsFixed(1)} km²';
    return '${km2.round()} km²';
  }

  /// Distinct places, aggregated from stamps (name → count + representative pt).
  List<({String name, int count, double lat, double lng})> get _visitedPlaces {
    final byName =
        <String, ({int count, double lat, double lng})>{};
    for (final s in _stamps) {
      final cur = byName[s.placeName];
      byName[s.placeName] = (
        count: (cur?.count ?? 0) + 1,
        lat: cur?.lat ?? s.lat,
        lng: cur?.lng ?? s.lng,
      );
    }
    final list = byName.entries
        .map((e) =>
            (name: e.key, count: e.value.count, lat: e.value.lat, lng: e.value.lng))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  String _distLabel(double lat, double lng) {
    final pos = ref.read(gpsNotifierProvider).valueOrNull;
    if (pos == null) return '';
    final m = geo.Geolocator.distanceBetween(
        pos.latitude, pos.longitude, lat, lng);
    return m < 1000 ? '${m.round()}m' : '${(m / 1000.0).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const LoadingView();

    final allPts = [
      for (final s in _stamps) (s.lat, s.lng),
      for (final c in _checkIns) (c.lat, c.lng),
    ];
    if (allPts.isEmpty) {
      return EmptyView(
        icon: Icons.map_outlined,
        message:
            widget.isOwnProfile ? 'No places yet' : 'No public places yet',
        subtitle: widget.isOwnProfile
            ? 'Your stamps and check-ins will map here.'
            : null,
      );
    }

    final centerLat =
        allPts.map((p) => p.$1).reduce((a, b) => a + b) / allPts.length;
    final centerLng =
        allPts.map((p) => p.$2).reduce((a, b) => a + b) / allPts.length;

    final markers = <MiniMapMarker>[
      for (final s in _stamps)
        MiniMapMarker(
            id: s.id, kind: 'stamp', lat: s.lat, lng: s.lng,
            color: Z.brand.toARGB32(), radius: 7),
      for (final c in _checkIns)
        MiniMapMarker(
            id: c.id, kind: 'checkin', lat: c.lat, lng: c.lng,
            color: Z.checkin.toARGB32(), radius: 5),
    ];

    final places = _visitedPlaces;
    final placeCheckIns =
        _checkIns.where((c) => c.placeName.isNotEmpty).take(20).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Map with stats overlay
        SizedBox(
          height: 268,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MiniMap(
                lat: centerLat,
                lng: centerLng,
                zoom: allPts.length > 1 ? 11.0 : 14.0,
                markers: markers,
                hull: _hullLngLat.isEmpty ? null : _hullLngLat,
              ),
              // Gradient scrim + stats
              IgnorePointer(
                child: Container(
                  alignment: Alignment.bottomLeft,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x85000000)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      _MapStat(
                          value: '${widget.stampCount}', label: 'Stamps'),
                      const SizedBox(width: 24),
                      _MapStat(
                          value: _coverageLabel,
                          label: 'Conquered'),
                      const SizedBox(width: 24),
                      _MapStat(
                          value: '${places.length}', label: 'Places'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Visited Places
        if (places.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text('Visited Places',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Z.textMuted,
                    letterSpacing: 0.6)),
          ),
          for (final p in places.take(20))
            GestureDetector(
              onTap: () {
                final match = _stamps.where((s) => s.placeName == p.name).firstOrNull;
                if (match != null) {
                  context.push('/stamp/${match.id}');
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Z.outline))),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: Z.brandSoft, borderRadius: Z.r12),
                      alignment: Alignment.center,
                      child: const Icon(Icons.location_on,
                          size: 16, color: Z.brand),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Z.text)),
                          const SizedBox(height: 2),
                          Text('${p.count} stamp${p.count == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  fontSize: 11, color: Z.textMuted)),
                        ],
                      ),
                    ),
                    Text(_distLabel(p.lat, p.lng),
                        style: const TextStyle(
                            fontSize: 11, color: Z.textMuted)),
                  ],
                ),
              ),
            ),
        ],

        // Check-ins (own profile only)
        if (placeCheckIns.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text('Check-ins',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Z.textMuted,
                    letterSpacing: 0.6)),
          ),
          for (final c in placeCheckIns)
            GestureDetector(
              onTap: () => context.push('/check-in/${c.id}'),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Z.outline))),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: c.stampId != null
                              ? Z.brandSoft
                              : Z.checkinSoft,
                          borderRadius: Z.r12),
                      alignment: Alignment.center,
                      child: Icon(
                          c.stampId != null
                              ? Icons.workspace_premium
                              : Icons.location_on,
                          size: 16,
                          color: c.stampId != null ? Z.brand : Z.checkin),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.placeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Z.text)),
                          const SizedBox(height: 2),
                          Text(DateFormat('MMM d · h:mm a').format(c.visitedAt),
                              style: const TextStyle(
                                  fontSize: 11, color: Z.textMuted)),
                        ],
                      ),
                    ),
                    _KindChip(
                        auto: c.source == CheckInSource.auto,
                        isStamp: c.stampId != null),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MapStat extends StatelessWidget {
  final String value;
  final String label;
  const _MapStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xB8FFFFFF))),
        ],
      );
}

class _KindChip extends StatelessWidget {
  final bool auto;
  final bool isStamp;
  const _KindChip({required this.auto, required this.isStamp});
  @override
  Widget build(BuildContext context) {
    final (label, color, soft) = isStamp
        ? ('Stamp', Z.brand, Z.brandSoft)
        : auto
            ? ('Auto', Z.auto, const Color(0x1AADADAD))
            : ('Check-in', Z.checkin, Z.checkinSoft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: soft, borderRadius: Z.rFull),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: color)),
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

