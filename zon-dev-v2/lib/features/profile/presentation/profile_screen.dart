import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../data/models/stamp.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/diary_repository.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/utils/format.dart';
import 'providers/profile_provider.dart';
import '../../../core/auth/auth_provider.dart';

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

        return DefaultTabController(
          length: 3,
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
                                    onTap: () =>
                                        context.push('/settings'))
                              else
                                _SocialButtons(targetId: targetId),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Z.outline),

                        // Stats: Stamps · Places · Friends
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              _StatItem(
                                  label: 'Stamps',
                                  value: profile.stampCount),
                              _vDivider(),
                              _StatItem(
                                  label: 'Places',
                                  value: profile.stampCount,
                                  onTap: isOwnProfile
                                      ? () => context.push('/check-ins')
                                      : null),
                              _vDivider(),
                              _StatItem(
                                  label: 'Friends',
                                  value: profile.friendCount,
                                  onTap: () => context
                                      .push('/profile/$targetId/friends')),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Z.outline),

                        // Tab switcher: Stamps | Saved | Diaries
                        const TabBar(
                          labelStyle: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          unselectedLabelStyle:
                              TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                          labelColor: Z.brand,
                          unselectedLabelColor: Z.textMuted,
                          indicatorColor: Z.brand,
                          indicatorWeight: 2.5,
                          tabs: [
                            Tab(text: 'Stamps'),
                            Tab(text: 'Saved'),
                            Tab(text: 'Diaries'),
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

// ── Social buttons (Add Friend + Follow) ──────────────────────────────────────
class _SocialButtons extends ConsumerWidget {
  final String targetId;
  const _SocialButtons({required this.targetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(friendStateProvider(targetId)).valueOrNull ??
        FriendState.none;
    final fw = ref.watch(followStateProvider(targetId)).valueOrNull ??
        FollowState.none;
    final notifier = ref.read(profileNotifierProvider(targetId).notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Friend button
        GestureDetector(
          onTap: () {
            if (fs == FriendState.none) notifier.sendFriendRequest();
          },
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Z.brand,
              borderRadius: BorderRadius.circular(9999),
            ),
            alignment: Alignment.center,
            child: Text(
              fs == FriendState.friends
                  ? 'Friends'
                  : fs == FriendState.requestedByMe
                      ? 'Requested'
                      : '+ Friend',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 7),
        // Follow button
        GestureDetector(
          onTap: () => notifier.toggleFollow(targetId),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Z.outline2, width: 1.5),
              borderRadius: BorderRadius.circular(9999),
            ),
            alignment: Alignment.center,
            child: Text(
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
          if (isOwnProfile && stamp.visibility.name == 'private')
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
