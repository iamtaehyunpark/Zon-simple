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
    ref.invalidate(isFollowingProvider(targetUserId));
  }
}

@riverpod
class ProfileStampsNotifier extends _$ProfileStampsNotifier {
  @override
  AsyncValue<List<Stamp>> build(String userId, {bool publicOnly = true}) {
    Future.microtask(() => _fetch(userId, publicOnly));
    return const AsyncValue.loading();
  }

  Future<void> _fetch(String userId, bool publicOnly) async {
    final result = await ref
        .read(stampRepositoryProvider)
        .getUserStamps(userId, publicOnly: publicOnly);
    state = result.fold(
      (err) => AsyncError(err, StackTrace.current),
      AsyncValue.data,
    );
  }
}

@riverpod
Future<bool> isFollowing(IsFollowingRef ref, String targetUserId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.isFollowing(targetUserId);
}
