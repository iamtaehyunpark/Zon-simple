// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isFollowingHash() => r'97714e948fba0700ec89319d74821188a8bdc8d8';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [isFollowing].
@ProviderFor(isFollowing)
const isFollowingProvider = IsFollowingFamily();

/// See also [isFollowing].
class IsFollowingFamily extends Family<AsyncValue<bool>> {
  /// See also [isFollowing].
  const IsFollowingFamily();

  /// See also [isFollowing].
  IsFollowingProvider call(
    String targetUserId,
  ) {
    return IsFollowingProvider(
      targetUserId,
    );
  }

  @override
  IsFollowingProvider getProviderOverride(
    covariant IsFollowingProvider provider,
  ) {
    return call(
      provider.targetUserId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isFollowingProvider';
}

/// See also [isFollowing].
class IsFollowingProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [isFollowing].
  IsFollowingProvider(
    String targetUserId,
  ) : this._internal(
          (ref) => isFollowing(
            ref as IsFollowingRef,
            targetUserId,
          ),
          from: isFollowingProvider,
          name: r'isFollowingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isFollowingHash,
          dependencies: IsFollowingFamily._dependencies,
          allTransitiveDependencies:
              IsFollowingFamily._allTransitiveDependencies,
          targetUserId: targetUserId,
        );

  IsFollowingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.targetUserId,
  }) : super.internal();

  final String targetUserId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsFollowingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsFollowingProvider._internal(
        (ref) => create(ref as IsFollowingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        targetUserId: targetUserId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsFollowingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsFollowingProvider && other.targetUserId == targetUserId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, targetUserId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsFollowingRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `targetUserId` of this provider.
  String get targetUserId;
}

class _IsFollowingProviderElement extends AutoDisposeFutureProviderElement<bool>
    with IsFollowingRef {
  _IsFollowingProviderElement(super.provider);

  @override
  String get targetUserId => (origin as IsFollowingProvider).targetUserId;
}

String _$profileNotifierHash() => r'5bd3535bc927a9123a3092c49cc82c7f7326a399';

abstract class _$ProfileNotifier
    extends BuildlessAutoDisposeNotifier<AsyncValue<UserProfile?>> {
  late final String userId;

  AsyncValue<UserProfile?> build(
    String userId,
  );
}

/// See also [ProfileNotifier].
@ProviderFor(ProfileNotifier)
const profileNotifierProvider = ProfileNotifierFamily();

/// See also [ProfileNotifier].
class ProfileNotifierFamily extends Family<AsyncValue<UserProfile?>> {
  /// See also [ProfileNotifier].
  const ProfileNotifierFamily();

  /// See also [ProfileNotifier].
  ProfileNotifierProvider call(
    String userId,
  ) {
    return ProfileNotifierProvider(
      userId,
    );
  }

  @override
  ProfileNotifierProvider getProviderOverride(
    covariant ProfileNotifierProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'profileNotifierProvider';
}

/// See also [ProfileNotifier].
class ProfileNotifierProvider extends AutoDisposeNotifierProviderImpl<
    ProfileNotifier, AsyncValue<UserProfile?>> {
  /// See also [ProfileNotifier].
  ProfileNotifierProvider(
    String userId,
  ) : this._internal(
          () => ProfileNotifier()..userId = userId,
          from: profileNotifierProvider,
          name: r'profileNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$profileNotifierHash,
          dependencies: ProfileNotifierFamily._dependencies,
          allTransitiveDependencies:
              ProfileNotifierFamily._allTransitiveDependencies,
          userId: userId,
        );

  ProfileNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  AsyncValue<UserProfile?> runNotifierBuild(
    covariant ProfileNotifier notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(ProfileNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProfileNotifierProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ProfileNotifier, AsyncValue<UserProfile?>>
      createElement() {
    return _ProfileNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileNotifierProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProfileNotifierRef
    on AutoDisposeNotifierProviderRef<AsyncValue<UserProfile?>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _ProfileNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<ProfileNotifier,
        AsyncValue<UserProfile?>> with ProfileNotifierRef {
  _ProfileNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as ProfileNotifierProvider).userId;
}

String _$profileStampsNotifierHash() =>
    r'507520663eeff836de5cecc0411b07f71952fc71';

abstract class _$ProfileStampsNotifier
    extends BuildlessAutoDisposeNotifier<AsyncValue<List<Stamp>>> {
  late final String userId;

  AsyncValue<List<Stamp>> build(
    String userId,
  );
}

/// See also [ProfileStampsNotifier].
@ProviderFor(ProfileStampsNotifier)
const profileStampsNotifierProvider = ProfileStampsNotifierFamily();

/// See also [ProfileStampsNotifier].
class ProfileStampsNotifierFamily extends Family<AsyncValue<List<Stamp>>> {
  /// See also [ProfileStampsNotifier].
  const ProfileStampsNotifierFamily();

  /// See also [ProfileStampsNotifier].
  ProfileStampsNotifierProvider call(
    String userId,
  ) {
    return ProfileStampsNotifierProvider(
      userId,
    );
  }

  @override
  ProfileStampsNotifierProvider getProviderOverride(
    covariant ProfileStampsNotifierProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'profileStampsNotifierProvider';
}

/// See also [ProfileStampsNotifier].
class ProfileStampsNotifierProvider extends AutoDisposeNotifierProviderImpl<
    ProfileStampsNotifier, AsyncValue<List<Stamp>>> {
  /// See also [ProfileStampsNotifier].
  ProfileStampsNotifierProvider(
    String userId,
  ) : this._internal(
          () => ProfileStampsNotifier()..userId = userId,
          from: profileStampsNotifierProvider,
          name: r'profileStampsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$profileStampsNotifierHash,
          dependencies: ProfileStampsNotifierFamily._dependencies,
          allTransitiveDependencies:
              ProfileStampsNotifierFamily._allTransitiveDependencies,
          userId: userId,
        );

  ProfileStampsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  AsyncValue<List<Stamp>> runNotifierBuild(
    covariant ProfileStampsNotifier notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(ProfileStampsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProfileStampsNotifierProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ProfileStampsNotifier,
      AsyncValue<List<Stamp>>> createElement() {
    return _ProfileStampsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileStampsNotifierProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProfileStampsNotifierRef
    on AutoDisposeNotifierProviderRef<AsyncValue<List<Stamp>>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _ProfileStampsNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<ProfileStampsNotifier,
        AsyncValue<List<Stamp>>> with ProfileStampsNotifierRef {
  _ProfileStampsNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as ProfileStampsNotifierProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
