import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../../../data/models/stamp.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../shared/widgets/app_states.dart';

/// Place detail screen (Phase D). Identified by [placeId] = external_place_id.
class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  List<Stamp> _stamps = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref
          .read(stampRepositoryProvider)
          .getStampsForPlace(widget.placeId);
      if (!mounted) return;
      setState(() {
        _stamps = data.getOrElse((_) => []);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cover = _stamps.isNotEmpty ? _stamps.first.coverPhotoUrl : null;
    final placeName = _stamps.isNotEmpty ? _stamps.first.placeName : widget.placeId;
    final allPhotos = [
      for (final s in _stamps) ...s.photoUrls,
    ].take(12).toList();

    // ZON stats
    final visitorIds = {for (final s in _stamps) s.userId}.length;
    final lastVisit = _stamps.isEmpty
        ? null
        : _stamps.reduce((a, b) =>
            a.visitedAt.isAfter(b.visitedAt) ? a : b).visitedAt;

    return Scaffold(
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : CustomScrollView(
                  slivers: [
                    // ── Hero photo ──────────────────────────────────────────
                    SliverAppBar(
                      expandedHeight: cover != null ? 260 : 80,
                      pinned: true,
                      flexibleSpace: cover != null
                          ? FlexibleSpaceBar(
                              background: CachedNetworkImage(
                                imageUrl: cover,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const FlexibleSpaceBar(),
                      actions: [
                        FilledButton.icon(
                          onPressed: () =>
                              context.push('/checkin?mode=checkin'),
                          icon: const Icon(Icons.pin_drop_outlined, size: 16),
                          label: const Text('Check in'),
                          style: FilledButton.styleFrom(
                            backgroundColor: kBrandPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),

                    // ── Place name ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              placeName,
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.w800),
                            ),
                            if (_stamps.isNotEmpty &&
                                _stamps.first.externalSource != null)
                              Text(
                                _stamps.first.externalSource!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ── ZON stats ──────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          children: [
                            _StatChip(
                                icon: Icons.auto_awesome,
                                label: '${_stamps.length} stamps'),
                            const SizedBox(width: 8),
                            _StatChip(
                                icon: Icons.people_outline,
                                label: '$visitorIds visitors'),
                            if (lastVisit != null) ...[
                              const SizedBox(width: 8),
                              _StatChip(
                                  icon: Icons.schedule,
                                  label: _relativeDate(lastVisit)),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ── Photos grid ────────────────────────────────────────
                    if (allPhotos.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            'Photos',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: allPhotos[i],
                                fit: BoxFit.cover,
                              ),
                            ),
                            childCount: allPhotos.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                        ),
                      ),
                    ],

                    // ── Stamps from this place ──────────────────────────────
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          'Stamps',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (_stamps.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: EmptyView(
                            icon: Icons.auto_awesome_outlined,
                            message: 'No public stamps yet',
                            subtitle: 'Check in here to be the first!',
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final s = _stamps[i];
                            return ListTile(
                              leading: s.coverPhotoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: s.coverPhotoUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: kBrandPurple
                                          .withValues(alpha: 0.15),
                                      child: const Icon(Icons.auto_awesome,
                                          color: kBrandPurple, size: 20),
                                    ),
                              title: Text(
                                s.username != null ? '@${s.username}' : 'User',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (s.caption != null &&
                                      s.caption!.isNotEmpty)
                                    Text(
                                      s.caption!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  Text(
                                    DateFormat('MMM d, y').format(s.visitedAt),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              isThreeLine: s.caption != null,
                              onTap: () => context.push('/stamp/${s.id}'),
                            );
                          },
                          childCount: _stamps.length,
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kBrandPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kBrandPurple),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kBrandPurple)),
        ],
      ),
    );
  }
}
