import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Emits a route string whenever a notification is tapped.
// App listens to this and calls GoRouter.go(route).
final notificationRouteStream = StreamController<String>.broadcast();

class NotificationService {
  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await requestPermission();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // App opened from a tapped FCM notification (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_routeFromMessage);

    // App launched by tapping a notification while terminated
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _routeFromMessage(initial);

    // Register for token refreshes first so we still capture the token once
    // APNs delivers it later (e.g. after the Push capability is configured).
    _fcm.onTokenRefresh.listen(_registerToken);

    // On iOS, getToken() throws if the APNs token isn't available yet (no Push
    // entitlement, simulator, or APNs not configured in Firebase). Guard it so
    // initialization still completes and local notifications keep working.
    try {
      if (Platform.isIOS && await _fcm.getAPNSToken() == null) {
        debugPrint('APNs token not available yet — skipping FCM token fetch. '
            'It will register via onTokenRefresh once APNs is configured.');
        return;
      }
      final token = await _fcm.getToken();
      if (token != null) await _registerToken(token);
    } catch (e) {
      debugPrint('FCM token fetch skipped: $e');
    }
  }

  Future<void> requestPermission() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _registerToken(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[NotificationService] FCM token registration failed: $e');
    }
  }

  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'zon_channel',
        'ZON Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] as String?;
    if (!await _isTypeEnabled(type)) return;
    final title = message.notification?.title ?? 'ZON';
    final body = message.notification?.body ?? '';
    sendLocalNotification(
      title: title,
      body: body,
      payload: _routeForData(data),
    );
  }

  /// Checks user_privacy to decide whether to surface a foreground notification.
  /// Defaults to true on any error so notifications are never silently blocked.
  Future<bool> _isTypeEnabled(String? type) async {
    if (type == null) return true;
    if (type != 'like' && type != 'comment' && type != 'mention' &&
        type != 'friend_request' && type != 'friend_accepted') {
      return true;
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return true;
      final row = await Supabase.instance.client
          .from('user_privacy')
          .select('notify_likes, notify_comments, notify_friend_requests')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return true;
      return switch (type) {
        'like' => row['notify_likes'] as bool? ?? true,
        'comment' || 'mention' => row['notify_comments'] as bool? ?? true,
        'friend_request' || 'friend_accepted' =>
          row['notify_friend_requests'] as bool? ?? true,
        _ => true,
      };
    } catch (e) {
      debugPrint('[NotificationService] preference check failed: $e');
      return true;
    }
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final route = response.payload;
    if (route != null && route.isNotEmpty) {
      notificationRouteStream.add(route);
    }
  }

  void _routeFromMessage(RemoteMessage message) {
    final route = _routeForData(message.data);
    notificationRouteStream.add(route);
  }

  String _routeForData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final stampId = data['stamp_id'] as String?;
    final checkInId = data['check_in_id'] as String?;
    final userId = data['actor_id'] as String?;
    return switch (type) {
      'significant_change_nudge' => () {
          final lat = data['lat'] as String?;
          final lng = data['lng'] as String?;
          if (lat != null && lng != null) {
            return '/checkin?lat=$lat&lng=$lng';
          }
          return '/checkin';
        }(),
      'photo_add_suggestion' => '/photo-suggestions',
      'evening_summary' => '/timeline',
      'like' || 'comment' || 'mention' => stampId != null
          ? '/stamp/$stampId'
          : '/activity',
      'tag' => stampId != null
          ? '/stamp/$stampId'
          : checkInId != null
              ? '/check-in/$checkInId'
              : '/activity',
      'follow' || 'friend_request' => '/activity',
      'follow_accepted' || 'friend_accepted' => userId != null
          ? '/profile/$userId'
          : '/activity',
      _ => '/feed',
    };
  }

  Future<String?> get fcmToken => _fcm.getToken();
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // FCM background handler — system handles displaying the notification.
  // Routing happens in onMessageOpenedApp when user taps.
}
