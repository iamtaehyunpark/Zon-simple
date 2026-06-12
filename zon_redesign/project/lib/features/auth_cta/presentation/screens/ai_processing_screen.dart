import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/ai/pipeline.dart';
import '../../../../core/ai/scene/scene_matcher.dart';
import '../../../../core/ai/sensor/sensor_fusion.dart';
import 'video_sweep_screen.dart';

/// Step 3 — runs Phase 2 (scene matching) + Phase 3 (sensor fusion) in parallel,
/// then computes the final score and navigates to stamp-complete or fail.
class AiProcessingScreen extends StatefulWidget {
  const AiProcessingScreen({super.key, this.args});
  final AiProcessingArgs? args;

  @override
  State<AiProcessingScreen> createState() => _AiProcessingScreenState();
}

class _AiProcessingScreenState extends State<AiProcessingScreen> {
  final _matcher = SceneMatcher();
  final _fusion  = SensorFusion();

  String _status = 'Initialising…';
  int _step = 0; // 0-4 for progress indicator

  @override
  void initState() {
    super.initState();
    // Defer until args are available via ModalRoute
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _matcher.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final args = widget.args
        ?? ModalRoute.of(context)?.settings.arguments as AiProcessingArgs?;
    if (args == null) {
      _fail('No processing data received.');
      return;
    }

    try {
      _setStatus('Loading scene models…', 1);
      await _matcher.load();

      // Fetch place reference data from Supabase
      _setStatus('Fetching place reference…', 2);
      final placeRef = await _fetchPlaceReference(args.placeId);

      // Phase 2 + Phase 3 in parallel
      _setStatus('Matching scene…', 3);
      final results = await Future.wait([
        _matcher.match(
          frames: args.frames,
          livenessPass: args.livenessPass,
          place: placeRef,
        ),
        _runSensorFusion(args),
      ]);

      final scene  = results[0] as SceneMatchResult;
      final sensor = results[1] as SensorFusionResult;

      // Teleport = hard fail
      if (!sensor.timestampConsistent) {
        _fail('Location verification failed. Physically impossible travel detected.');
        return;
      }

      // Anchor hard-filter
      if (!scene.anchorDetected) {
        _fail('Could not match this location\'s anchor point. Try again from a different angle.');
        return;
      }

      _setStatus('Computing final score…', 4);
      final finalScore = ScoreCalculator.compute(
        embeddingScore: scene.embeddingScore,
        keypointScore:  scene.keypointScore,
        depthScore:     scene.depthScore,
        sensorScore:    sensor.sensorScore,
      );

      final now = DateTime.now();
      final verification = VerificationResult(
        finalScore:      finalScore,
        passed:          finalScore > 0.75,
        needsChallenge:  finalScore > 0.5 && finalScore <= 0.75,
        liveness:        args.livenessPass,
        scene:           scene,
        sensor:          sensor,
        placeId:         args.placeId,
        verifiedAt:      now,
        certificateHash: '${finalScore.toStringAsFixed(4)}:${args.placeId}:${now.millisecondsSinceEpoch}'.hashCode.toRadixString(16),
      );

      if (!mounted) return;
      context.pushReplacementNamed('record-edit', extra: verification);
    } catch (e) {
      _fail('Processing error: $e');
    }
  }

  Future<PlaceReference> _fetchPlaceReference(String placeId) async {
    final row = await Supabase.instance.client
        .from('places')
        .select('global_embedding, anchor_descriptor, spatial_fingerprint')
        .eq('id', placeId)
        .maybeSingle();
    // Fields are null until first consensus registration — that's fine.
    return const PlaceReference(); // TODO: parse binary fields when populated
  }

  Future<SensorFusionResult> _runSensorFusion(AiProcessingArgs args) async {
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    // Grab latest IMU reading
    final imu = <String, double>{};
    try {
      final acc = await accelerometerEventStream().first
          .timeout(const Duration(seconds: 2));
      imu['ax'] = acc.x;
      imu['ay'] = acc.y;
      imu['az'] = acc.z;
    } catch (_) {}

    // Fetch place lat/lng
    final placeRow = await Supabase.instance.client
        .from('places')
        .select('lat, lng')
        .eq('id', args.placeId)
        .single();

    return _fusion.fuse(
      gpsLat:    pos?.latitude  ?? 0,
      gpsLng:    pos?.longitude ?? 0,
      placeLat:  (placeRow['lat'] as num).toDouble(),
      placeLng:  (placeRow['lng'] as num).toDouble(),
      wifiScan:  args.livenessPass.stationaryFlag ? [] : [],
      referenceWifi: null,
      imu:       imu,
      verificationTime: DateTime.now(),
      lastKnownTime: null,
      lastKnownLat: null,
      lastKnownLng: null,
    );
  }

  void _setStatus(String msg, int step) {
    if (mounted) setState(() { _status = msg; _step = step; });
  }

  void _fail(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Verification failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/feed');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _ZonSpinner(),
              const SizedBox(height: 40),
              Text('Verifying your presence',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(_status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 40),
              _StepIndicator(currentStep: _step),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZonSpinner extends StatefulWidget {
  const _ZonSpinner();

  @override
  State<_ZonSpinner> createState() => _ZonSpinnerState();
}

class _ZonSpinnerState extends State<_ZonSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _ctrl,
        child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: [
              const Color(0xFF1D9E75),
              const Color(0xFF1D9E75).withValues(alpha: 0),
            ]),
          ),
          child: Center(
            child: Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF0A0A0A)),
              child: const Center(
                child: Text('Z',
                    style: TextStyle(color: Color(0xFF1D9E75),
                        fontSize: 28, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
      );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  static const _labels = [
    'Load models',
    'Fetch reference',
    'Match scene',
    'Sensor fusion',
    'Score',
  ];

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(_labels.length, (i) {
          final done    = i < currentStep;
          final active  = i == currentStep;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: done
                    ? const Color(0xFF1D9E75)
                    : active
                        ? Colors.white
                        : Colors.white24,
              ),
              const SizedBox(width: 12),
              Text(_labels[i],
                  style: TextStyle(
                      color: done
                          ? const Color(0xFF1D9E75)
                          : active
                              ? Colors.white
                              : Colors.white24,
                      fontSize: 14,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.normal)),
            ]),
          );
        }),
      );
}
