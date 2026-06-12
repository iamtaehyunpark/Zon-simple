import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ai/pipeline.dart';
import 'stamp_complete_screen.dart';

/// Step 4 — add caption and sensory tags before publishing the Stamp.
class RecordEditScreen extends StatefulWidget {
  const RecordEditScreen({super.key, this.verification});
  final VerificationResult? verification;

  @override
  State<RecordEditScreen> createState() => _RecordEditScreenState();
}

class _RecordEditScreenState extends State<RecordEditScreen> {
  final _captionCtrl = TextEditingController();
  final Set<String> _selectedTags = {};

  static const _tagOptions = [
    'Cozy', 'Lively', 'Quiet', 'Scenic', 'Crowded',
    'Historic', 'Modern', 'Artsy', 'Peaceful', 'Bustling',
  ];

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  void _publish() {
    final verification = widget.verification;
    if (verification == null) {
      context.go('/feed');
      return;
    }
    context.pushReplacementNamed(
      'stamp-complete',
      extra: StampDraftArgs(
        verification: verification,
        caption: _captionCtrl.text.trim().isEmpty
            ? null
            : _captionCtrl.text.trim(),
        sensoryTags: _selectedTags.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.go('/feed'),
        ),
        title: const Text('Add details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _publish,
            child: const Text('Publish',
                style: TextStyle(
                    color: Color(0xFF1D9E75),
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // Verification badge
          if (widget.verification != null) ...[
            _VerificationSummary(verification: widget.verification!),
            const SizedBox(height: 24),
          ],

          // Caption
          const _SectionLabel('Caption'),
          const SizedBox(height: 8),
          TextField(
            controller: _captionCtrl,
            maxLines: 3,
            maxLength: 200,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Describe the vibe…',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF141414),
              counterStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1D9E75)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 24),

          // Sensory tags
          const _SectionLabel('Sensory tags'),
          const SizedBox(height: 4),
          const Text('What does this place feel like?',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tagOptions.map((tag) {
              final selected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1D9E75).withValues(alpha: 0.2)
                        : const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFF333333),
                    ),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF1D9E75)
                          : Colors.white54,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: _publish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Publish stamp',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/feed'),
            child: const Text('Skip and discard',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8));
}

class _VerificationSummary extends StatelessWidget {
  const _VerificationSummary({required this.verification});
  final VerificationResult verification;

  @override
  Widget build(BuildContext context) {
    final passed = verification.passed;
    final score  = verification.finalScore;
    final color  = passed ? const Color(0xFF1D9E75) : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(passed ? Icons.verified : Icons.pending, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              passed ? 'Tier 1 verified' : 'Pending verification',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            Text(
              'Score: ${score.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ]),
        ),
      ]),
    );
  }
}
