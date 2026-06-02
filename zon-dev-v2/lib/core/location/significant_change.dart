import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Background cell tower detection — see CLAUDE.md §6.2
// iOS: CLLocationManager.startMonitoringSignificantLocationChanges
// Purpose: ONLY for triggering check-in nudge notifications.
// Not for continuous route tracking.
class SignificantChangeService {
  static Future<void> initialize() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
  }

  /// Called when a significant-change event fires (~500m cell tower displacement).
  /// Calls the suggest-stamp edge function which self-geocodes and sends FCM.
  static Future<void> onSignificantChange(Position position) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;

      await Supabase.instance.client.functions.invoke(
        'suggest-stamp',
        body: {
          'lat': position.latitude,
          'lng': position.longitude,
        },
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
    } catch (_) {
      // Non-fatal — user just doesn't get the nudge this time
    }
  }
}
