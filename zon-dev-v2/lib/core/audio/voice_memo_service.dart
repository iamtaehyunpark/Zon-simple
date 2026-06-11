import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Records short voice memos, uploads them to Supabase Storage, and transcribes
/// the speech to text fully on-device via the iOS Speech framework
/// (SFSpeechRecognizer) over a platform channel — see ios/Runner/AppDelegate.swift.
///
/// One mic consumer only: we capture an m4a file with `record`, then hand the
/// file to the OS speech recognizer. The recording is the playable artifact;
/// the transcript becomes the timeline note body. Nothing leaves the device.
class VoiceMemoService {
  static const _speech = MethodChannel('app.getzon.zon/speech');

  VoiceMemoService([AudioRecorder? recorder])
      : _recorder = recorder ?? AudioRecorder();

  static const _uuid = Uuid();
  final AudioRecorder _recorder;
  String? _path;

  /// True if the mic permission is granted and a recording can start.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Begin recording to a temp file. Returns false if permission is denied.
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${_uuid.v4()}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100),
      path: path,
    );
    _path = path;
    return true;
  }

  /// True while a recording is in progress.
  Future<bool> get isRecording => _recorder.isRecording();

  /// Live input amplitude stream (for a waveform / pulsing UI).
  Stream<Amplitude> amplitudeStream() =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 160));

  /// Stop recording and return the local file path (or null if nothing/empty).
  Future<File?> stop() async {
    final path = await _recorder.stop();
    _path = null;
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists() || await file.length() < 256) return null;
    return file;
  }

  /// Abort the current recording and discard the file.
  Future<void> cancel() async {
    try {
      await _recorder.stop();
    } catch (_) {}
    final p = _path;
    _path = null;
    if (p != null) {
      try {
        await File(p).delete();
      } catch (_) {}
    }
  }

  void dispose() => _recorder.dispose();

  /// Upload [file] to the `voice-memos` bucket, namespaced under the user id.
  /// Returns the public URL, or null on failure.
  Future<String?> upload(File file) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;
      final filename = '$userId/${_uuid.v4()}.m4a';
      await Supabase.instance.client.storage
          .from('voice-memos')
          .upload(filename, file);
      return Supabase.instance.client.storage
          .from('voice-memos')
          .getPublicUrl(filename);
    } catch (_) {
      return null;
    }
  }

  /// Ask the OS for speech-recognition authorization. Returns true if granted.
  Future<bool> requestSpeechPermission() async {
    try {
      return await _speech.invokeMethod<bool>('requestAuthorization') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Transcribe [file] to text on-device via the iOS Speech framework, using the
  /// current device locale. Returns '' on failure (permission denied, locale
  /// unsupported, no speech) so the memo can still be saved audio-only.
  Future<String> transcribe(File file) async {
    try {
      if (!await requestSpeechPermission()) return '';
      final text = await _speech.invokeMethod<String>('transcribe', {
        'path': file.path,
        'localeId': ui.PlatformDispatcher.instance.locale.toLanguageTag(),
      });
      return text?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Server-side transcription via the `transcribe-voice` Edge Function
  /// (Gemini 3.1 flash lite, multimodal). Kept for later: swap [transcribe]'s
  /// body for `return transcribeViaGemini(file);` to route through the server
  /// instead of on-device. Gemini auto-detects the spoken language (no locale
  /// needed) at the cost of a network round-trip + per-memo API usage.
  Future<String> transcribeViaGemini(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final result = await Supabase.instance.client.functions.invoke(
        'transcribe-voice',
        body: {'audio': base64Encode(bytes), 'mimeType': 'audio/m4a'},
      );
      return (result.data as Map<String, dynamic>?)?['transcript'] as String? ??
          '';
    } catch (_) {
      return '';
    }
  }
}
