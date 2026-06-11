import 'dart:async';
import 'package:flutter/services.dart';

/// One voice recording handed over from the iOS Share Extension. [path] points
/// into the App Group container (readable by the main app); [recordedAt] is the
/// recording's original creation date, preserved by the extension.
class SharedVoiceMemo {
  final String path;
  final DateTime recordedAt;
  const SharedVoiceMemo({required this.path, required this.recordedAt});

  static SharedVoiceMemo? fromMap(Map<dynamic, dynamic> m) {
    final path = m['path'] as String?;
    if (path == null || path.isEmpty) return null;
    final ts = m['recordedAt'] as String?;
    return SharedVoiceMemo(
      path: path,
      recordedAt: DateTime.tryParse(ts ?? '') ?? DateTime.now(),
    );
  }
}

/// Bridges the native `app.getzon.zon/sharing` channel (see AppDelegate.swift)
/// for shared voice memos. The Share Extension copies recordings into the App
/// Group container, stores their metadata, and either pushes `sharedVoiceMemos`
/// (warm app) or buffers them for the `getPendingVoiceMemos` poll (cold launch).
class SharedVoiceService {
  SharedVoiceService._() {
    _channel.setMethodCallHandler(_onCall);
  }
  static final SharedVoiceService instance = SharedVoiceService._();

  static const _channel = MethodChannel('app.getzon.zon/sharing');
  final _controller = StreamController<List<SharedVoiceMemo>>.broadcast();

  /// Voice memos shared while the app is running.
  Stream<List<SharedVoiceMemo>> get stream => _controller.stream;

  final _photoController =
      StreamController<List<Map<dynamic, dynamic>>>.broadcast();

  /// Raw photo metadata dicts shared from the iOS Photos app. Each map has
  /// keys: `path` (String), `lat` (num), `lng` (num), `timestamp` (String).
  Stream<List<Map<dynamic, dynamic>>> get photoStream => _photoController.stream;

  Future<void> _onCall(MethodCall call) async {
    if (call.method == 'sharedVoiceMemos') {
      final memos = _parse(call.arguments);
      if (memos.isNotEmpty) _controller.add(memos);
    } else if (call.method == 'sharedPhotos') {
      final photos = _parsePhotos(call.arguments);
      if (photos.isNotEmpty) _photoController.add(photos);
    }
  }

  /// Poll once on launch for voice memos shared while the app was closed.
  Future<List<SharedVoiceMemo>> getPending() async {
    try {
      final res = await _channel.invokeMethod('getPendingVoiceMemos');
      return _parse(res);
    } catch (_) {
      return const [];
    }
  }

  /// Poll once on launch for photos shared while the app was closed.
  Future<List<Map<dynamic, dynamic>>> getPendingPhotos() async {
    try {
      final res = await _channel.invokeMethod<List?>('getPending');
      return res?.cast<Map<dynamic, dynamic>>() ?? const [];
    } catch (_) {
      return const [];
    }
  }

  List<SharedVoiceMemo> _parse(dynamic args) {
    if (args is! List) return const [];
    return [
      for (final e in args)
        if (e is Map) SharedVoiceMemo.fromMap(e),
    ].whereType<SharedVoiceMemo>().toList();
  }

  List<Map<dynamic, dynamic>> _parsePhotos(dynamic args) {
    if (args is! List) return const [];
    return args.whereType<Map<dynamic, dynamic>>().toList();
  }
}
