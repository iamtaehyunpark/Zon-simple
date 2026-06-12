import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/compliance/jurisdiction.dart';
import '../../../../data/repositories/consent_repository.dart';

part 'consent_provider.g.dart';

/// Resolved state of the data-consent flow for the signed-in user.
class ConsentGateState {
  final DataConsent consent;
  final Jurisdiction jurisdiction;

  /// True only when the user is in an opt-in jurisdiction AND hasn't yet made a
  /// decision. The router routes these users to the blocking [ConsentGateScreen].
  final bool needsGate;

  const ConsentGateState({
    required this.consent,
    required this.jurisdiction,
    required this.needsGate,
  });
}

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
@Riverpod(keepAlive: true)
class ConsentGate extends _$ConsentGate {
  @override
  Future<ConsentGateState> build() async {
    final jurisdiction = Jurisdiction.detect();
    final repo = ref.watch(consentRepositoryProvider);

    final res = await repo.getMyConsent();
    final consent = res.getOrElse((_) => const DataConsent());

    if (consent.isResolved) {
      return ConsentGateState(
        consent: consent,
        jurisdiction: jurisdiction,
        needsGate: false,
      );
    }

    // Unresolved. Opt-in regions must decide for themselves (blocking gate).
    if (jurisdiction.requiresOptIn) {
      return ConsentGateState(
        consent: consent,
        jurisdiction: jurisdiction,
        needsGate: true,
      );
    }

    // Opt-out region: record the opt-out defaults so the decision is real, then
    // proceed without bothering the user. Disclosure lives in Settings.
    await repo.record(
      bmDataUse: true,
      thirdPartyShare: true,
      jurisdiction: jurisdiction.code,
      consentVersion: kAutoOptOutVersion,
    );
    return ConsentGateState(
      consent: consent.copyWith(
        bmDataUse: true,
        thirdPartyShare: true,
        consentVersion: kAutoOptOutVersion,
        jurisdiction: jurisdiction.code,
      ),
      jurisdiction: jurisdiction,
      needsGate: false,
    );
  }

  /// Persist an explicit decision (from the gate or the settings screen) and
  /// refresh, which clears [needsGate] and lets the router proceed.
  Future<void> submit({
    required bool bmDataUse,
    required bool thirdPartyShare,
  }) async {
    final jurisdiction = Jurisdiction.detect();
    await ref.read(consentRepositoryProvider).record(
          bmDataUse: bmDataUse,
          thirdPartyShare: thirdPartyShare,
          jurisdiction: jurisdiction.code,
        );
    ref.invalidateSelf();
    await future;
  }
}
