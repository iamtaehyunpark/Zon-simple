// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_suggestion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todayPhotoSuggestionsHash() =>
    r'b3c9c2fdb59ddd55e0fed391504a1be05478b854';

/// Today's geotagged photos — surfaced as check-in suggestions.
///
/// Copied from [todayPhotoSuggestions].
@ProviderFor(todayPhotoSuggestions)
final todayPhotoSuggestionsProvider =
    AutoDisposeFutureProvider<List<AssetEntity>>.internal(
  todayPhotoSuggestions,
  name: r'todayPhotoSuggestionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todayPhotoSuggestionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayPhotoSuggestionsRef
    = AutoDisposeFutureProviderRef<List<AssetEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
