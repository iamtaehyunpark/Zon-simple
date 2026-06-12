import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import 'providers/consent_provider.dart';
import 'widgets/consent_choice_tile.dart';

/// Settings → Data & Privacy. The persistent control surface: the user can see
/// and change both consent choices at any time (withdrawal is as easy as the
/// grant — a GDPR/PIPA requirement), see which posture applies to their region,
/// and open the transparency screen / privacy policy.
class DataPrivacyScreen extends ConsumerWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(consentGateProvider);

    return Scaffold(
      backgroundColor: Z.surface0,
      appBar: AppBar(
        backgroundColor: Z.surface1,
        title: const Text('Data & Privacy',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Z.text)),
        iconTheme: const IconThemeData(color: Z.text),
      ),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Z.brand)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Couldn\'t load your privacy settings.\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Z.textMuted)),
          ),
        ),
        data: (state) {
          final c = state.consent;
          final optIn = state.jurisdiction.requiresOptIn;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                optIn
                    ? 'Your region requires explicit opt-in. These are off unless '
                        'you turn them on, and you can withdraw anytime.'
                    : 'These help improve ZON. They\'re on by default in your '
                        'region — turn either off anytime.',
                style: const TextStyle(
                    fontSize: 13, color: Z.textMuted, height: 1.45),
              ),
              const SizedBox(height: 16),
              ConsentChoiceTile(
                icon: Icons.insights,
                title: 'Improve place insights',
                body: 'Include my anonymized visits in aggregated, place-level '
                    'statistics. Never tied to my identity.',
                value: c.bmDataUse,
                onChanged: (v) => ref
                    .read(consentGateProvider.notifier)
                    .submit(bmDataUse: v, thirdPartyShare: c.thirdPartyShare),
              ),
              const SizedBox(height: 12),
              ConsentChoiceTile(
                icon: Icons.handshake_outlined,
                title: 'Share with trusted partners',
                body: 'Allow my anonymized, aggregated visit data to be provided '
                    'to third parties. A separate choice from the one above.',
                value: c.thirdPartyShare,
                onChanged: (v) => ref
                    .read(consentGateProvider.notifier)
                    .submit(bmDataUse: c.bmDataUse, thirdPartyShare: v),
              ),
              const SizedBox(height: 24),
              _LinkRow(
                icon: Icons.fact_check_outlined,
                label: 'What we\'ve inferred about you',
                sub: 'See and verify the data derived from your activity',
                onTap: () => context.push('/inferred-data'),
              ),
              const Divider(height: 1, color: Z.outline),
              _LinkRow(
                icon: Icons.policy_outlined,
                label: 'Privacy Policy',
                sub: 'How we collect, use, and share data',
                // TODO: point at the published policy URL once available.
                onTap: () {},
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Region: ${c.jurisdiction ?? state.jurisdiction.code} · '
                  '${optIn ? 'opt-in' : 'opt-out'} posture',
                  style: const TextStyle(fontSize: 12, color: Z.textFaint),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: Z.brandSoft, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: Z.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Z.text)),
                    Text(sub,
                        style:
                            const TextStyle(fontSize: 12, color: Z.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Z.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
