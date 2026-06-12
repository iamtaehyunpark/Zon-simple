import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import 'providers/consent_provider.dart';
import 'widgets/consent_choice_tile.dart';

/// Blocking, full-screen consent gate shown once to users in opt-in
/// jurisdictions (KR / EU/EEA) before they can use the app. Both purposes are
/// unbundled and default OFF — the user must actively opt in. They can continue
/// with either or both off; declining is a valid, recorded decision.
class ConsentGateScreen extends ConsumerStatefulWidget {
  const ConsentGateScreen({super.key});

  @override
  ConsumerState<ConsentGateScreen> createState() => _ConsentGateScreenState();
}

class _ConsentGateScreenState extends ConsumerState<ConsentGateScreen> {
  bool _bmDataUse = false; // default OFF — opt-in
  bool _thirdParty = false; // default OFF — opt-in
  bool _saving = false;

  Future<void> _continue() async {
    setState(() => _saving = true);
    await ref.read(consentGateProvider.notifier).submit(
          bmDataUse: _bmDataUse,
          thirdPartyShare: _thirdParty,
        );
    // The router's redirect (watching consentGateProvider) moves us to /map once
    // needsGate flips to false; no manual navigation needed.
  }

  @override
  Widget build(BuildContext context) {
    // Block the OS/app back gesture — a decision is required.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Z.surface0,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  children: [
                    const Icon(Icons.shield_outlined, size: 40, color: Z.brand),
                    const SizedBox(height: 16),
                    const Text(
                      'Your data, your choice',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Z.text),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ZON keeps a private map of where you go. Separately from '
                      'running the app for you, you can choose whether your '
                      'visit data helps build anonymous place insights. These '
                      'are optional and off by default — the app works either way.',
                      style: TextStyle(
                          fontSize: 14, color: Z.textMuted, height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    ConsentChoiceTile(
                      icon: Icons.insights,
                      title: 'Improve place insights',
                      body: 'Include my anonymized visits in aggregated, '
                          'place-level statistics (never tied to my identity, '
                          'and only shown for places with enough visitors).',
                      value: _bmDataUse,
                      onChanged: (v) => setState(() => _bmDataUse = v),
                    ),
                    const SizedBox(height: 12),
                    ConsentChoiceTile(
                      icon: Icons.handshake_outlined,
                      title: 'Share with trusted partners',
                      body: 'Allow my anonymized, aggregated visit data to be '
                          'provided to third parties. This is a separate choice '
                          'from the one above.',
                      value: _thirdParty,
                      onChanged: (v) => setState(() => _thirdParty = v),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You can change either choice anytime in Settings → Data & '
                      'Privacy. See our Privacy Policy for full details.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Z.textFaint,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _continue,
                    style: FilledButton.styleFrom(
                      backgroundColor: Z.brand,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            (_bmDataUse || _thirdParty)
                                ? 'Save & continue'
                                : 'Continue without sharing',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
