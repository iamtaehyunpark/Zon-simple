import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/models/stamp.dart';
import '../../../../data/repositories/stamp_repository.dart';
import '../../../../data/repositories/profile_repository.dart';

part 'profile_provider.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  AsyncValue<UserProfile?> build(String userId) {
    Future.microtask(() => _fetch(userId));
    return const AsyncValue.loading();
  }

  Future<void> _fetch(String userId) async {
    final result = await ref.read(profileRepositoryProvider).getProfile(userId);
    state = result.fold(
      (err) => AsyncError(err, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<void> toggleFollow(String targetUserId) async {
    await ref.read(profileRepositoryProvider).follow(targetUserId);
    await _fetch(userId);
    ref.invalidate(followStateProvider(targetUserId));
  }
}

@riverpod
class ProfileStampsNotifier extends _$ProfileStampsNotifier {
  static const _pageSize = 30;
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  AsyncValue<List<Stamp>> build(String userId, {bool publicOnly = true}) {
    Future.microtask(() => _fetch(userId, publicOnly));
    return const AsyncValue.loading();
  }

  Future<void> _fetch(String userId, bool publicOnly) async {
    _offset = 0;
    _hasMore = true;
    final result = await ref
        .read(stampRepositoryProvider)
        .getUserStamps(userId, publicOnly: publicOnly, offset: 0);
    state = result.fold(
      (err) => AsyncError(err, StackTrace.current),
      (stamps) {
        _offset = stamps.length;
        _hasMore = stamps.length == _pageSize;
        return AsyncValue.data(stamps);
      },
    );
  }

  Future<void> loadMore(String userId, {bool publicOnly = true}) async {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    final current = state.valueOrNull ?? [];
    final result = await ref.read(stampRepositoryProvider).getUserStamps(
        userId,
        publicOnly: publicOnly,
        offset: _offset);
    result.fold((_) {}, (stamps) {
      _offset += stamps.length;
      _hasMore = stamps.length == _pageSize;
      state = AsyncValue.data([...current, ...stamps]);
    });
    _loadingMore = false;
  }
}

@riverpod
Future<FollowState> followState(FollowStateRef ref, String targetUserId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.followState(targetUserId);
}

@riverpod
Future<List<UserProfile>> followRequests(FollowRequestsRef ref) async {
  return ref.watch(profileRepositoryProvider).getFollowRequests();
}
