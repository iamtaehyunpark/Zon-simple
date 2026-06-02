import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/enums.dart';
import 'providers/timeline_provider.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    ref.read(timelineNotifierProvider.notifier).loadMonth(_selectedMonth);
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      return;
    }
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    ref.read(timelineNotifierProvider.notifier).loadMonth(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _prevMonth,
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'List'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _TimelineListView(timelineState: timelineState),
          _CalendarView(timelineState: timelineState, month: _selectedMonth),
        ],
      ),
    );
  }
}

class _TimelineListView extends StatelessWidget {
  final AsyncValue<List<DayData>> timelineState;
  const _TimelineListView({required this.timelineState});

  @override
  Widget build(BuildContext context) {
    return timelineState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (days) {
        if (days.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No stamps this month'),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: days.length,
          itemBuilder: (ctx, i) {
            final day = days[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    DateFormat('EEEE, MMM d').format(day.date),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                ...day.stamps.map((s) => ListTile(
                      leading: s.coverPhotoUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(s.coverPhotoUrl!))
                          : CircleAvatar(
                              backgroundColor:
                                  Theme.of(ctx).colorScheme.primaryContainer,
                              child: const Icon(Icons.place)),
                      title: Text(s.placeName),
                      subtitle: s.caption != null
                          ? Text(s.caption!,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
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
            );
          },
        );
      },
    );
  }
}

class _CalendarView extends StatelessWidget {
  final AsyncValue<List<DayData>> timelineState;
  final DateTime month;

  const _CalendarView({required this.timelineState, required this.month});

  @override
  Widget build(BuildContext context) {
    return timelineState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (days) {
        final stampsByDay = {
          for (final d in days) d.date.day: d.stamps.length,
        };
        final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
        final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (ctx, i) {
            if (i < firstWeekday) return const SizedBox.shrink();
            final day = i - firstWeekday + 1;
            final count = stampsByDay[day] ?? 0;
            final isToday = month.year == DateTime.now().year &&
                month.month == DateTime.now().month &&
                day == DateTime.now().day;
            return GestureDetector(
              onTap: count > 0 ? () {} : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday
                      ? Theme.of(ctx).colorScheme.primary
                      : count > 0
                          ? Theme.of(ctx).colorScheme.primaryContainer
                          : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.normal,
                        color: isToday
                            ? Theme.of(ctx).colorScheme.onPrimary
                            : null,
                      ),
                    ),
                    if (count > 0)
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday
                              ? Theme.of(ctx).colorScheme.onPrimary
                              : Theme.of(ctx).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
