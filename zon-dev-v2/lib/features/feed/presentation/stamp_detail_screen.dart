import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/location/providers/gps_provider.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../shared/widgets/mini_map.dart';
import 'feed_screen.dart' show StampCard;
import 'providers/feed_provider.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../../shared/utils/format.dart';

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

class _StampDetailBody extends ConsumerStatefulWidget {
  final Stamp stamp;
  final String stampId;

  const _StampDetailBody({required this.stamp, required this.stampId});

  @override
  ConsumerState<_StampDetailBody> createState() => _StampDetailBodyState();
}

class _StampDetailBodyState extends ConsumerState<_StampDetailBody> {
  PageController? _gallery;
  int _page = 0;
  bool _showingPhotos = true;

  Stamp get stamp => widget.stamp;
  String get stampId => widget.stampId;

  @override
  void dispose() {
    _gallery?.dispose();
    super.dispose();
  }

  void _ensureController() {
    _gallery ??= PageController(initialPage: 0);
  }

  String? _subtitle() {
    final parts = <String>[];
    final pos = ref.read(gpsNotifierProvider).valueOrNull;
    if (pos != null) {
      final m = geo.Geolocator.distanceBetween(
          pos.latitude, pos.longitude, stamp.lat, stamp.lng);
      parts.add(m < 1000 ? '${m.round()}m away' : '${(m / 1000).toStringAsFixed(1)}km away');
    }
    parts.add(_relDate(stamp.visitedAt));
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(stampPhotosProvider(stampId));
    final photoUrls = photosAsync.valueOrNull ??
        (stamp.coverPhotoUrl != null ? [stamp.coverPhotoUrl!] : const <String>[]);
    final tagged = ref.watch(stampTaggedUsersProvider(stampId)).valueOrNull ??
        const <UserProfile>[];
    final isOwner = stamp.userId == ref.watch(currentUserProvider)?.id;
    final commentsAsync = ref.watch(stampCommentsProvider(stampId));

    _ensureController();

    return Column(
      children: [
        // ── Fixed place header ───────────────────────────────
        Container(
          color: Z.surface1,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 2, 8, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back, size: 24, color: Z.text),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: stamp.externalPlaceId != null
                          ? () => context.push(
                              '/place/${Uri.encodeComponent(stamp.externalPlaceId!)}')
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stamp.placeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Z.text,
                                height: 1.2),
                          ),
                          if (_subtitle() != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              _subtitle()!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Z.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (stamp.externalPlaceId != null)
                    GestureDetector(
                      onTap: () => context.push(
                          '/place/${Uri.encodeComponent(stamp.externalPlaceId!)}'),
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Z.outline2),
                          borderRadius: Z.rFull,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me, size: 13, color: Z.brand),
                            SizedBox(width: 4),
                            Text('Go',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Z.text)),
                          ],
                        ),
                      ),
                    ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 22, color: Z.text),
                      onSelected: (v) => _onMenu(v, photoUrls),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 0.5, color: Z.outline),

        // ── Gallery sits outside the scroll view so the map gets raw touches ──
        Flexible(child: _buildGallery(photoUrls)),

        // ── Scrollable content: actions → comments → more ─────────────────
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [

              // Actions + caption
              Container(
                color: Z.surface1,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _IconAction(
                          icon: stamp.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: stamp.isLiked ? Z.error : Z.text,
                          onTap: () async {
                            await ref
                                .read(stampRepositoryProvider)
                                .toggleLike(stampId);
                            ref.invalidate(stampDetailProvider(stampId));
                          },
                        ),
                        _IconAction(
                            icon: Icons.chat_bubble_outline,
                            color: Z.text,
                            onTap: () {}),
                        _IconAction(
                            icon: Icons.send, color: Z.text, onTap: () {}),
                        const Spacer(),
                        _IconAction(
                          icon: stamp.isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: stamp.isSaved ? Z.brand : Z.text,
                          onTap: () async {
                            await ref
                                .read(stampRepositoryProvider)
                                .toggleSave(stampId);
                            ref.invalidate(stampDetailProvider(stampId));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${compactCount(stamp.likeCount)} likes',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Z.text)),
                    if (stamp.caption != null &&
                        stamp.caption!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: '@${stamp.username ?? 'user'} ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: Z.text),
                          ),
                          TextSpan(text: stamp.caption!),
                        ]),
                        style: const TextStyle(
                            fontSize: 13, height: 1.65, color: Z.text),
                      ),
                    ],
                    if (stamp.sensoryTags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          for (final t in stamp.sensoryTags)
                            Text('#$t',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Z.brand)),
                        ],
                      ),
                    ],
                    if (tagged.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final u in tagged)
                            GestureDetector(
                              onTap: () => context.push('/profile/${u.id}'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 9,
                                    backgroundImage: u.avatarUrl != null
                                        ? CachedNetworkImageProvider(
                                            u.avatarUrl!)
                                        : null,
                                    child: u.avatarUrl == null
                                        ? const Icon(Icons.person, size: 9)
                                        : null,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('@${u.username}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Z.textMuted)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 0.5, color: Z.outline),

              // Comments — flattened, borderless
              Container(
                color: Z.surface1,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                alignment: Alignment.centerLeft,
                child: const Text('Comments',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Z.text)),
              ),
              commentsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: CircularProgressIndicator(color: Z.brand)),
                ),
                error: (e, _) => const SizedBox.shrink(),
                data: (comments) {
                  if (comments.isEmpty) {
                    return Container(
                      color: Z.surface1,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      alignment: Alignment.centerLeft,
                      child: const Text('No comments yet. Be the first!',
                          style: TextStyle(color: Z.textMuted, fontSize: 13)),
                    );
                  }
                  final repliesByParent = <String, List<StampComment>>{};
                  for (final c in comments) {
                    if (c.parentId != null) {
                      repliesByParent
                          .putIfAbsent(c.parentId!, () => [])
                          .add(c);
                    }
                  }
                  final rows = <Widget>[];
                  for (final c
                      in comments.where((c) => c.parentId == null)) {
                    rows.add(_CommentTile(
                        comment: c, stampId: stampId, isReply: false));
                    for (final r in repliesByParent[c.id] ?? const []) {
                      rows.add(_CommentTile(
                          comment: r, stampId: stampId, isReply: true));
                    }
                  }
                  return Container(
                    color: Z.surface1,
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Column(children: rows),
                  );
                },
              ),
              // More from this place
              if (stamp.externalPlaceId != null)
                _MoreFromPlace(
                  placeId: stamp.externalPlaceId!,
                  placeName: stamp.placeName,
                  excludeId: stampId,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // ── Fixed comment input footer ───────────────────────
        const Divider(height: 1, color: Z.outline),
        SafeArea(
          top: false,
          child: Container(
            color: Z.surface1,
            child: _CommentInput(stampId: stampId),
          ),
        ),
      ],
    );
  }

  Future<void> _onMenu(String v, List<String> photoUrls) async {
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
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete')),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(stampRepositoryProvider).deleteStamp(stampId);
        ref.read(feedNotifierProvider.notifier).removeStamp(stampId);
        if (mounted) context.pop();
      }
    }
  }

  // ── Gallery: interactive map base + photo layer that slides in on top ─────
  Widget _buildGallery(List<String> photoUrls) {
    const h = 348.0;
    const pillDecor = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(9999)),
      boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3))],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: h),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Map — always rendered, fully interactive ───────────────
          MiniMap(
            lat: stamp.lat,
            lng: stamp.lng,
            zoom: 15.5,
            interactive: true,
            markers: [
              MiniMapMarker(
                id: stamp.id,
                lat: stamp.lat,
                lng: stamp.lng,
                color: Z.brand.toARGB32(),
                radius: 8,
              ),
            ],
          ),
          // Place name chip
          Positioned(
            left: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: Z.rFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 13, color: Z.brand),
                  const SizedBox(width: 5),
                  Text(stamp.placeName,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: Z.text)),
                ],
              ),
            ),
          ),
          // Photos → button (fades out when photos are showing)
          if (photoUrls.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 20,
              child: AnimatedOpacity(
                opacity: _showingPhotos ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: _showingPhotos,
                  child: GestureDetector(
                    onTap: () => setState(() { _showingPhotos = true; _page = 0; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: pillDecor,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Photos',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Z.text)),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 18, color: Z.text),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Photo layer — slides in from the right ─────────────────
          if (photoUrls.isNotEmpty)
            AnimatedSlide(
              offset: _showingPhotos ? Offset.zero : const Offset(1.0, 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo PageView
                  PageView(
                    controller: _gallery,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      for (final (i, url) in photoUrls.indexed)
                        GestureDetector(
                          onTap: () => FullScreenImageViewer.show(context, photoUrls, index: i),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ColoredBox(color: Z.surface2),
                            errorWidget: (_, __, ___) => const ColoredBox(color: Z.surface2),
                          ),
                        ),
                    ],
                  ),
                  // Dot indicators
                  if (photoUrls.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < photoUrls.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: _page == i ? 18 : 6,
                              height: 5,
                              decoration: BoxDecoration(
                                color: _page == i
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  // ← Map button
                  Positioned(
                    left: 16,
                    bottom: 20,
                    child: GestureDetector(
                      onTap: () => setState(() => _showingPhotos = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: pillDecor,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_left, size: 18, color: Z.text),
                            SizedBox(width: 4),
                            Text('Map',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Z.text)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _relDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

// ── Icon action (Instagram-style bar) ─────────────────────────
class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconAction(
      {required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Icon(icon, size: 26, color: color),
        ),
      );
}

// ── More from this place — feed-style StampCards ──────────────
class _MoreFromPlace extends ConsumerStatefulWidget {
  final String placeId;
  final String placeName;
  final String excludeId;
  const _MoreFromPlace({
    required this.placeId,
    required this.placeName,
    required this.excludeId,
  });

  @override
  ConsumerState<_MoreFromPlace> createState() => _MoreFromPlaceState();
}

class _MoreFromPlaceState extends ConsumerState<_MoreFromPlace> {
  List<Stamp> _stamps = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ref
        .read(stampRepositoryProvider)
        .getStampsForPlace(widget.placeId);
    if (!mounted) return;
    setState(() {
      _stamps = res
          .getOrElse((_) => const [])
          .where((s) => s.id != widget.excludeId)
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _stamps.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text('More from ${widget.placeName}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Z.text)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [for (final s in _stamps) StampCard(stamp: s)],
          ),
        ),
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

  // Inline @mention state
  String? _mentionQuery; // non-null while user is typing after @
  List<UserProfile> _mentionSuggestions = [];
  bool _mentionLoading = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _clearReply() =>
      ref.read(replyTargetProvider(widget.stampId).notifier).state = null;

  void _onTextChanged() {
    final text = _ctrl.text;
    final cursor = _ctrl.selection.baseOffset;
    if (cursor < 0) return;

    // Find the @ token the cursor is currently inside
    final before = text.substring(0, cursor);
    final match = RegExp(r'@(\w*)$').firstMatch(before);
    if (match != null) {
      final query = match.group(1)!;
      if (_mentionQuery != query) {
        _mentionQuery = query;
        _fetchMentionSuggestions(query);
      }
    } else if (_mentionQuery != null) {
      setState(() {
        _mentionQuery = null;
        _mentionSuggestions = [];
      });
    }
  }

  Future<void> _fetchMentionSuggestions(String query) async {
    setState(() => _mentionLoading = true);
    try {
      final results = await ref
          .read(profileRepositoryProvider)
          .searchUsers(query.isEmpty ? ' ' : query);
      if (mounted && _mentionQuery == query) {
        setState(() {
          _mentionSuggestions = results.take(5).toList();
          _mentionLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _mentionLoading = false);
    }
  }

  void _pickMention(UserProfile user) {
    _mentionIds.add(user.id);
    final text = _ctrl.text;
    final cursor = _ctrl.selection.baseOffset.clamp(0, text.length);
    final before = text.substring(0, cursor);
    // Replace the trailing @query with @username + space
    final replaced = before.replaceAllMapped(
      RegExp(r'@\w*$'),
      (_) => '@${user.username} ',
    );
    final after = text.substring(cursor);
    _ctrl.text = replaced + after;
    _ctrl.selection =
        TextSelection.fromPosition(TextPosition(offset: replaced.length));
    setState(() {
      _mentionQuery = null;
      _mentionSuggestions = [];
    });
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
        FocusManager.instance.primaryFocus?.unfocus();
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
    final myProfile = myId != null
        ? ref.watch(profileNotifierProvider(myId)).valueOrNull
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        key: ValueKey('comment-input-${widget.stampId}'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // @mention suggestion list
          if (_mentionQuery != null && (_mentionLoading || _mentionSuggestions.isNotEmpty))
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Z.surface1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Z.outline),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2)),
                ],
              ),
              child: _mentionLoading && _mentionSuggestions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Z.brand))),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _mentionSuggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Z.outline),
                      itemBuilder: (_, i) {
                        final u = _mentionSuggestions[i];
                        return InkWell(
                          onTap: () => _pickMention(u),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Z.surface2,
                                  backgroundImage: u.avatarUrl != null
                                      ? CachedNetworkImageProvider(u.avatarUrl!)
                                      : null,
                                  child: u.avatarUrl == null
                                      ? Text(u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                                          style: const TextStyle(fontSize: 11, color: Z.textMuted))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('@${u.username}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Z.text)),
                                    if (u.displayName != null && u.displayName!.isNotEmpty)
                                      Text(u.displayName!,
                                          style: const TextStyle(fontSize: 11, color: Z.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

          // Reply banner
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

          // Input row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Z.surface2),
                clipBehavior: Clip.antiAlias,
                child: myProfile?.avatarUrl != null
                    ? CachedNetworkImage(imageUrl: myProfile!.avatarUrl!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          myProfile?.username.isNotEmpty == true
                              ? myProfile!.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Z.textMuted),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(fontSize: 14, color: Z.text),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    filled: true,
                    fillColor: Z.surface0,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      decoration: const BoxDecoration(color: Z.brandSoft, shape: BoxShape.circle),
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
    final avatarSize = isReply ? 22.0 : 30.0;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 34 : 16,
        right: 16,
        top: 8,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/${comment.userId}'),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Z.surface2,
              ),
              clipBehavior: Clip.antiAlias,
              child: comment.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: comment.avatarUrl!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        comment.username != null && comment.username!.isNotEmpty
                            ? comment.username![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: isReply ? 10 : 12,
                          fontWeight: FontWeight.bold,
                          color: Z.textMuted,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inline: @user + body
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '@${comment.username ?? 'user'} ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Z.text),
                    ),
                    ..._mentionSpan(comment.body, context, ref).children!,
                  ]),
                  style: const TextStyle(
                      fontSize: 13, height: 1.55, color: Z.text),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_timeAgo(comment.createdAt),
                        style: const TextStyle(
                            color: Z.textMuted, fontSize: 11)),
                    if (!isReply) ...[
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => ref
                            .read(replyTargetProvider(stampId).notifier)
                            .state = comment,
                        child: const Text('Reply',
                            style: TextStyle(
                                color: Z.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                    if (isOwn) ...[
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete comment?'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Z.error)),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          final repo = ref.read(commentRepositoryProvider);
                          await repo.deleteComment(comment.id);
                          ref.invalidate(stampCommentsProvider(stampId));
                          ref.invalidate(stampDetailProvider(stampId));
                        },
                        child: const Text('Delete',
                            style: TextStyle(
                                color: Z.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _mentionSpan(String body, BuildContext context, WidgetRef ref) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'@(\w+)');
    int last = 0;
    for (final m in regex.allMatches(body)) {
      if (m.start > last) spans.add(TextSpan(text: body.substring(last, m.start)));
      final username = m.group(1)!;
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(color: Z.brand, fontWeight: FontWeight.w600),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final results = await ref
                .read(profileRepositoryProvider)
                .searchUsers(username);
            final match = results.firstWhere(
              (u) => u.username.toLowerCase() == username.toLowerCase(),
              orElse: () => results.first,
            );
            if (context.mounted) context.push('/profile/${match.id}');
          },
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

