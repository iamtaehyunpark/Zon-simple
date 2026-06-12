import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../data/repositories/consent_repository.dart';

/// Transparency / right-of-access screen. Shows the user exactly what has been
/// derived about them in `user_attributes` (demographics, coarse home/work
/// anchors, behavioral segments). Inference jobs are a later workstream, so this
/// is usually empty today — that's shown honestly rather than hidden.
class InferredDataScreen extends ConsumerStatefulWidget {
  const InferredDataScreen({super.key});

  @override
  ConsumerState<InferredDataScreen> createState() => _InferredDataScreenState();
}

class _InferredDataScreenState extends ConsumerState<InferredDataScreen> {
  Future<Map<String, dynamic>?>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(consentRepositoryProvider)
        .getMyAttributes()
        .then((res) => res.getOrElse((_) => null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Z.surface0,
      appBar: AppBar(
        backgroundColor: Z.surface1,
        title: const Text('What we\'ve inferred',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Z.text)),
        iconTheme: const IconThemeData(color: Z.text),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: Z.brand));
          }
          final rows = _present(snap.data);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Text(
                'This is everything ZON has derived from your activity. It is '
                'coarse by design — we never store an exact home address, and '
                'demographics are buckets, not exact values.',
                style:
                    TextStyle(fontSize: 13, color: Z.textMuted, height: 1.45),
              ),
              const SizedBox(height: 20),
              if (rows.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Z.surface1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Z.outline),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Z.brand, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nothing has been inferred about you yet.',
                          style: TextStyle(fontSize: 14, color: Z.text),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Z.surface1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Z.outline),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < rows.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(rows[i].$1,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Z.textMuted)),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(rows[i].$2,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Z.text)),
                              ),
                            ],
                          ),
                        ),
                        if (i < rows.length - 1)
                          const Divider(height: 1, color: Z.outline),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Turning off "Improve place insights" in Data & Privacy stops '
                'your data feeding these inferences.',
                style: TextStyle(fontSize: 12, color: Z.textFaint, height: 1.4),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Map the raw attributes row into human-readable label/value pairs, skipping
  /// nulls, bookkeeping columns, and empty segment lists.
  List<(String, String)> _present(Map<String, dynamic>? row) {
    if (row == null) return const [];
    const labels = <String, String>{
      'age_band': 'Age range',
      'gender': 'Gender',
      'home_region': 'Home region',
      'home_geohash': 'Home area (≈1km)',
      'work_geohash': 'Work area (≈1km)',
      'locale': 'Locale',
      'primary_language': 'Primary language',
    };
    final out = <(String, String)>[];
    labels.forEach((key, label) {
      final v = row[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        out.add((label, v.toString()));
      }
    });
    final segments = (row['segments'] as List?)?.cast<String>() ?? const [];
    if (segments.isNotEmpty) {
      out.add(('Behavioral segments', segments.join(', ')));
    }
    return out;
  }
}
