// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stamp_detail_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stampDetailHash() => r'7323e772f6ac7ec46798a2061d2016be82c95d27';

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

/// See also [stampDetail].
@ProviderFor(stampDetail)
const stampDetailProvider = StampDetailFamily();

/// See also [stampDetail].
class StampDetailFamily extends Family<AsyncValue<Stamp?>> {
  /// See also [stampDetail].
  const StampDetailFamily();

  /// See also [stampDetail].
  StampDetailProvider call(
    String stampId,
  ) {
    return StampDetailProvider(
      stampId,
    );
  }

  @override
  StampDetailProvider getProviderOverride(
    covariant StampDetailProvider provider,
  ) {
    return call(
      provider.stampId,
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
  String? get name => r'stampDetailProvider';
}

/// See also [stampDetail].
class StampDetailProvider extends AutoDisposeFutureProvider<Stamp?> {
  /// See also [stampDetail].
  StampDetailProvider(
    String stampId,
  ) : this._internal(
          (ref) => stampDetail(
            ref as StampDetailRef,
            stampId,
          ),
          from: stampDetailProvider,
          name: r'stampDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$stampDetailHash,
          dependencies: StampDetailFamily._dependencies,
          allTransitiveDependencies:
              StampDetailFamily._allTransitiveDependencies,
          stampId: stampId,
        );

  StampDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.stampId,
  }) : super.internal();

  final String stampId;

  @override
  Override overrideWith(
    FutureOr<Stamp?> Function(StampDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StampDetailProvider._internal(
        (ref) => create(ref as StampDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        stampId: stampId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Stamp?> createElement() {
    return _StampDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StampDetailProvider && other.stampId == stampId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, stampId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StampDetailRef on AutoDisposeFutureProviderRef<Stamp?> {
  /// The parameter `stampId` of this provider.
  String get stampId;
}

class _StampDetailProviderElement
    extends AutoDisposeFutureProviderElement<Stamp?> with StampDetailRef {
  _StampDetailProviderElement(super.provider);

  @override
  String get stampId => (origin as StampDetailProvider).stampId;
}

String _$stampCommentsHash() => r'38e6209344694f890c437a6dbea37dda90282d21';

/// See also [stampComments].
@ProviderFor(stampComments)
const stampCommentsProvider = StampCommentsFamily();

/// See also [stampComments].
class StampCommentsFamily extends Family<AsyncValue<List<StampComment>>> {
  /// See also [stampComments].
  const StampCommentsFamily();

  /// See also [stampComments].
  StampCommentsProvider call(
    String stampId,
  ) {
    return StampCommentsProvider(
      stampId,
    );
  }

  @override
  StampCommentsProvider getProviderOverride(
    covariant StampCommentsProvider provider,
  ) {
    return call(
      provider.stampId,
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
  String? get name => r'stampCommentsProvider';
}

/// See also [stampComments].
class StampCommentsProvider
    extends AutoDisposeFutureProvider<List<StampComment>> {
  /// See also [stampComments].
  StampCommentsProvider(
    String stampId,
  ) : this._internal(
          (ref) => stampComments(
            ref as StampCommentsRef,
            stampId,
          ),
          from: stampCommentsProvider,
          name: r'stampCommentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$stampCommentsHash,
          dependencies: StampCommentsFamily._dependencies,
          allTransitiveDependencies:
              StampCommentsFamily._allTransitiveDependencies,
          stampId: stampId,
        );

  StampCommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.stampId,
  }) : super.internal();

  final String stampId;

  @override
  Override overrideWith(
    FutureOr<List<StampComment>> Function(StampCommentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StampCommentsProvider._internal(
        (ref) => create(ref as StampCommentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        stampId: stampId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StampComment>> createElement() {
    return _StampCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StampCommentsProvider && other.stampId == stampId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, stampId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StampCommentsRef on AutoDisposeFutureProviderRef<List<StampComment>> {
  /// The parameter `stampId` of this provider.
  String get stampId;
}

class _StampCommentsProviderElement
    extends AutoDisposeFutureProviderElement<List<StampComment>>
    with StampCommentsRef {
  _StampCommentsProviderElement(super.provider);

  @override
  String get stampId => (origin as StampCommentsProvider).stampId;
}

String _$stampPhotosHash() => r'a8728d2e1a9cca4ec6ee1e0a3fd3ca2c20239f2b';

/// See also [stampPhotos].
@ProviderFor(stampPhotos)
const stampPhotosProvider = StampPhotosFamily();

/// See also [stampPhotos].
class StampPhotosFamily extends Family<AsyncValue<List<String>>> {
  /// See also [stampPhotos].
  const StampPhotosFamily();

  /// See also [stampPhotos].
  StampPhotosProvider call(
    String stampId,
  ) {
    return StampPhotosProvider(
      stampId,
    );
  }

  @override
  StampPhotosProvider getProviderOverride(
    covariant StampPhotosProvider provider,
  ) {
    return call(
      provider.stampId,
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
  String? get name => r'stampPhotosProvider';
}

/// See also [stampPhotos].
class StampPhotosProvider extends AutoDisposeFutureProvider<List<String>> {
  /// See also [stampPhotos].
  StampPhotosProvider(
    String stampId,
  ) : this._internal(
          (ref) => stampPhotos(
            ref as StampPhotosRef,
            stampId,
          ),
          from: stampPhotosProvider,
          name: r'stampPhotosProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$stampPhotosHash,
          dependencies: StampPhotosFamily._dependencies,
          allTransitiveDependencies:
              StampPhotosFamily._allTransitiveDependencies,
          stampId: stampId,
        );

  StampPhotosProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.stampId,
  }) : super.internal();

  final String stampId;

  @override
  Override overrideWith(
    FutureOr<List<String>> Function(StampPhotosRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StampPhotosProvider._internal(
        (ref) => create(ref as StampPhotosRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        stampId: stampId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<String>> createElement() {
    return _StampPhotosProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StampPhotosProvider && other.stampId == stampId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, stampId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StampPhotosRef on AutoDisposeFutureProviderRef<List<String>> {
  /// The parameter `stampId` of this provider.
  String get stampId;
}

class _StampPhotosProviderElement
    extends AutoDisposeFutureProviderElement<List<String>> with StampPhotosRef {
  _StampPhotosProviderElement(super.provider);

  @override
  String get stampId => (origin as StampPhotosProvider).stampId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
