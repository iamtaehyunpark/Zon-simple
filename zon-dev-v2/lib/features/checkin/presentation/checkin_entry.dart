import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/check_in.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../shared/widgets/app_states.dart';
import 'providers/checkin_provider.dart';
import 'stamp_editor.dart';
import 'check_in_editor.dart';

class CheckinEntry extends ConsumerStatefulWidget {
  final double? lat;
  final double? lng;
  final CheckinMode mode;
  // When set, the flow opens straight into the stamp editor pre-filled from
  // this existing check-in (promote-to-stamp as an editable step).
  final String? fromCheckInId;

  const CheckinEntry({
    super.key,
    this.lat,
    this.lng,
    this.mode = CheckinMode.checkIn,
    this.fromCheckInId,
  });

  @override
  ConsumerState<CheckinEntry> createState() => _CheckinEntryState();
}

class _CheckinEntryState extends ConsumerState<CheckinEntry> {
  final _searchCtrl = TextEditingController();
  List<ExternalPlace> _searchResults = [];
  bool _searching = false;
  CheckIn? _savedCheckIn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.fromCheckInId != null) {
        _startFromCheckIn(widget.fromCheckInId!);
      } else {
        ref
            .read(checkinNotifierProvider.notifier)
            .startCheckin(lat: widget.lat, lng: widget.lng, mode: widget.mode);
      }
    });
  }

  Future<void> _startFromCheckIn(String id) async {
    final repo = ref.read(checkInRepositoryProvider);
    final res = await repo.getCheckIn(id);
    final ci = res.fold((_) => null, (c) => c);
    if (ci == null) {
      if (mounted) {
        ref
            .read(checkinNotifierProvider.notifier)
            .startCheckin(mode: CheckinMode.stamp);
      }
      return;
    }
    final photos = await repo.getCheckInPhotos(id);
    if (!mounted) return;
    ref
        .read(checkinNotifierProvider.notifier)
        .startStampFromCheckIn(ci, [for (final p in photos) p.url]);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    final state = ref.read(checkinNotifierProvider);
    double lat = widget.lat ?? 0;
    double lng = widget.lng ?? 0;
    state.maybeWhen(
      placeSelected: (sLat, sLng, _, __, ___) {
        lat = sLat;
        lng = sLng;
      },
      orElse: () {},
    );
    final results = await ref
        .read(checkinNotifierProvider.notifier)
        .searchPlaces(lat, lng, q);
    if (mounted) setState(() { _searchResults = results; _searching = false; });
  }

  @override
  Widget build(BuildContext context) {
    final checkinState = ref.watch(checkinNotifierProvider);
    final isStamp =
        widget.mode == CheckinMode.stamp || widget.fromCheckInId != null;

    Widget mainContent = checkinState.when(
      idle: () => const Center(child: CircularProgressIndicator(color: Z.brand)),
      locating: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Z.brand),
            SizedBox(height: 16),
            Text('Finding your location...', style: TextStyle(color: Z.textMuted)),
          ],
        ),
      ),
      placeSelected:
          (lat, lng, nearbyStamps, suggestedPlace, placeSuggestions) =>
              _PlaceSelectionBody(
        lat: lat,
        lng: lng,
        suggestedPlace: suggestedPlace,
        placeSuggestions: placeSuggestions,
        nearbyStamps: nearbyStamps,
        searchCtrl: _searchCtrl,
        searchResults: _searchResults,
        searching: _searching,
        onSearch: _search,
        onSelectPlace: (place) {
          ref.read(checkinNotifierProvider.notifier).beginEditing(place);
        },
        onSkipPlace: () {
          ref.read(checkinNotifierProvider.notifier).beginEditing(null);
        },
      ),
      editingCheckIn: (draft) => CheckInEditorBody(
        draft: draft,
        onUpdate: (d) =>
            ref.read(checkinNotifierProvider.notifier).updateCheckInDraft(d),
        onSave: () => ref.read(checkinNotifierProvider.notifier).save(),
      ),
      editingStamp: (draft) => StampEditorBody(
        draft: draft,
        nearbyStamps: const [],
        onUpdate: (d) =>
            ref.read(checkinNotifierProvider.notifier).updateStampDraft(d),
        onSave: () => ref.read(checkinNotifierProvider.notifier).save(),
      ),
      saving: () => const Center(child: CircularProgressIndicator(color: Z.brand)),
      completeCheckIn: (checkIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _savedCheckIn == null) {
            setState(() {
              _savedCheckIn = checkIn;
            });
          }
        });
        if (_savedCheckIn != null) {
          return _buildConfirmBody(context, _savedCheckIn!);
        }
        return const Center(child: CircularProgressIndicator(color: Z.brand));
      },
      completeStamp: (stampId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(checkinNotifierProvider.notifier).reset();
          context.pop();
          context.push('/stamp/$stampId');
        });
        return const Center(child: CircularProgressIndicator(color: Z.brand));
      },
      error: (msg) => ErrorView(
        message: msg,
        onRetry: () => ref.read(checkinNotifierProvider.notifier).startCheckin(
            lat: widget.lat, lng: widget.lng, mode: widget.mode),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0x7F000000), // semi-transparent black
      body: Column(
        children: [
          // Top peek area (tapping dismisses)
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(checkinNotifierProvider.notifier).reset();
                context.pop();
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          // Bottom sheet container
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Z.surface1,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              children: [
                // Bottom Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Z.outline2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Custom Step Headers
                if (checkinState.maybeWhen(
                  editingCheckIn: (_) => true,
                  editingStamp: (_) => true,
                  orElse: () => false,
                )) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            ref.read(checkinNotifierProvider.notifier).startCheckin(
                              lat: widget.lat,
                              lng: widget.lng,
                              mode: widget.mode,
                            );
                          },
                          child: const Icon(Icons.arrow_back, color: Z.text),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            checkinState.maybeWhen(
                              editingCheckIn: (draft) => draft.placeName,
                              editingStamp: (draft) => draft.placeName,
                              orElse: () => 'Edit Check-in',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Z.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Z.outline),
                ] else if (checkinState.maybeWhen(
                  placeSelected: (_, __, ___, ____, _____) => true,
                  orElse: () => false,
                )) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isStamp ? 'Create Stamp' : 'Add a Check-in',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Z.text,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(checkinNotifierProvider.notifier).reset();
                            context.pop();
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Z.surface2,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Z.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Step body
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: mainContent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBody(BuildContext context, CheckIn checkIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Z.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 34,
              color: Z.brand,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Checked in!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Z.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            checkIn.placeName,
            style: const TextStyle(
              fontSize: 14,
              color: Z.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    ref.read(checkinNotifierProvider.notifier).reset();
                    context.pop();
                    context.push('/checkin?mode=stamp&fromCheckIn=${checkIn.id}');
                  },
                  child: const Text('Make it a stamp →'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(checkinNotifierProvider.notifier).reset();
                    context.pop();
                    context.go('/timeline');
                  },
                  child: const Text(
                    'View in Timeline',
                    style: TextStyle(color: Z.text, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    ref.read(checkinNotifierProvider.notifier).reset();
                    context.pop();
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Z.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceSelectionBody extends StatelessWidget {
  final double lat;
  final double lng;
  final ExternalPlace? suggestedPlace;
  final List<ExternalPlace> placeSuggestions;
  final List<Stamp> nearbyStamps;
  final TextEditingController searchCtrl;
  final List<ExternalPlace> searchResults;
  final bool searching;
  final void Function(String) onSearch;
  final void Function(ExternalPlace) onSelectPlace;
  final VoidCallback onSkipPlace;

  const _PlaceSelectionBody({
    required this.lat,
    required this.lng,
    required this.suggestedPlace,
    required this.placeSuggestions,
    required this.nearbyStamps,
    required this.searchCtrl,
    required this.searchResults,
    required this.searching,
    required this.onSearch,
    required this.onSelectPlace,
    required this.onSkipPlace,
  });

  @override
  Widget build(BuildContext context) {
    final displayPlaces =
        searchResults.isNotEmpty ? searchResults : placeSuggestions;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: searchCtrl,
            onSubmitted: onSearch,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14, color: Z.text),
            decoration: InputDecoration(
              hintText: 'Where are you?',
              prefixIcon: const Icon(Icons.search, color: Z.textMuted),
              suffixIcon: searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Z.brand),
                      ),
                    )
                  : searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Z.textMuted),
                          onPressed: () {
                            searchCtrl.clear();
                            onSearch('');
                          },
                        )
                      : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: onSkipPlace,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Z.brandSoft2,
                border: Border.all(color: Z.brand, width: 1.5),
                borderRadius: Z.r12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Z.brand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Use current location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Z.text,
                          ),
                        ),
                        Text(
                          suggestedPlace != null
                              ? '${suggestedPlace!.name} · nearby'
                              : 'Check in right where you are',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Z.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (nearbyStamps.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.history, size: 14, color: Z.textMuted),
                SizedBox(width: 6),
                Text(
                  "You've been here before",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Z.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: nearbyStamps.length,
              itemBuilder: (ctx, i) {
                final s = nearbyStamps[i];
                return GestureDetector(
                  onTap: () => onSelectPlace(ExternalPlace(
                    externalPlaceId: s.externalPlaceId ?? '',
                    externalSource: s.externalSource ?? 'existing',
                    name: s.placeName,
                    lat: s.lat,
                    lng: s.lng,
                  )),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Z.brandSoft,
                      border: Border.all(color: Z.outline),
                      borderRadius: Z.r12,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.placeName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Z.brand,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.visitedAt.day}/${s.visitedAt.month}/${s.visitedAt.year}',
                          style: const TextStyle(fontSize: 11, color: Z.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Z.outline),
        ],
        Expanded(
          child: ListView.builder(
            itemCount: displayPlaces.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (ctx, i) {
              final place = displayPlaces[i];
              String emoji = '📍';
              if (place.address?.contains('Café') == true || place.name.toLowerCase().contains('coffee')) {
                emoji = '☕';
              } else if (place.name.toLowerCase().contains('park') || place.name.toLowerCase().contains('river')) {
                emoji = '🌿';
              } else if (place.name.toLowerCase().contains('market') || place.name.toLowerCase().contains('store')) {
                emoji = '🏬';
              } else if (place.name.toLowerCase().contains('pasta') || place.name.toLowerCase().contains('pizza') || place.name.toLowerCase().contains('restaurant')) {
                emoji = '🍝';
              } else if (place.name.toLowerCase().contains('music') || place.name.toLowerCase().contains('records')) {
                emoji = '🎵';
              }
              
              return GestureDetector(
                onTap: () => onSelectPlace(place),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Z.outline)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Z.text,
                              ),
                            ),
                            if (place.address != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                place.address!,
                                style: const TextStyle(fontSize: 12, color: Z.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Z.textFaint,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
