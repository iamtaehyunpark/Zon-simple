// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$placeServiceForHash() => r'f12fd6a031cd475adea3e95b6d23078e605b67ee';

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

/// Korea → Kakao (true coordinate-grounded nearby + text search).
/// Everywhere else → Google Places.
///
/// Copied from [placeServiceFor].
@ProviderFor(placeServiceFor)
const placeServiceForProvider = PlaceServiceForFamily();

/// Korea → Kakao (true coordinate-grounded nearby + text search).
/// Everywhere else → Google Places.
///
/// Copied from [placeServiceFor].
class PlaceServiceForFamily extends Family<PlaceService> {
  /// Korea → Kakao (true coordinate-grounded nearby + text search).
  /// Everywhere else → Google Places.
  ///
  /// Copied from [placeServiceFor].
  const PlaceServiceForFamily();

  /// Korea → Kakao (true coordinate-grounded nearby + text search).
  /// Everywhere else → Google Places.
  ///
  /// Copied from [placeServiceFor].
  PlaceServiceForProvider call(
    double lat,
    double lng,
  ) {
    return PlaceServiceForProvider(
      lat,
      lng,
    );
  }

  @override
  PlaceServiceForProvider getProviderOverride(
    covariant PlaceServiceForProvider provider,
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
  String? get name => r'placeServiceForProvider';
}

/// Korea → Kakao (true coordinate-grounded nearby + text search).
/// Everywhere else → Google Places.
///
/// Copied from [placeServiceFor].
class PlaceServiceForProvider extends AutoDisposeProvider<PlaceService> {
  /// Korea → Kakao (true coordinate-grounded nearby + text search).
  /// Everywhere else → Google Places.
  ///
  /// Copied from [placeServiceFor].
  PlaceServiceForProvider(
    double lat,
    double lng,
  ) : this._internal(
          (ref) => placeServiceFor(
            ref as PlaceServiceForRef,
            lat,
            lng,
          ),
          from: placeServiceForProvider,
          name: r'placeServiceForProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$placeServiceForHash,
          dependencies: PlaceServiceForFamily._dependencies,
          allTransitiveDependencies:
              PlaceServiceForFamily._allTransitiveDependencies,
          lat: lat,
          lng: lng,
        );

  PlaceServiceForProvider._internal(
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
    PlaceService Function(PlaceServiceForRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PlaceServiceForProvider._internal(
        (ref) => create(ref as PlaceServiceForRef),
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
  AutoDisposeProviderElement<PlaceService> createElement() {
    return _PlaceServiceForProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaceServiceForProvider &&
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
mixin PlaceServiceForRef on AutoDisposeProviderRef<PlaceService> {
  /// The parameter `lat` of this provider.
  double get lat;

  /// The parameter `lng` of this provider.
  double get lng;
}

class _PlaceServiceForProviderElement
    extends AutoDisposeProviderElement<PlaceService> with PlaceServiceForRef {
  _PlaceServiceForProviderElement(super.provider);

  @override
  double get lat => (origin as PlaceServiceForProvider).lat;
  @override
  double get lng => (origin as PlaceServiceForProvider).lng;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
