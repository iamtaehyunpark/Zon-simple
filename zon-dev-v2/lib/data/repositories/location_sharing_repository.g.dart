// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_sharing_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationSharingRepositoryHash() =>
    r'09d00994ea0396bdc36c70cc7637280cbda5425b';

/// See also [locationSharingRepository].
@ProviderFor(locationSharingRepository)
final locationSharingRepositoryProvider =
    AutoDisposeProvider<LocationSharingRepository>.internal(
  locationSharingRepository,
  name: r'locationSharingRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationSharingRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationSharingRepositoryRef
    = AutoDisposeProviderRef<LocationSharingRepository>;
String _$friendLocationsHash() => r'2207cf9da725f6f41fa0821d984bc75425d2ed2d';

/// Stream of mutual-friend live locations, filtered to ≤ 8 h stale.
///
/// Copied from [friendLocations].
@ProviderFor(friendLocations)
final friendLocationsProvider =
    AutoDisposeStreamProvider<List<FriendLocation>>.internal(
  friendLocations,
  name: r'friendLocationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$friendLocationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FriendLocationsRef = AutoDisposeStreamProviderRef<List<FriendLocation>>;
String _$ghostModeHash() => r'19b914a9e0042297f719535ba1c1ec2347224e4b';

/// Ghost Mode state for the current user.
///
/// Copied from [ghostMode].
@ProviderFor(ghostMode)
final ghostModeProvider = AutoDisposeFutureProvider<bool>.internal(
  ghostMode,
  name: r'ghostModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$ghostModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GhostModeRef = AutoDisposeFutureProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
