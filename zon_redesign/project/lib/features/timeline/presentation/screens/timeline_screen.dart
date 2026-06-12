import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../feed/data/models/feed_item.dart';
import '../providers/timeline_provider.dart';
import '../../../../shared/widgets/tier_badge.dart';

/// Personal timeline — toggle between calendar grid and chronological list.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  bool _isCalendar = true;
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final timeline = ref.watch(timelineNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Timeline',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(
              _isCalendar ? Icons.view_list : Icons.calendar_month,
              color: Colors.white70,
            ),
            onPressed: () => setState(() => _isCalendar = !_isCalendar),
          ),
        ],
      ),
      body: !isLoggedIn
          ? const _SignInPrompt()
          : timeline.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1D9E75))),
              error: (e, _) => Center(
                  child: Text(e.toString(),
                      style: const TextStyle(color: Colors.white38))),
              data: (grouped) => grouped.isEmpty
                  ? const _EmptyTimeline()
                  : RefreshIndicator(
                      color: const Color(0xFF1D9E75),
                      backgroundColor: const Color(0xFF141414),
                      onRefresh: () =>
                          ref.read(timelineNotifierProvider.notifier).refresh(),
                      child: _isCalendar
                          ? _CalendarView(
                              grouped: grouped,
                              focusedMonth: _focusedMonth,
                              onMonthChanged: (m) =>
                                  setState(() => _focusedMonth = m),
                            )
                          : _ListView(grouped: grouped),
                    ),
            ),
    );
  }
}

// ── Calendar view ─────────────────────────────────────────────────────────────

class _CalendarView extends StatefulWidget {
  const _CalendarView({
    required this.grouped,
    required this.focusedMonth,
    required this.onMonthChanged,
  });
  final Map<DateTime, List<FeedItem>> grouped;
  final DateTime focusedMonth;
  final void Function(DateTime) onMonthChanged;

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final year  = widget.focusedMonth.year;
    final month = widget.focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = firstDay.weekday % 7; // 0=Sun

    final days = <DateTime?>[];
    for (var i = 0; i < firstWeekday; i++) days.add(null);
    for (var d = 1; d <= daysInMonth; d++) days.add(DateTime(year, month, d));

    final selectedItems = _selected != null
        ? widget.grouped[_selected!] ?? []
        : <FeedItem>[];

    return Column(children: [
      // Month nav
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
            onPressed: () => widget.onMonthChanged(
                DateTime(year, month - 1, 1)),
          ),
          Expanded(
            child: Text(
              '${_monthName(month)} $year',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white70),
            onPressed: () => widget.onMonthChanged(
                DateTime(year, month + 1, 1)),
          ),
        ]),
      ),

      // Weekday headers
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
            .map((d) => Expanded(
                  child: Center(
                    child: Text(d,
                        style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ))
            .toList()),
      ),

      const SizedBox(height: 4),

      // Calendar grid
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, childAspectRatio: 1),
          itemCount: days.length,
          itemBuilder: (_, i) {
            final day = days[i];
            if (day == null) return const SizedBox.shrink();

            final hasStamp = widget.grouped.containsKey(day);
            final isSelected = _selected == day;
            final isToday = DateUtils.isSameDay(day, DateTime.now());

            return GestureDetector(
              onTap: hasStamp
                  ? () => setState(() =>
                      _selected = isSelected ? null : day)
                  : null,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF1D9E75)
                        : hasStamp
                            ? const Color(0xFF1D9E75).withValues(alpha: 0.2)
                            : Colors.transparent,
                    border: isToday
                        ? Border.all(color: const Color(0xFF1D9E75), width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : hasStamp
                                ? const Color(0xFF1D9E75)
                                : Colors.white38,
                        fontSize: 12,
                        fontWeight: hasStamp
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // Selected day stamps
      if (_selected != null && selectedItems.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Divider(color: Color(0xFF2A2A2A), height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: selectedItems.length,
            itemBuilder: (_, i) => _StampRow(item: selectedItems[i]),
          ),
        ),
      ] else
        const Expanded(child: SizedBox.shrink()),
    ]);
  }

  static String _monthName(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun',
       'Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

// ── List view ─────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  const _ListView({required this.grouped});
  final Map<DateTime, List<FeedItem>> grouped;

  @override
  Widget build(BuildContext context) {
    final days = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final day = days[i];
        final items = grouped[day]!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _dateLabel(day),
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5),
            ),
          ),
          ...items.map((item) => _StampRow(item: item)),
        ]);
      },
    );
  }

  static String _dateLabel(DateTime d) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(d, now)) return 'TODAY';
    if (DateUtils.isSameDay(d, now.subtract(const Duration(days: 1)))) {
      return 'YESTERDAY';
    }
    return '${['SUN','MON','TUE','WED','THU','FRI','SAT'][d.weekday % 7]}, '
        '${['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'][d.month - 1]} ${d.day}';
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _StampRow extends StatelessWidget {
  const _StampRow({required this.item});
  final FeedItem item;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.pushNamed('stamp-detail',
            pathParameters: {'id': item.stampId}),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.place, color: Color(0xFF1D9E75), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.placeName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(item.placeCategory,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ]),
            ),
            TierBadge(tier: item.tier),
          ]),
        ),
      );
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, color: Colors.white24, size: 56),
          const SizedBox(height: 16),
          const Text('Your timeline lives here',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Sign in to see your verified places over time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pushNamed('login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign in'),
          ),
        ]),
      );
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_outlined,
              color: Colors.white24, size: 56),
          const SizedBox(height: 16),
          const Text('No stamps yet',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Verify a place to start your timeline.',
              style: TextStyle(color: Colors.white24, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.pushNamed('auth-cta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Verify a place'),
          ),
        ]),
      );
}
