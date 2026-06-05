// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followStateHash() => r'9b23ea8dfd9b49a21be2b14de99b7c899716a7ba';

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

/// See also [followState].
@ProviderFor(followState)
const followStateProvider = FollowStateFamily();

/// See also [followState].
class FollowStateFamily extends Family<AsyncValue<FollowState>> {
  /// See also [followState].
  const FollowStateFamily();

  /// See also [followState].
  FollowStateProvider call(
    String targetUserId,
  ) {
    return FollowStateProvider(
      targetUserId,
    );
  }

  @override
  FollowStateProvider getProviderOverride(
    covariant FollowStateProvider provider,
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
  String? get name => r'followStateProvider';
}

/// See also [followState].
class FollowStateProvider extends AutoDisposeFutureProvider<FollowState> {
  /// See also [followState].
  FollowStateProvider(
    String targetUserId,
  ) : this._internal(
          (ref) => followState(
            ref as FollowStateRef,
            targetUserId,
          ),
          from: followStateProvider,
          name: r'followStateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$followStateHash,
          dependencies: FollowStateFamily._dependencies,
          allTransitiveDependencies:
              FollowStateFamily._allTransitiveDependencies,
          targetUserId: targetUserId,
        );

  FollowStateProvider._internal(
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
    FutureOr<FollowState> Function(FollowStateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowStateProvider._internal(
        (ref) => create(ref as FollowStateRef),
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
  AutoDisposeFutureProviderElement<FollowState> createElement() {
    return _FollowStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowStateProvider && other.targetUserId == targetUserId;
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
mixin FollowStateRef on AutoDisposeFutureProviderRef<FollowState> {
  /// The parameter `targetUserId` of this provider.
  String get targetUserId;
}

class _FollowStateProviderElement
    extends AutoDisposeFutureProviderElement<FollowState> with FollowStateRef {
  _FollowStateProviderElement(super.provider);

  @override
  String get targetUserId => (origin as FollowStateProvider).targetUserId;
}

String _$followRequestsHash() => r'7767b4a5e0f39606771fc4a84ac038d653bcb507';

/// See also [followRequests].
@ProviderFor(followRequests)
final followRequestsProvider =
    AutoDisposeFutureProvider<List<UserProfile>>.internal(
  followRequests,
  name: r'followRequestsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followRequestsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FollowRequestsRef = AutoDisposeFutureProviderRef<List<UserProfile>>;
String _$profileNotifierHash() => r'adf6208cd39d7270be7201f064b6a802ddcb1684';

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
    r'9a054010a5a948c975e14075b1207a12c4ef777f';

abstract class _$ProfileStampsNotifier
    extends BuildlessAutoDisposeNotifier<AsyncValue<List<Stamp>>> {
  late final String userId;
  late final bool publicOnly;

  AsyncValue<List<Stamp>> build(
    String userId, {
    bool publicOnly = true,
  });
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
    String userId, {
    bool publicOnly = true,
  }) {
    return ProfileStampsNotifierProvider(
      userId,
      publicOnly: publicOnly,
    );
  }

  @override
  ProfileStampsNotifierProvider getProviderOverride(
    covariant ProfileStampsNotifierProvider provider,
  ) {
    return call(
      provider.userId,
      publicOnly: provider.publicOnly,
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
    String userId, {
    bool publicOnly = true,
  }) : this._internal(
          () => ProfileStampsNotifier()
            ..userId = userId
            ..publicOnly = publicOnly,
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
          publicOnly: publicOnly,
        );

  ProfileStampsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.publicOnly,
  }) : super.internal();

  final String userId;
  final bool publicOnly;

  @override
  AsyncValue<List<Stamp>> runNotifierBuild(
    covariant ProfileStampsNotifier notifier,
  ) {
    return notifier.build(
      userId,
      publicOnly: publicOnly,
    );
  }

  @override
  Override overrideWith(ProfileStampsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProfileStampsNotifierProvider._internal(
        () => create()
          ..userId = userId
          ..publicOnly = publicOnly,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        publicOnly: publicOnly,
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
    return other is ProfileStampsNotifierProvider &&
        other.userId == userId &&
        other.publicOnly == publicOnly;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, publicOnly.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProfileStampsNotifierRef
    on AutoDisposeNotifierProviderRef<AsyncValue<List<Stamp>>> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `publicOnly` of this provider.
  bool get publicOnly;
}

class _ProfileStampsNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<ProfileStampsNotifier,
        AsyncValue<List<Stamp>>> with ProfileStampsNotifierRef {
  _ProfileStampsNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as ProfileStampsNotifierProvider).userId;
  @override
  bool get publicOnly => (origin as ProfileStampsNotifierProvider).publicOnly;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
