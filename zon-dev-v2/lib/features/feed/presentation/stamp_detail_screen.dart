import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/app_states.dart';
import 'providers/feed_provider.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../../shared/widgets/photo_thumb_row.dart';
import '../../../shared/utils/format.dart';
import '../../checkin/presentation/user_tag_field.dart' show showUserPicker;

part 'stamp_detail_screen.g.dart';

/// The comment currently being replied to (null = top-level), per stamp.
final replyTargetProvider =
    StateProvider.family<StampComment?, String>((ref, _) => null);

// ── Providers ────────────────────────────────────────────────

@riverpod
Future<Stamp?> stampDetail(StampDetailRef ref, String stampId) async {
  final repo = ref.watch(stampRepositoryProvider);
  final result = await repo.getStamp(stampId);
  return result.fold((_) => null, (s) => s);
}

@riverpod
Future<List<StampComment>> stampComments(
    StampCommentsRef ref, String stampId) async {
  final repo = ref.watch(commentRepositoryProvider);
  final result = await repo.getComments(stampId);
  return result.getOrElse((_) => []);
}

@riverpod
Future<List<String>> stampPhotos(StampPhotosRef ref, String stampId) async {
  final repo = ref.watch(stampRepositoryProvider);
  final photos = await repo.getStampPhotos(stampId);
  return [for (final p in photos) p.url];
}

@riverpod
Future<List<UserProfile>> stampTaggedUsers(
    StampTaggedUsersRef ref, String stampId) async {
  final stamp = await ref.watch(stampDetailProvider(stampId).future);
  if (stamp == null || stamp.taggedUserIds.isEmpty) return [];
  return ref
      .watch(profileRepositoryProvider)
      .getProfilesByIds(stamp.taggedUserIds);
}

// ── Screen ───────────────────────────────────────────────────

class StampDetailScreen extends ConsumerWidget {
  final String stampId;
  const StampDetailScreen({super.key, required this.stampId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stampAsync = ref.watch(stampDetailProvider(stampId));

    return Scaffold(
      body: stampAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
        data: (stamp) {
          if (stamp == null) {
            return const EmptyView(
              icon: Icons.location_off_outlined,
              message: 'Stamp not found',
            );
          }
          return _StampDetailBody(stamp: stamp, stampId: stampId);
        },
      ),
    );
  }
}

class _StampDetailBody extends ConsumerWidget {
  final Stamp stamp;
  final String stampId;

