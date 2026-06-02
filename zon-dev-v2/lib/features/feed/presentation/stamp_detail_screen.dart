import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/enums.dart';

part 'stamp_detail_screen.g.dart';

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

// ── Screen ───────────────────────────────────────────────────

class StampDetailScreen extends ConsumerWidget {
  final String stampId;
  const StampDetailScreen({super.key, required this.stampId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stampAsync = ref.watch(stampDetailProvider(stampId));

    return Scaffold(
      body: stampAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline),
            Text(e.toString()),
          ]),
        ),
        data: (stamp) {
          if (stamp == null) {
            return const Center(child: Text('Stamp not found'));
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
              ),
              onPressed: () async {
                await ref.read(stampRepositoryProvider).toggleSave(stampId);
                ref.invalidate(stampDetailProvider(stampId));
              },
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
                    Text('${stamp.commentCount}'),
                    const SizedBox(width: 16),
                    Icon(Icons.photo_library_outlined,
                        size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${stamp.photoCount} photos'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Photo grid (if multiple photos) ─────────────────
        if (stamp.photoUrls.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: stamp.photoUrls.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: stamp.photoUrls[i],
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
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _CommentTile(comment: comments[i], stampId: stampId),
                childCount: comments.length,
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
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final repo = ref.read(commentRepositoryProvider);
    await repo.addComment(stampId: widget.stampId, body: text);
    _ctrl.clear();
    ref.invalidate(stampCommentsProvider(widget.stampId));
    ref.invalidate(stampDetailProvider(widget.stampId));
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }
}

// ── Comment tile ──────────────────────────────────────────────

class _CommentTile extends ConsumerWidget {
  final StampComment comment;
  final String stampId;
  const _CommentTile({required this.comment, required this.stampId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final isOwn = comment.userId == myId;

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundImage: comment.avatarUrl != null
            ? NetworkImage(comment.avatarUrl!)
            : null,
        child: comment.avatarUrl == null
            ? const Icon(Icons.person, size: 18)
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
      subtitle: Text(comment.body),
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
            Text('${stamp.likeCount}'),
          ],
        ),
      ),
    );
  }
}
