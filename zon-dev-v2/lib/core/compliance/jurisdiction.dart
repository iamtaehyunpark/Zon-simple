import 'dart:ui' as ui;

/// Where the user is, for the purpose of choosing the privacy/consent posture.
///
/// KR PIPA and EU/EEA GDPR require OPT-IN (explicit, unbundled consent) for
/// secondary big-data use and third-party provision. Everywhere else we use the
/// owner's chosen OPT-OUT default. The deciding signal is the device locale's
/// region — cheap, offline, and good enough to pick the safe posture.
///
/// Bias is deliberately toward protection: an unknown/missing region is treated
/// as opt-in. Mis-detection can only ever over-protect, never under-protect.
class Jurisdiction {
  /// ISO-3166-1 alpha-2 region code, or null if the device didn't report one.
  final String? countryCode;

  /// True when this region legally requires opt-in (KR + EU/EEA + UK/CH), or
  /// when the region is unknown (fail safe).
  final bool requiresOptIn;

  const Jurisdiction(this.countryCode, this.requiresOptIn);

  /// Stored on `data_consents.jurisdiction`. 'UNKNOWN' when the device gave us
  /// nothing — still flagged opt-in via [requiresOptIn].
  String get code => countryCode ?? 'UNKNOWN';

  /// EU-27 + EEA (IS/LI/NO) + UK (UK GDPR) + CH (FADP, opt-in-equivalent).
  static const _optInRegions = <String>{
    // EU-27
    'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR',
    'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK',
    'SI', 'ES', 'SE',
    // EEA non-EU
    'IS', 'LI', 'NO',
    // UK GDPR + Swiss FADP
    'GB', 'CH',
    // Korea (PIPA)
    'KR',
  };

  /// Detect from the device locale. Pure read of platform state — safe to call
  /// anytime. Region absent → opt-in (conservative).
  factory Jurisdiction.detect() {
    final region = ui.PlatformDispatcher.instance.locale.countryCode
        ?.toUpperCase();
    if (region == null || region.isEmpty) {
      return const Jurisdiction(null, true);
    }
    return Jurisdiction(region, _optInRegions.contains(region));
  }
}
