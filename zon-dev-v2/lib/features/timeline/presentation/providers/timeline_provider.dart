import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/stamp.dart';
import '../../../../data/models/check_in.dart';
import '../../../../data/models/raw_location_event.dart';
import '../../../../data/repositories/stamp_repository.dart';
import '../../../../data/repositories/check_in_repository.dart';
import '../../../../data/repositories/location_repository.dart';
import '../../../../data/repositories/diary_repository.dart';
import '../../../../data/repositories/timeline_note_repository.dart';
import '../../../../core/auth/auth_provider.dart';

part 'timeline_provider.g.dart';

/// Everything that happened on one day: route line, check-in pins, stamps,
/// free-text note nodes, and the day's diary.
class DayBundle {
  final DateTime date;
  final List<RawLocationEvent> route;
  final List<CheckIn> checkIns;
  final List<Stamp> stamps;
  final List<TimelineNote> notes;
  final String diary;
  const DayBundle({
    required this.date,
    this.route = const [],
    this.checkIns = const [],
    this.stamps = const [],
    this.notes = const [],
    this.diary = '',
  });

  bool get isEmpty =>
      route.isEmpty && checkIns.isEmpty && stamps.isEmpty && notes.isEmpty;
}

@Riverpod(keepAlive: true)
class TimelineNotifier extends _$TimelineNotifier {
  @override
  AsyncValue<DayBundle> build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Future.microtask(() => loadDay(today));
    return const AsyncValue.loading();
  }

  Future<void> loadDay(DateTime day) async {
    // Keep current data visible while loading so the map stays mounted.
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.data(DayBundle(date: day));
      return;
    }

    final stampRepo = ref.read(stampRepositoryProvider);
    final checkInRepo = ref.read(checkInRepositoryProvider);
    final locationRepo = ref.read(locationRepositoryProvider);

    final (stampsRes, checkInsRes, routeRes, diary, notes) = await (
      stampRepo.getMyStampsForDay(day),
      checkInRepo.getForDay(day),
      locationRepo.getRouteForDay(day),
      ref.read(diaryRepositoryProvider).getDiary(day),
      ref.read(timelineNoteRepositoryProvider).getForDay(day),
    ).wait;

    var checkIns = checkInsRes.getOrElse((_) => <CheckIn>[]);
    var stamps = stampsRes.getOrElse((_) => <Stamp>[]);

    // Attach photo URLs so list nodes can show thumbnails.
    final (ciPhotos, stPhotos) = await (
      checkInRepo.photoUrlsByCheckIn([for (final c in checkIns) c.id]),
      stampRepo.photoUrlsByStamp([for (final s in stamps) s.id]),
    ).wait;
    checkIns = [
      for (final c in checkIns)
        c.copyWith(photoUrls: ciPhotos[c.id] ?? const [])
    ];
    stamps = [
      for (final s in stamps)
        s.copyWith(photoUrls: stPhotos[s.id] ?? const [])
    ];

    state = AsyncValue.data(DayBundle(
      date: day,
      stamps: stamps,
      checkIns: checkIns,
      route: routeRes.getOrElse((_) => []),
      notes: notes,
      diary: diary,
    ));
  }
}
