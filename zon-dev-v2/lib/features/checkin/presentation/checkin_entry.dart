import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/stamp.dart';
import 'providers/checkin_provider.dart';
import 'stamp_editor.dart';
import 'check_in_editor.dart';

class CheckinEntry extends ConsumerStatefulWidget {
  final double? lat;
  final double? lng;
  final CheckinMode mode;

  const CheckinEntry({
    super.key,
    this.lat,
    this.lng,
    this.mode = CheckinMode.checkIn,
  });

  @override
  ConsumerState<CheckinEntry> createState() => _CheckinEntryState();
}

class _CheckinEntryState extends ConsumerState<CheckinEntry> {
  final _searchCtrl = TextEditingController();
  List<ExternalPlace> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(checkinNotifierProvider.notifier)
          .startCheckin(lat: widget.lat, lng: widget.lng, mode: widget.mode);
    });
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
    final isStamp = widget.mode == CheckinMode.stamp;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStamp ? 'Create Stamp' : 'Check In'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(checkinNotifierProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: checkinState.when(
        idle: () => const Center(child: CircularProgressIndicator()),
        locating: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finding your location...'),
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
        saving: () => const Center(child: CircularProgressIndicator()),
        completeCheckIn: (checkIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Checked in at ${checkIn.placeName}')),
            );
            ref.read(checkinNotifierProvider.notifier).reset();
            context.pop();
          });
          return const Center(child: CircularProgressIndicator());
        },
        completeStamp: (stampId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(checkinNotifierProvider.notifier).reset();
            context.pop();
            context.push('/stamp/$stampId');
          });
          return const Center(child: CircularProgressIndicator());
        },
        error: (msg) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(msg, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(checkinNotifierProvider.notifier)
                    .startCheckin(
                        lat: widget.lat, lng: widget.lng, mode: widget.mode),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchCtrl,
            onSubmitted: onSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search for a place...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => onSearch(searchCtrl.text),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
          ),
        ),
        if (nearbyStamps.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.history, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'You\'ve been here before',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
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
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.placeName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${s.visitedAt.day}/${s.visitedAt.month}/${s.visitedAt.year}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
        ],
        Expanded(
          child: ListView.builder(
            itemCount: displayPlaces.length + 1,
            itemBuilder: (ctx, i) {
              if (i == displayPlaces.length) {
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Use current location'),
                  subtitle: const Text('No specific place'),
                  onTap: onSkipPlace,
                );
              }
              final place = displayPlaces[i];
              return ListTile(
                leading: const Icon(Icons.place),
                title: Text(place.name),
                subtitle: place.address != null ? Text(place.address!) : null,
                onTap: () => onSelectPlace(place),
              );
            },
          ),
        ),
      ],
    );
  }
}
