// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedStoriesHash() => r'eca3af787dff250a49592a275b380795a9980589';

/// Recent public check-ins grouped per author for the feed "stories" rail.
///
/// Copied from [feedStories].
@ProviderFor(feedStories)
final feedStoriesProvider =
    AutoDisposeFutureProvider<List<CheckInStory>>.internal(
  feedStories,
  name: r'feedStoriesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$feedStoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedStoriesRef = AutoDisposeFutureProviderRef<List<CheckInStory>>;
String _$feedNotifierHash() => r'9996bf320b49356dd0b65f97817d57ec55e1bbf1';

/// See also [FeedNotifier].
@ProviderFor(FeedNotifier)
final feedNotifierProvider =
    AutoDisposeNotifierProvider<FeedNotifier, AsyncValue<List<Stamp>>>.internal(
  FeedNotifier.new,
  name: r'feedNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$feedNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FeedNotifier = AutoDisposeNotifier<AsyncValue<List<Stamp>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
