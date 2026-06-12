import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ai/pipeline.dart';
import '../../../../core/services/stamp_service.dart';
import '../../../../data/models/auth_tier.dart';

/// Passed via go_router `extra` to the stamp-complete route.
class StampDraftArgs {
  const StampDraftArgs({
    required this.verification,
    this.caption,
    this.sensoryTags = const [],
  });
  final VerificationResult verification;
  final String? caption;
  final List<String> sensoryTags;
}

/// Final step — shows the verification result and creates the Stamp in Supabase.
class StampCompleteScreen extends StatefulWidget {
  const StampCompleteScreen({super.key, this.args});
  final StampDraftArgs? args;

  @override
  State<StampCompleteScreen> createState() => _StampCompleteScreenState();
}

class _StampCompleteScreenState extends State<StampCompleteScreen> {
  bool _saving = false;
  bool _saved  = false;
  String? _error;
  VerificationResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _save());
  }

  Future<void> _save() async {
    final args = widget.args;
    if (args == null) return;
    setState(() { _result = args.verification; _saving = true; });

    try {
      final tier = args.verification.finalScore > 0.75
          ? AuthTier.tier1
          : AuthTier.tier2;

      await StampService.createStamp(
        placeId:         args.verification.placeId,
        tier:            tier,
        visionScore:     args.verification.scene.embeddingScore,
        sensorScore:     args.verification.sensor.sensorScore,
        finalScore:      args.verification.finalScore,
        certificateHash: args.verification.certificateHash,
        caption:         args.caption,
        sensoryTags:     args.sensoryTags,
      );

      if (mounted) setState(() { _saving = false; _saved = true; });
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result == null || _saving) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75))),
      );
    }

    final passed = result.passed;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Result icon
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: passed
                      ? const Color(0xFF1D9E75).withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                ),
                child: Icon(
                  passed ? Icons.verified : Icons.pending,
                  color: passed ? const Color(0xFF1D9E75) : Colors.orange,
                  size: 52,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                passed ? 'Stamp Earned!' : 'Verification Pending',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                passed
                    ? 'Tier 1 — AI-verified presence'
                    : 'Score below threshold. Retry for Tier 1.',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),

              const SizedBox(height: 40),
              _ScoreBreakdown(result: result),
              const Spacer(),

              if (_error != null) ...[
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                const SizedBox(height: 12),
              ],

              // Actions
              if (passed && _saved) ...[
                ElevatedButton.icon(
                  onPressed: () => context.go('/feed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.home),
                  label: const Text('View Feed',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
              ],
              TextButton(
                onPressed: () => context.go('/feed'),
                child: const Text('Back to feed',
                    style: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.result});
  final VerificationResult result;

  @override
  Widget build(BuildContext context) => Column(children: [
        _ScoreRow('Scene embedding',
            result.scene.embeddingScore, weight: '25%'),
        _ScoreRow('Keypoint match',
            result.scene.keypointScore,  weight: '35%'),
        _ScoreRow('Depth signature',
            result.scene.depthScore,     weight: '25%'),
        _ScoreRow('Sensor fusion',
            result.sensor.sensorScore,   weight: '15%'),
        const Divider(color: Colors.white12, height: 24),
        _ScoreRow('Final score', result.finalScore,
            weight: '', highlight: true),
      ]);
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.score,
      {required this.weight, this.highlight = false});
  final String label, weight;
  final double score;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = score > 0.7
        ? const Color(0xFF1D9E75)
        : score > 0.5
            ? Colors.orange
            : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(
          child: Text('$label${weight.isNotEmpty ? ' ($weight)' : ''}',
              style: TextStyle(
                  color: highlight ? Colors.white : Colors.white60,
                  fontSize: highlight ? 15 : 13,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.normal)),
        ),
        Text(
          score.toStringAsFixed(2),
          style: TextStyle(
              color: color,
              fontSize: highlight ? 16 : 13,
              fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}
