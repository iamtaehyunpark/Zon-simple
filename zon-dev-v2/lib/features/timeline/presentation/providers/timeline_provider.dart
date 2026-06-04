import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/stamp.dart';
import '../../../../data/models/check_in.dart';
import '../../../../data/models/raw_location_event.dart';
import '../../../../data/repositories/stamp_repository.dart';
import '../../../../data/repositories/check_in_repository.dart';
import '../../../../data/repositories/location_repository.dart';
import '../../../../data/repositories/diary_repository.dart';
import '../../../../core/auth/auth_provider.dart';

part 'timeline_provider.g.dart';

/// Everything that happened on one day: the route line, the check-in pins,
/// and the stamps.
class DayBundle {
  final DateTime date;
  final List<RawLocationEvent> route;
  final List<CheckIn> checkIns;
  final List<Stamp> stamps;
  final String diary;
  const DayBundle({
    required this.date,
    this.route = const [],
    this.checkIns = const [],
    this.stamps = const [],
    this.diary = '',
  });

  bool get isEmpty => route.isEmpty && checkIns.isEmpty && stamps.isEmpty;
}

@riverpod
class TimelineNotifier extends _$TimelineNotifier {
  @override
  AsyncValue<DayBundle> build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Future.microtask(() => loadDay(today));
    return const AsyncValue.loading();
  }

  Future<void> loadDay(DateTime day) async {
    // Keep any current data visible while the new day loads so the map stays
    // mounted (no flicker / re-init) when navigating days.
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.data(DayBundle(date: day));
      return;
    }

    final stampRepo = ref.read(stampRepositoryProvider);
    final checkInRepo = ref.read(checkInRepositoryProvider);
    final locationRepo = ref.read(locationRepositoryProvider);

    final (stampsRes, checkInsRes, routeRes, diary) = await (
      stampRepo.getMyStampsForDay(day),
      checkInRepo.getForDay(day),
      locationRepo.getRouteForDay(day),
      ref.read(diaryRepositoryProvider).getDiary(day),
    ).wait;

    state = AsyncValue.data(DayBundle(
      date: day,
      stamps: stampsRes.getOrElse((_) => []),
      checkIns: checkInsRes.getOrElse((_) => []),
      route: routeRes.getOrElse((_) => []),
      diary: diary,
    ));
  }
}
