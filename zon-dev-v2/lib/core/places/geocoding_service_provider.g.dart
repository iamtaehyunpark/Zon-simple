// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geocoding_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$geocodingServiceForHash() =>
    r'35338470a9b2b0d722346a7d970a70e6f5d0faea';

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

/// Returns the correct GeocodingService for a coordinate.
/// Korea → Naver Maps Platform (NCP). Everywhere else → Mapbox.
///
/// Copied from [geocodingServiceFor].
@ProviderFor(geocodingServiceFor)
const geocodingServiceForProvider = GeocodingServiceForFamily();

/// Returns the correct GeocodingService for a coordinate.
/// Korea → Naver Maps Platform (NCP). Everywhere else → Mapbox.
///
/// Copied from [geocodingServiceFor].
class GeocodingServiceForFamily extends Family<GeocodingService> {
  /// Returns the correct GeocodingService for a coordinate.
  /// Korea → Naver Maps Platform (NCP). Everywhere else → Mapbox.
  ///
  /// Copied from [geocodingServiceFor].
  const GeocodingServiceForFamily();

  /// Returns the correct GeocodingService for a coordinate.
  /// Korea → Naver Maps Platform (NCP). Everywhere else → Mapbox.
  ///
  /// Copied from [geocodingServiceFor].
  GeocodingServiceForProvider call(
    double lat,
    double lng,
  ) {
    return GeocodingServiceForProvider(
      lat,
      lng,
    );
  }

  @override
  GeocodingServiceForProvider getProviderOverride(
    covariant GeocodingServiceForProvider provider,
  ) {
    return call(
      provider.lat,
      provider.lng,
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
  String? get name => r'geocodingServiceForProvider';
}

/// Returns the correct GeocodingService for a coordinate.
/// Korea → Naver Maps Platform (NCP). Everywhere else → Mapbox.
///
/// Copied from [geocodingServiceFor].
class GeocodingServiceForProvider
    extends AutoDisposeProvider<GeocodingService> {
  /// Returns the correct GeocodingService for a coordinate.
  /// Korea → Naver Maps Platform (NCP). Everywhere else → Mapbox.
  ///
  /// Copied from [geocodingServiceFor].
  GeocodingServiceForProvider(
    double lat,
    double lng,
  ) : this._internal(
          (ref) => geocodingServiceFor(
            ref as GeocodingServiceForRef,
            lat,
            lng,
          ),
          from: geocodingServiceForProvider,
          name: r'geocodingServiceForProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$geocodingServiceForHash,
          dependencies: GeocodingServiceForFamily._dependencies,
          allTransitiveDependencies:
              GeocodingServiceForFamily._allTransitiveDependencies,
          lat: lat,
          lng: lng,
        );

  GeocodingServiceForProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.lat,
    required this.lng,
  }) : super.internal();

  final double lat;
  final double lng;

  @override
  Override overrideWith(
    GeocodingService Function(GeocodingServiceForRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GeocodingServiceForProvider._internal(
        (ref) => create(ref as GeocodingServiceForRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        lat: lat,
        lng: lng,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<GeocodingService> createElement() {
    return _GeocodingServiceForProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GeocodingServiceForProvider &&
        other.lat == lat &&
        other.lng == lng;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lat.hashCode);
    hash = _SystemHash.combine(hash, lng.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GeocodingServiceForRef on AutoDisposeProviderRef<GeocodingService> {
  /// The parameter `lat` of this provider.
  double get lat;

  /// The parameter `lng` of this provider.
  double get lng;
}

class _GeocodingServiceForProviderElement
    extends AutoDisposeProviderElement<GeocodingService>
    with GeocodingServiceForRef {
  _GeocodingServiceForProviderElement(super.provider);

  @override
  double get lat => (origin as GeocodingServiceForProvider).lat;
  @override
  double get lng => (origin as GeocodingServiceForProvider).lng;
}

String _$reverseGeocodeHash() => r'f08e83b0a0d05a16cd5545191a72e1c85172fc0a';

/// Convenience provider: reverse geocode a coordinate to a place name.
///
/// Copied from [reverseGeocode].
@ProviderFor(reverseGeocode)
const reverseGeocodeProvider = ReverseGeocodeFamily();

/// Convenience provider: reverse geocode a coordinate to a place name.
///
/// Copied from [reverseGeocode].
class ReverseGeocodeFamily extends Family<AsyncValue<String?>> {
  /// Convenience provider: reverse geocode a coordinate to a place name.
  ///
  /// Copied from [reverseGeocode].
  const ReverseGeocodeFamily();

  /// Convenience provider: reverse geocode a coordinate to a place name.
  ///
  /// Copied from [reverseGeocode].
  ReverseGeocodeProvider call(
    double lat,
    double lng,
  ) {
    return ReverseGeocodeProvider(
      lat,
      lng,
    );
  }

  @override
  ReverseGeocodeProvider getProviderOverride(
    covariant ReverseGeocodeProvider provider,
  ) {
    return call(
      provider.lat,
      provider.lng,
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
  String? get name => r'reverseGeocodeProvider';
}

/// Convenience provider: reverse geocode a coordinate to a place name.
///
/// Copied from [reverseGeocode].
class ReverseGeocodeProvider extends AutoDisposeFutureProvider<String?> {
  /// Convenience provider: reverse geocode a coordinate to a place name.
  ///
  /// Copied from [reverseGeocode].
  ReverseGeocodeProvider(
    double lat,
    double lng,
  ) : this._internal(
          (ref) => reverseGeocode(
            ref as ReverseGeocodeRef,
            lat,
            lng,
          ),
          from: reverseGeocodeProvider,
          name: r'reverseGeocodeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$reverseGeocodeHash,
          dependencies: ReverseGeocodeFamily._dependencies,
          allTransitiveDependencies:
              ReverseGeocodeFamily._allTransitiveDependencies,
          lat: lat,
          lng: lng,
        );

  ReverseGeocodeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.lat,
    required this.lng,
  }) : super.internal();

  final double lat;
  final double lng;

  @override
  Override overrideWith(
    FutureOr<String?> Function(ReverseGeocodeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReverseGeocodeProvider._internal(
        (ref) => create(ref as ReverseGeocodeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        lat: lat,
        lng: lng,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _ReverseGeocodeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReverseGeocodeProvider &&
        other.lat == lat &&
        other.lng == lng;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lat.hashCode);
    hash = _SystemHash.combine(hash, lng.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReverseGeocodeRef on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `lat` of this provider.
  double get lat;

  /// The parameter `lng` of this provider.
  double get lng;
}

class _ReverseGeocodeProviderElement
    extends AutoDisposeFutureProviderElement<String?> with ReverseGeocodeRef {
  _ReverseGeocodeProviderElement(super.provider);

  @override
  double get lat => (origin as ReverseGeocodeProvider).lat;
  @override
  double get lng => (origin as ReverseGeocodeProvider).lng;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
