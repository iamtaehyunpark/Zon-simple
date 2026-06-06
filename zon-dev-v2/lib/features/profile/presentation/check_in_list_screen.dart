import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../shared/widgets/app_states.dart';

class CheckInListScreen extends ConsumerStatefulWidget {
  const CheckInListScreen({super.key});

  @override
  ConsumerState<CheckInListScreen> createState() => _CheckInListScreenState();
}

class _CheckInListScreenState extends ConsumerState<CheckInListScreen> {
  List<CheckIn> _checkIns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(checkInRepositoryProvider);
    final res = await repo.getMyCheckIns(limit: 100);
    final checkIns = res.getOrElse((_) => []);

    // Batch-fetch photo URLs so each card can show a thumbnail.
    final photoMap = await repo.photoUrlsByCheckIn(
      checkIns.map((c) => c.id).toList(),
    );
    final withPhotos = checkIns
        .map((c) => c.copyWith(photoUrls: photoMap[c.id] ?? const []))
        .toList();

    if (mounted) {
      setState(() {
        _checkIns = withPhotos;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My check-ins')),
      body: _loading
          ? const LoadingView()
          : _checkIns.isEmpty
              ? EmptyView(
                  icon: Icons.pin_drop_outlined,
                  message: 'No check-ins yet',
                  subtitle: 'Check in somewhere to start your trace.',
                  action: FilledButton.icon(
                    onPressed: () => context.push('/checkin?mode=checkin'),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Check in'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loading = true);
                    await _load();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _checkIns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (ctx, i) =>
                        _CheckInCard(checkIn: _checkIns[i]),
                  ),
                ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final CheckIn checkIn;
  const _CheckInCard({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final thumb =
        checkIn.photoUrls.isNotEmpty ? checkIn.photoUrls.first : null;
    final isPublic = checkIn.visibility == StampVisibility.public;
    final hasStamp = checkIn.stampId != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/check-in/${checkIn.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumb != null
                    ? CachedNetworkImage(
                        imageUrl: thumb,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _PlaceholderThumb(
                            source: checkIn.source),
                        errorWidget: (_, __, ___) =>
                            _PlaceholderThumb(source: checkIn.source),
                      )
                    : _PlaceholderThumb(source: checkIn.source),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Place + visibility icon
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            checkIn.placeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPublic)
                          const Icon(Icons.public,
                              size: 14, color: Colors.blue)
                        else
                          Icon(Icons.lock,
                              size: 14, color: Colors.grey[400]),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Date + time
                    Text(
                      DateFormat('EEE, MMM d · h:mm a')
                          .format(checkIn.visitedAt),
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12),
                    ),

                    // Note
                    if (checkIn.note != null &&
                        checkIn.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        checkIn.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Footer row: photo count + action button
                    Row(
                      children: [
                        if (checkIn.photoUrls.isNotEmpty) ...[
                          Icon(Icons.photo_library_outlined,
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text(
                            '${checkIn.photoUrls.length}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        if (hasStamp)
                          _ChipButton(
                            icon: Icons.collections_bookmark_outlined,
                            label: 'View stamp',
                            onTap: () => context
                                .push('/stamp/${checkIn.stampId}'),
                          )
                        else if (checkIn.source != CheckInSource.auto)
                          _ChipButton(
                            icon: Icons.auto_awesome,
                            label: 'Make stamp',
                            onTap: () => context.push(
                                '/checkin?fromCheckIn=${checkIn.id}'),
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
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  final CheckInSource source;
  const _PlaceholderThumb({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        source == CheckInSource.photo
            ? Icons.photo_camera_outlined
            : Icons.place,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChipButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