  const _StampDetailBody({required this.stamp, required this.stampId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(stampCommentsProvider(stampId));
    final photoUrls =
        ref.watch(stampPhotosProvider(stampId)).valueOrNull ?? const <String>[];
    final tagged = ref.watch(stampTaggedUsersProvider(stampId)).valueOrNull ??
        const <UserProfile>[];
    final isOwner = stamp.userId == ref.watch(currentUserProvider)?.id;

    return CustomScrollView(
      slivers: [
        // ── App bar with 340px cover photo & scrim ────────────
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          automaticallyImplyLeading: false,
          leadingWidth: 56,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () async {
                await ref.read(stampRepositoryProvider).toggleSave(stampId);
                ref.invalidate(stampDetailProvider(stampId));
              },
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stamp.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: stamp.isSaved ? Z.brand : Colors.white,
                  size: 20,
                ),
              ),
            ),
            if (isOwner)
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 16, left: 4, top: 8, bottom: 8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await context.push('/stamp/$stampId/edit');
                      ref.invalidate(stampDetailProvider(stampId));
                      ref.invalidate(stampPhotosProvider(stampId));
                    } else if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete stamp?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref
                            .read(stampRepositoryProvider)
                            .deleteStamp(stampId);
                        ref.read(feedNotifierProvider.notifier).removeStamp(stampId);
                        if (context.mounted) context.pop();
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (stamp.coverPhotoUrl != null)
                  CachedNetworkImage(
                    imageUrl: stamp.coverPhotoUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: Z.surface2,
                    child: const Icon(Icons.image_outlined, size: 48, color: Z.textMuted),
                  ),
                // Gradient scrim
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Bottom details overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stamp.placeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _VisibilityBadge(stamp.visibility),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/profile/${stamp.userId}'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundImage: stamp.avatarUrl != null
                                      ? CachedNetworkImageProvider(stamp.avatarUrl!)
                                      : null,
                                  child: stamp.avatarUrl == null
                                      ? const Icon(Icons.person, size: 12)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '@${stamp.username ?? "user"}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM d, yyyy · h:mm a').format(stamp.visitedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Stamp info ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tagged.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final u in tagged)
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: CircleAvatar(
                            backgroundImage: u.avatarUrl != null
                                ? CachedNetworkImageProvider(u.avatarUrl!)
                                : null,
                            child: u.avatarUrl == null
                                ? const Icon(Icons.person, size: 12)
                                : null,
                          ),
                          label: Text('@${u.username}'),
                          onPressed: () => context.push('/profile/${u.id}'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                if (stamp.caption != null && stamp.caption!.isNotEmpty) ...[
                  Text(
                    stamp.caption!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      height: 1.65,
                      color: Z.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (stamp.sensoryTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: stamp.sensoryTags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Z.brandSoft,
                                borderRadius: Z.rFull,
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Z.brand,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action icons row
                Row(
                  children: [
                    _LikeButton(stamp: stamp, stampId: stampId),
                    const SizedBox(width: 24),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 20, color: Z.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          compactCount(stamp.commentCount),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Z.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (photoUrls.isNotEmpty) ...[
                      const Icon(Icons.photo_library_outlined, size: 18, color: Z.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${compactCount(stamp.photoCount)} photos',
                        style: const TextStyle(fontSize: 12, color: Z.textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Photo grid ───────────────────────────────────────
        if (photoUrls.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PhotoThumbRow(urls: photoUrls, size: 90),
            ),
          ),

        // ── Comments header ──────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Comments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Z.text),
            ),
          ),
        ),

        // ── Comments list ────────────────────────────────────
        commentsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Z.brand),
              ),
            ),
          ),
          error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          data: (comments) {
            if (comments.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Text(
                    'No comments yet. Be the first!',
                    style: TextStyle(color: Z.textMuted, fontSize: 14),
                  ),
                ),
              );
            }
            final repliesByParent = <String, List<StampComment>>{};
            for (final c in comments) {
              if (c.parentId != null) {
                repliesByParent.putIfAbsent(c.parentId!, () => []).add(c);
              }
            }
            final rows = <Widget>[];
            for (final c in comments.where((c) => c.parentId == null)) {
              rows.add(
                  _CommentTile(comment: c, stampId: stampId, isReply: false));
              for (final r in repliesByParent[c.id] ?? const []) {
                rows.add(
                    _CommentTile(comment: r, stampId: stampId, isReply: true));
              }
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => rows[i],
                childCount: rows.length,
              ),
            );
          },
        ),

        // ── Comment input ────────────────────────────────────
        SliverToBoxAdapter(
          child: _CommentInput(stampId: stampId),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Comment input ─────────────────────────────────────────────

class _CommentInput extends ConsumerStatefulWidget {
  final String stampId;
  const _CommentInput({required this.stampId});

  @override
  ConsumerState<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<_CommentInput> {
  final _ctrl = TextEditingController();
  final Set<String> _mentionIds = {};
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _clearReply() =>
      ref.read(replyTargetProvider(widget.stampId).notifier).state = null;

  Future<void> _addMention() async {
    final user = await showUserPicker(context);
    if (user == null) return;
    _mentionIds.add(user.id);
    final t = _ctrl.text;
    final sep = t.isEmpty || t.endsWith(' ') ? '' : ' ';
    _ctrl.text = '$t$sep@${user.username} ';
    _ctrl.selection =
        TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
    setState(() {});
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final repo = ref.read(commentRepositoryProvider);
    final replyTarget = ref.read(replyTargetProvider(widget.stampId));
    final res = await repo.addComment(
      stampId: widget.stampId,
      body: text,
      parentId: replyTarget?.id,
    );
    await res.fold(
      (e) async {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to post comment: ${e.message}')));
        }
      },
      (comment) async {
        final targets = {..._mentionIds};
        if (replyTarget != null) targets.add(replyTarget.userId);
        for (final t in targets) {
          await repo.notifyMention(
            targetUserId: t,
            stampId: widget.stampId,
            commentId: comment.id,
          );
        }
        _ctrl.clear();
        _mentionIds.clear();
        _clearReply();
        ref.invalidate(stampCommentsProvider(widget.stampId));
        ref.invalidate(stampDetailProvider(widget.stampId));
      },
    );
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final replyTarget = ref.watch(replyTargetProvider(widget.stampId));
    final myId = ref.watch(currentUserProvider)?.id;
    final myProfile = myId != null ? ref.watch(profileNotifierProvider(myId)).valueOrNull : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        key: ValueKey('comment-input-${widget.stampId}'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replyTarget != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Z.brandSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to @${replyTarget.username ?? 'user'}',
                      style: const TextStyle(color: Z.brand, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearReply,
                    child: const Icon(Icons.close, size: 16, color: Z.brand),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Current user avatar (34px)
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Z.surface2,
                ),
                clipBehavior: Clip.antiAlias,
                child: myProfile?.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: myProfile!.avatarUrl!,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          myProfile?.username.isNotEmpty == true
                              ? myProfile!.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Z.textMuted),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              // Pill Input Box
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(fontSize: 14, color: Z.text),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    filled: true,
                    fillColor: Z.surface0,
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.alternate_email, size: 18, color: Z.textMuted),
                      onPressed: _addMention,
                      padding: EdgeInsets.zero,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Z.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Z.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Z.brand, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              _sending
                  ? const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Z.brand),
                    )
                  : Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Z.brandSoft,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, size: 18, color: Z.brand),
                        onPressed: _submit,
                        padding: EdgeInsets.zero,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Comment tile ──────────────────────────────────────────────

