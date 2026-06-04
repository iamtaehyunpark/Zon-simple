import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/app_states.dart';
import '../../map/presentation/map_drawing.dart';
import 'day_route_map.dart';
import 'providers/timeline_provider.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _day = DateTime(n.year, n.month, n.day);
  }

  bool get _isToday {
    final n = DateTime.now();
    return _day.year == n.year && _day.month == n.month && _day.day == n.day;
  }

  void _load(DateTime d) {
    setState(() => _day = d);
    ref.read(timelineNotifierProvider.notifier).loadDay(d);
  }

  void _shift(int days) {
    final next = _day.add(Duration(days: days));
    final n = DateTime.now();
    if (next.isAfter(DateTime(n.year, n.month, n.day))) return; // no future
    _load(next);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _load(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1)),
            TextButton(
              onPressed: _pickDate,
              child: Text(
                _isToday ? 'Today' : DateFormat('EEE, MMM d').format(_day),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _isToday ? null : () => _shift(1),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.calendar_month), onPressed: _pickDate),
        ],
      ),
      body: state.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
        data: (bundle) => _DayView(bundle: bundle),
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  final DayBundle bundle;
  const _DayView({required this.bundle});

  @override
  Widget build(BuildContext context) {
    if (bundle.isEmpty) {
      final now = DateTime.now();
      final isToday = bundle.date.year == now.year &&
          bundle.date.month == now.month &&
          bundle.date.day == now.day;
      return EmptyView(
        icon: Icons.map_outlined,
        message: 'Nothing logged this day',
        subtitle: 'Check in or add a stamp to see it here.',
        action: isToday
            ? FilledButton.icon(
                onPressed: () => context.push('/checkin?mode=checkin'),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Check in'),
              )
            : null,
      );
    }

    final pins = <MapPin>[
      for (final c in bundle.checkIns)
        MapPin(
            id: c.id,
            kind: 'checkin',
            name: c.placeName,
            lat: c.lat,
            lng: c.lng),
      for (final s in bundle.stamps)
        MapPin(
            id: s.id,
            kind: 'stamp',
            name: s.placeName,
            lat: s.lat,
            lng: s.lng),
    ];

    return ListView(
      children: [
        if (bundle.route.length >= 2 || pins.isNotEmpty)
          SizedBox(
            height: 240,
            child: DayRouteMap(route: bundle.route, pins: pins),
          ),
        if (bundle.checkIns.isNotEmpty) ...[
          const _SectionHeader('Check-ins'),
          ...bundle.checkIns.map((c) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.pin_drop)),
                title: Text(c.placeName),
                subtitle: Text([
                  DateFormat('h:mm a').format(c.visitedAt),
                  if (c.note != null && c.note!.isNotEmpty) c.note!,
                ].join(' · ')),
                trailing: c.photoCount > 0
                    ? Text('${c.photoCount} 📷',
                        style: const TextStyle(fontSize: 12))
                    : null,
              )),
        ],
        if (bundle.stamps.isNotEmpty) ...[
          const _SectionHeader('Stamps'),
          ...bundle.stamps.map((s) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.auto_awesome),
                ),
                title: Text(s.placeName),
                subtitle: Text(DateFormat('h:mm a').format(s.visitedAt)),
                trailing: Icon(
                  s.visibility == StampVisibility.public
                      ? Icons.public
                      : Icons.lock,
                  size: 16,
                  color: Colors.grey,
                ),
                onTap: () => context.push('/stamp/${s.id}'),
              )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }
}
