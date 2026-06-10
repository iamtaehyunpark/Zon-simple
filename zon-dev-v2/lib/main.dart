import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  final mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';
  assert(mapboxToken.isNotEmpty, 'MAPBOX_TOKEN is missing in .env');
  MapboxOptions.setAccessToken(mapboxToken);

  await Hive.initFlutter();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    // OAuth is handled in-app via flutter_web_auth_2 + getSessionFromUrl
    // (see LoginScreen), so disable the built-in deep-link observer to
    // avoid a second, failing exchange of the same one-time auth code.
    authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notifications are optional — APNs may not be configured on first run.
  NotificationService().initialize().catchError((e) {
    debugPrint('NotificationService init: $e');
  });

  runApp(const ProviderScope(child: ZonApp()));
}