class _CommentTile extends ConsumerWidget {
  final StampComment comment;
  final String stampId;
  final bool isReply;
  const _CommentTile({
    required this.comment,
    required this.stampId,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentUserProvider)?.id;
    final isOwn = comment.userId == myId;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 52 : 16,
        right: 16,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (34px or 28px for reply)
          GestureDetector(
            onTap: () => context.push('/profile/${comment.userId}'),
            child: Container(
              width: isReply ? 28 : 34,
              height: isReply ? 28 : 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Z.surface2,
              ),
              clipBehavior: Clip.antiAlias,
              child: comment.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: comment.avatarUrl!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Text(
                        comment.username != null && comment.username!.isNotEmpty
                            ? comment.username![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: isReply ? 11 : 13,
                          fontWeight: FontWeight.bold,
                          color: Z.textMuted,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // Bubble content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Z.surface1,
                border: Border.all(color: Z.outline),
                borderRadius: Z.r12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: username + time
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile/${comment.userId}'),
                        child: Text(
                          comment.username ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Z.text,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(comment.createdAt),
                        style: const TextStyle(color: Z.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Text body
                  Text.rich(
                    _mentionSpan(comment.body),
                    style: const TextStyle(fontSize: 13, height: 1.45, color: Z.text),
                  ),
                  // Reply CTA
                  if (!isReply) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => ref
                          .read(replyTargetProvider(stampId).notifier)
                          .state = comment,
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          color: Z.brand,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isOwn) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Z.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                final repo = ref.read(commentRepositoryProvider);
                await repo.deleteComment(comment.id);
                ref.invalidate(stampCommentsProvider(stampId));
                ref.invalidate(stampDetailProvider(stampId));
              },
            ),
          ],
        ],
      ),
    );
  }

  static TextSpan _mentionSpan(String body) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'@(\w+)');
    int last = 0;
    for (final m in regex.allMatches(body)) {
      if (m.start > last) spans.add(TextSpan(text: body.substring(last, m.start)));
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(color: Z.brand, fontWeight: FontWeight.w600),
      ));
      last = m.end;
    }
    if (last < body.length) spans.add(TextSpan(text: body.substring(last)));
    return TextSpan(children: spans);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Shared widgets ────────────────────────────────────────────

class _VisibilityBadge extends StatelessWidget {
  final StampVisibility visibility;
  const _VisibilityBadge(this.visibility);

  @override
  Widget build(BuildContext context) {
    final isPublic = visibility == StampVisibility.public;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPublic ? const Color(0x1F10B981) : Z.brandSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock,
            size: 11,
            color: isPublic ? Z.success : Z.brand,
          ),
          const SizedBox(width: 4),
          Text(
            visibility.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isPublic ? Z.success : Z.brand,
            ),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends ConsumerWidget {
  final Stamp stamp;
  final String stampId;
  const _LikeButton({required this.stamp, required this.stampId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await ref.read(stampRepositoryProvider).toggleLike(stampId);
        ref.invalidate(stampDetailProvider(stampId));
      },
      child: Row(
        children: [
          Icon(
            stamp.isLiked ? Icons.favorite : Icons.favorite_border,
            color: stamp.isLiked ? Z.error : Z.textMuted,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            compactCount(stamp.likeCount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: stamp.isLiked ? Z.error : Z.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
