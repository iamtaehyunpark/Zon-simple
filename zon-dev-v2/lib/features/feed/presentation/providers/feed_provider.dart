import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/stamp.dart';
import '../../../../data/repositories/stamp_repository.dart';

part 'feed_provider.g.dart';

@riverpod
class FeedNotifier extends _$FeedNotifier {
  static const _pageSize = 30;
  int _offset = 0;
  bool _hasMore = true;

  @override
  AsyncValue<List<Stamp>> build() {
    Future.microtask(_load);
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    _offset = 0;
    _hasMore = true;
    final repo = ref.read(stampRepositoryProvider);
    final result = await repo.getFeedStamps(limit: _pageSize, offset: 0);
    state = result.fold(
      (err) => AsyncError(err, StackTrace.current),
      (stamps) {
        _offset = stamps.length;
        _hasMore = stamps.length == _pageSize;
        return AsyncValue.data(stamps);
      },
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    final repo = ref.read(stampRepositoryProvider);
    final result =
        await repo.getFeedStamps(limit: _pageSize, offset: _offset);
    result.fold(
      (_) => null,
      (stamps) {
        _offset += stamps.length;
        _hasMore = stamps.length == _pageSize;
        state = AsyncValue.data([...current, ...stamps]);
      },
    );
  }

  Future<void> refresh() => _load();

  Future<void> toggleLike(String stampId) async {
    final repo = ref.read(stampRepositoryProvider);
    await repo.toggleLike(stampId);
    // Optimistic update
    state = state.whenData((stamps) => stamps.map((s) {
          if (s.id != stampId) return s;
          final liked = !s.isLiked;
          return s.copyWith(
            isLiked: liked,
            likeCount: liked ? s.likeCount + 1 : s.likeCount - 1,
          );
        }).toList());
  }
}
