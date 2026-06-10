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
    final res = await ref.read(profileRepositoryProvider).follow(targetUserId);
    await res.fold(
      (err) async => throw err,
      (_) async {
        await _fetch(userId);
        ref.invalidate(followStateProvider(targetUserId));
      },
    );
  }

  Future<void> sendFriendRequest() async {
    final res = await ref.read(profileRepositoryProvider).sendFriendRequest(userId);
    res.fold(
      (err) => throw err,
      (_) => ref.invalidate(friendStateProvider(userId)),
    );
  }

  Future<void> cancelFriendRequest() async {
    final res = await ref.read(profileRepositoryProvider).removeFriendship(userId);
    res.fold(
      (err) => throw err,
      (_) => ref.invalidate(friendStateProvider(userId)),
    );
  }

  Future<void> unfriend() async {
    final res = await ref.read(profileRepositoryProvider).removeFriendship(userId);
    await res.fold(
      (err) async => throw err,
      (_) async {
        await _fetch(userId);
        ref.invalidate(friendStateProvider(userId));
      },
    );
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
    result.fold(
      (e) => state = AsyncValue.error(e, StackTrace.current),
      (stamps) {
        _offset += stamps.length;
        _hasMore = stamps.length == _pageSize;
        state = AsyncValue.data([...current, ...stamps]);
      },
    );
    _loadingMore = false;
  }
}

@riverpod
Future<FollowState> followState(FollowStateRef ref, String targetUserId) async {
  return ref.watch(profileRepositoryProvider).followState(targetUserId);
}

@riverpod
Future<FriendState> friendState(FriendStateRef ref, String targetUserId) async {
  return ref.watch(profileRepositoryProvider).friendState(targetUserId);
}

@riverpod
Future<List<UserProfile>> followRequests(FollowRequestsRef ref) async {
  return ref.watch(profileRepositoryProvider).getFollowRequests();
}

@riverpod
Future<List<UserProfile>> friendRequests(FriendRequestsRef ref) async {
  return ref.watch(profileRepositoryProvider).getIncomingFriendRequests();
}
