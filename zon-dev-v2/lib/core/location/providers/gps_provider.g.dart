// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gpsServiceHash() => r'62c81e46cb52c7150aff63ca36f3db45237b58e8';

/// See also [gpsService].
@ProviderFor(gpsService)
final gpsServiceProvider = AutoDisposeProvider<GpsService>.internal(
  gpsService,
  name: r'gpsServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$gpsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GpsServiceRef = AutoDisposeProviderRef<GpsService>;
String _$gpsNotifierHash() => r'778703ba1228033cdb0f8af7601fb6ae2cfbc565';

/// App-wide foreground location tracker (keepAlive): one subscription records
/// the route while the app is open, and when the session ends drops a passive
/// "auto" check-in at the end of the tracked path (linking the trace across
/// launches), skipped when it lands too close to the last one.
///
/// Copied from [GpsNotifier].
@ProviderFor(GpsNotifier)
final gpsNotifierProvider =
    NotifierProvider<GpsNotifier, AsyncValue<Position?>>.internal(
  GpsNotifier.new,
  name: r'gpsNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$gpsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GpsNotifier = Notifier<AsyncValue<Position?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
