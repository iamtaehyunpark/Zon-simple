import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/places/place_models.dart';
import '../../core/places/place_service_provider.dart';

/// A text field that shows a coordinate-anchored place dropdown on focus.
///
/// Top item is always "Use coordinates" — either the auto-resolved nearby name
/// (when field is empty) or the user's typed text (as a custom place name).
/// Remaining items are nearby / text-search results from the place service.
///
/// Coordinates are fixed at construction time and never change (the lat/lng
/// is from when the node was originally created, not the current GPS position).
class PlaceSearchField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final double lat;
  final double lng;
  final String labelText;
  final ValueChanged<String>? onChanged;

  const PlaceSearchField({
    super.key,
    required this.controller,
    required this.lat,
    required this.lng,
    this.labelText = 'Place',
    this.onChanged,
  });

  @override
  ConsumerState<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends ConsumerState<PlaceSearchField> {
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  List<PlaceResult> _nearby = [];
  List<PlaceResult> _searchResults = [];
  bool _loadingNearby = false;
  bool _searching = false;
  String _coordName = ''; // first nearby result — the "coordinate" label
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounce?.cancel();
    _overlay?.remove();
    super.dispose();
  }

  // ── Focus ─────────────────────────────────────────────────────────────────

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
      if (_nearby.isEmpty && !_loadingNearby) _loadNearby();
    } else {
      // Short delay so tapping a list item registers before the overlay closes.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  // ── Network ───────────────────────────────────────────────────────────────

  Future<void> _loadNearby() async {
    _loadingNearby = true;
    _rebuild();
    try {
      final svc = ref.read(placeServiceForProvider(widget.lat, widget.lng));
      _nearby = await svc.nearby(widget.lat, widget.lng);
      if (_nearby.isNotEmpty) _coordName = _nearby.first.name;
    } catch (_) {}
    _loadingNearby = false;
    if (mounted) _rebuild();
  }

  void _onTextChanged(String text) {
    widget.onChanged?.call(text);
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      _searchResults = [];
      _rebuild();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text.trim()));
  }

  Future<void> _search(String query) async {
    _searching = true;
    _rebuild();
    try {
      final svc = ref.read(placeServiceForProvider(widget.lat, widget.lng));
      _searchResults = await svc.search(query, widget.lat, widget.lng);
    } catch (_) {}
    _searching = false;
    if (mounted) _rebuild();
  }

  // ── Overlay ───────────────────────────────────────────────────────────────

  void _showOverlay() {
    _overlay?.remove();
    final entry = OverlayEntry(builder: _buildDropdown);
    _overlay = entry;
    Overlay.of(context).insert(entry);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _rebuild() => _overlay?.markNeedsBuild();

  void _select(String name) {
    widget.controller.text = name;
    widget.controller.selection =
        TextSelection.fromPosition(TextPosition(offset: name.length));
    widget.onChanged?.call(name);
    _focusNode.unfocus();
  }

  Widget _buildDropdown(BuildContext ctx) {
    final typed = widget.controller.text.trim();
    final hasTyped = typed.isNotEmpty;
    // Top label: typed text (custom name) OR coordinate-resolved name
    final topLabel =
        hasTyped ? typed : (_coordName.isNotEmpty ? _coordName : 'Nearby location');
    final topSub = hasTyped ? 'Custom name' : 'Coordinate-based';

    final listItems = (hasTyped ? _searchResults : _nearby)
        .where((p) => p.name != topLabel)
        .take(5)
        .toList();

    return Positioned.fill(
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 2),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(10)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top: coordinate / custom option ──────────────────────
                  InkWell(
                    onTap: () => _select(topLabel),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          Icon(Icons.my_location,
                              size: 18,
                              color: Theme.of(ctx).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(topLabel,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                Text(topSub,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 14, endIndent: 14),
                  // ── Nearby / search results ───────────────────────────────
                  if (_loadingNearby || _searching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    for (final place in listItems)
                      InkWell(
                        onTap: () => _select(place.name),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(place.name,
                                        style: const TextStyle(
                                            fontSize: 14)),
                                    if (place.address != null &&
                                        place.address!.isNotEmpty)
                                      Text(place.address!,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600]),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: _onTextChanged,
        decoration: InputDecoration(
          labelText: widget.labelText,
          prefixIcon: const Icon(Icons.place_outlined),
          border: const OutlineInputBorder(),
          suffixIcon: (_loadingNearby || _searching)
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
