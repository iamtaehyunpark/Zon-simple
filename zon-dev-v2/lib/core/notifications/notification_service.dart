import 'dart:async';
import 'dart:io';
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

    final token = await _fcm.getToken();
    if (token != null) await _registerToken(token);
    _fcm.onTokenRefresh.listen(_registerToken);
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
    } catch (_) {}
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

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ?? 'ZON';
    final body = message.notification?.body ?? '';
    // Encode route as payload so local notification can deep-link on tap
    sendLocalNotification(
      title: title,
      body: body,
      payload: _routeForData(data),
    );
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
