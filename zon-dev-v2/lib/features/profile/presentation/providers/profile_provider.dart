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
    Future.microtask(() => loadProfile(userId));
    return const AsyncValue.loading();
  }

  Future<void> loadProfile(String userId) async {
    state = const AsyncValue.loading();
    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.getProfile(userId);
    state = result.fold(
      (err) => AsyncError(err, StackTrace.current),
      (profile) => AsyncValue.data(profile),
    );
  }

  Future<void> toggleFollow(String targetUserId) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.follow(targetUserId);
    await loadProfile(targetUserId);
    ref.invalidate(isFollowingProvider(targetUserId));
  }
}

@riverpod
class ProfileStampsNotifier extends _$ProfileStampsNotifier {
  @override
  AsyncValue<List<Stamp>> build(String userId) {
    Future.microtask(() => loadStamps(userId));
    return const AsyncValue.loading();
  }

  Future<void> loadStamps(String userId) async {
    state = const AsyncValue.loading();
    final repo = ref.read(stampRepositoryProvider);
    final result = await repo.getUserStamps(userId, publicOnly: true);
    state = result.fold(
      (err) => AsyncError(err, StackTrace.current),
      (stamps) => AsyncValue.data(stamps),
    );
  }
}

@riverpod
Future<bool> isFollowing(IsFollowingRef ref, String targetUserId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.isFollowing(targetUserId);
}
