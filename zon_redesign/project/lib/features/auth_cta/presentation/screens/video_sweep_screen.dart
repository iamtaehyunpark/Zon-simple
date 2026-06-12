import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ai/liveness/liveness_detector.dart';
import '../../../../core/ai/pipeline.dart';

/// Step 2 — video sweep with live liveness gate.
///
/// User sweeps the camera across the scene for 5+ seconds.
/// Depth model runs on every [LivenessDetector.frameInterval]th frame.
/// Immediate abort if a flat surface is detected.
class VideoSweepScreen extends StatefulWidget {
  const VideoSweepScreen({super.key, required this.placeId});
  final String placeId;

  @override
  State<VideoSweepScreen> createState() => _VideoSweepScreenState();
}

class _VideoSweepScreenState extends State<VideoSweepScreen> {
  CameraController? _camera;
  final _liveness = LivenessDetector();

  bool _initialising = true;
  bool _recording = false;
  bool _livenessLoading = true;
  String? _error;
  String _hint = 'Loading…';

  int _frameCount = 0;
  int _elapsedSec = 0;
  Timer? _timer;

  final List<Uint8List> _capturedFrames = [];

  static const _minRecordSec = 5;
  static const _maxRecordSec = 15;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _camera?.dispose();
    _liveness.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() { _error = 'No camera found'; _initialising = false; });
      return;
    }
    final ctrl = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await ctrl.initialize();
    await _liveness.load();
    if (mounted) {
      setState(() {
        _camera = ctrl;
        _initialising = false;
        _livenessLoading = false;
        _hint = 'Tap the button to start sweeping';
      });
    }
  }

  Future<void> _startRecording() async {
    if (_camera == null || _recording) return;
    _liveness.reset();
    _capturedFrames.clear();
    _frameCount = 0;
    _elapsedSec = 0;
    setState(() { _recording = true; _hint = 'Sweep slowly across the scene…'; });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { _elapsedSec++; });
      if (_elapsedSec >= _maxRecordSec) _stopRecording();
    });

    await _camera!.startImageStream((CameraImage frame) async {
      _frameCount++;

      // Capture a JPEG snapshot roughly every second
      if (_frameCount % 30 == 0 && _capturedFrames.length < 5) {
        try {
          final xfile = await _camera!.takePicture();
          _capturedFrames.add(await xfile.readAsBytes());
        } catch (_) {}
      }

      if (_frameCount % LivenessDetector.frameInterval != 0) return;
      final earlyFail = await _liveness.checkFrame(frame);
      if (earlyFail != null && mounted) {
        _timer?.cancel();
        await _camera!.stopImageStream();
        if (mounted) {
          setState(() { _recording = false; });
          _showFailDialog((earlyFail as LivenessFail).userMessage);
        }
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    _timer?.cancel();
    try { await _camera?.stopImageStream(); } catch (_) {}
    if (mounted) setState(() { _recording = false; _hint = 'Processing…'; });

    final result = await _liveness.finalize(_frameCount);

    if (!mounted) return;
    if (result is LivenessFail) {
      _showFailDialog(result.userMessage);
    } else {
      context.pushNamed(
        'ai-processing',
        extra: AiProcessingArgs(
          placeId: widget.placeId,
          frames: List<Uint8List>.from(_capturedFrames),
          livenessPass: result as LivenessPass,
        ),
      );
    }
  }

  void _showFailDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Liveness check failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() { _hint = 'Tap the button to try again'; });
            },
            child: const Text('Try again'),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); context.pop(); },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _initialising
          ? const Center(child: CircularProgressIndicator())
          : Stack(fit: StackFit.expand, children: [
              if (_camera != null) CameraPreview(_camera!),
              _SweepOverlay(
                recording: _recording,
                elapsedSec: _elapsedSec,
                minSec: _minRecordSec,
                maxSec: _maxRecordSec,
                hint: _hint,
                error: _error,
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => context.pop(),
                ),
              ),
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Center(
                  child: _RecordButton(
                    recording: _recording,
                    enabled: !_initialising && !_livenessLoading && _error == null,
                    canStop: _elapsedSec >= _minRecordSec,
                    onStart: _startRecording,
                    onStop: _stopRecording,
                  ),
                ),
              ),
            ]),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SweepOverlay extends StatelessWidget {
  const _SweepOverlay({
    required this.recording, required this.elapsedSec,
    required this.minSec, required this.maxSec,
    required this.hint, this.error,
  });

  final bool recording;
  final int elapsedSec, minSec, maxSec;
  final String hint;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 56),
        if (recording)
          Text('${elapsedSec}s / ${maxSec}s',
              style: const TextStyle(
                  color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 4)])),
        const Spacer(),
        if (recording)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: elapsedSec / maxSec,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(
                    elapsedSec >= minSec
                        ? const Color(0xFF1D9E75)
                        : Colors.orange),
                minHeight: 4,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(error ?? hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: error != null ? Colors.redAccent : Colors.white70,
                  fontSize: 14,
                  shadows: const [Shadow(blurRadius: 6)])),
        ),
        const SizedBox(height: 110),
      ]);
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.recording, required this.enabled,
    required this.canStop, required this.onStart, required this.onStop,
  });

  final bool recording, enabled, canStop;
  final VoidCallback onStart, onStop;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled
            ? (recording ? (canStop ? onStop : null) : onStart)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: recording
                ? (canStop ? Colors.red : Colors.red.withValues(alpha: 0.4))
                : const Color(0xFF1D9E75),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Icon(
              recording ? Icons.stop : Icons.fiber_manual_record,
              color: Colors.white, size: 30),
        ),
      );
}

/// Passed via `extra` when navigating to ai-processing.
class AiProcessingArgs {
  const AiProcessingArgs({
    required this.placeId,
    required this.frames,
    required this.livenessPass,
  });

  final String placeId;
  final List<Uint8List> frames;
  final LivenessPass livenessPass;
}
