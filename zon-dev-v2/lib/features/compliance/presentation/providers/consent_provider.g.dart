// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$consentGateHash() => r'3d82bdcefa8cc82318c4ab9d926970b0218a46f3';

/// Loads consent state and decides what to do about it:
///
///  • already resolved            → nothing to do (no gate)
///  • unresolved, opt-out region  → silently record the opt-out defaults so the
///                                  decision is real (counts in aggregates), no UI
///  • unresolved, opt-in region   → flag [needsGate]; record NOTHING until the
///                                  user explicitly chooses on the gate screen
///
/// Kept alive so the router can read the cached value synchronously in its
/// redirect. Invalidate after the user submits the gate to re-evaluate.
///
/// Copied from [ConsentGate].
@ProviderFor(ConsentGate)
final consentGateProvider =
    AsyncNotifierProvider<ConsentGate, ConsentGateState>.internal(
  ConsentGate.new,
  name: r'consentGateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$consentGateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConsentGate = AsyncNotifier<ConsentGateState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
