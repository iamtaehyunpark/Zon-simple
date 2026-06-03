import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/stamp.dart';
import '../../../../data/repositories/stamp_repository.dart';
import '../../../../core/auth/auth_provider.dart';

part 'timeline_provider.g.dart';

class DayData {
  final DateTime date;
  final List<Stamp> stamps;

  const DayData({required this.date, required this.stamps});
}

@riverpod
class TimelineNotifier extends _$TimelineNotifier {
  @override
  AsyncValue<List<DayData>> build() {
    Future.microtask(() => loadMonth(DateTime.now()));
    return const AsyncValue.loading();
  }

  Future<void> loadMonth(DateTime month) async {
    state = const AsyncValue.loading();
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    final stampRepo = ref.read(stampRepositoryProvider);
    final stampsResult = await stampRepo.getMyStamps(limit: 200);
    final stamps = stampsResult.getOrElse((_) => []);

    final monthStamps = stamps.where((s) =>
        s.visitedAt.year == month.year && s.visitedAt.month == month.month);

    final grouped = <DateTime, List<Stamp>>{};
    for (final s in monthStamps) {
      final day = DateTime(s.visitedAt.year, s.visitedAt.month, s.visitedAt.day);
      grouped.putIfAbsent(day, () => []).add(s);
    }

    final days = grouped.entries
        .map((e) => DayData(date: e.key, stamps: e.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    state = AsyncValue.data(days);
  }
}
