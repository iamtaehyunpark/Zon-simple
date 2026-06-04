import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../app.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/app_states.dart';
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
        // ── App bar with cover photo ─────────────────────────
        SliverAppBar(
          expandedHeight: stamp.coverPhotoUrl != null ? 320 : 80,
          pinned: true,
          flexibleSpace: stamp.coverPhotoUrl != null
              ? FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: stamp.coverPhotoUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : const FlexibleSpaceBar(),
          actions: [
            IconButton(
              icon: Icon(
                stamp.isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: stamp.isSaved
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: () async {
                await ref.read(stampRepositoryProvider).toggleSave(stampId);
                ref.invalidate(stampDetailProvider(stampId));
              },
            ),
            if (isOwner)
              PopupMenuButton<String>(
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
                      if (context.mounted) context.pop();
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),

        // ── Stamp info ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stamp.placeName,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMMM d, y').format(stamp.visitedAt),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    _VisibilityBadge(stamp.visibility),
                  ],
                ),

                if (tagged.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final u in tagged)
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: CircleAvatar(
                            backgroundImage: u.avatarUrl != null
                                ? NetworkImage(u.avatarUrl!)
                                : null,
                            child: u.avatarUrl == null
                                ? const Icon(Icons.person, size: 14)
                                : null,
                          ),
                          label: Text('@${u.username}'),
                          onPressed: () => context.push('/profile/${u.id}'),
                        ),
                    ],
                  ),
                ],

                if (stamp.caption != null && stamp.caption!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(stamp.caption!, style: const TextStyle(fontSize: 16)),
                ],

                if (stamp.sensoryTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: stamp.sensoryTags
                        .map((t) => Chip(label: Text(t)))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    _LikeButton(stamp: stamp, stampId: stampId),
                    const SizedBox(width: 16),
                    Icon(Icons.comment_outlined,
                        size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(compactCount(stamp.commentCount)),
                    const SizedBox(width: 16),
                    Icon(Icons.photo_library_outlined,
                        size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${compactCount(stamp.photoCount)} photos'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Photo grid ───────────────────────────────────────
        if (photoUrls.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: photoUrls.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: photoUrls[i],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── Comments header ──────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Comments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // ── Comments list ────────────────────────────────────
        commentsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
          ),
          error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          data: (comments) {
            if (comments.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No comments yet. Be the first!',
                      style: TextStyle(color: Colors.grey)),
                ),
              );
            }
            // 1-level threading: top-level comments, each followed by its replies.
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
    await res.fold((_) async {}, (comment) async {
      final targets = {..._mentionIds};
      if (replyTarget != null) targets.add(replyTarget.userId);
      for (final t in targets) {
        await repo.notifyMention(
          targetUserId: t,
          stampId: widget.stampId,
          commentId: comment.id,
        );
      }
    });
    _ctrl.clear();
    _mentionIds.clear();
    _clearReply();
    ref.invalidate(stampCommentsProvider(widget.stampId));
    ref.invalidate(stampDetailProvider(widget.stampId));
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final replyTarget = ref.watch(replyTargetProvider(widget.stampId));
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyTarget != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Replying to @${replyTarget.username ?? 'user'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: _clearReply,
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.alternate_email),
                tooltip: 'Mention',
                onPressed: _addMention,
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              _sending
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      color: kBrandGreen,
                      onPressed: _submit,
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
      padding: EdgeInsets.only(left: isReply ? 40 : 0),
      child: ListTile(
        leading: CircleAvatar(
          radius: isReply ? 14 : 18,
          backgroundImage: comment.avatarUrl != null
              ? NetworkImage(comment.avatarUrl!)
              : null,
          child: comment.avatarUrl == null
              ? Icon(Icons.person, size: isReply ? 14 : 18)
              : null,
        ),
        title: Row(
          children: [
            Text(
              comment.username ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Text(
              _timeAgo(comment.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.body),
            if (!isReply)
              GestureDetector(
                onTap: () => ref
                    .read(replyTargetProvider(stampId).notifier)
                    .state = comment,
                child: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text('Reply',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
        trailing: isOwn
            ? IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () async {
                  final repo = ref.read(commentRepositoryProvider);
                  await repo.deleteComment(comment.id);
                  ref.invalidate(stampCommentsProvider(stampId));
                  ref.invalidate(stampDetailProvider(stampId));
                },
              )
            : null,
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublic
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPublic ? Icons.public : Icons.lock,
              size: 14, color: isPublic ? Colors.green : Colors.grey),
          const SizedBox(width: 4),
          Text(
            visibility.name,
            style: TextStyle(
              fontSize: 12,
              color: isPublic ? Colors.green : Colors.grey,
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
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await ref.read(stampRepositoryProvider).toggleLike(stampId);
        ref.invalidate(stampDetailProvider(stampId));
      },
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Icon(
              stamp.isLiked ? Icons.favorite : Icons.favorite_border,
              color: stamp.isLiked ? Colors.red : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(compactCount(stamp.likeCount)),
          ],
        ),
      ),
    );
  }
}
