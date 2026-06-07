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

  // Load .env
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  // Set Mapbox token
  try {
    final mapboxToken = dotenv.env['MAPBOX_TOKEN'];
    if (mapboxToken != null && mapboxToken.isNotEmpty) {
      MapboxOptions.setAccessToken(mapboxToken);
    } else {
      debugPrint('Warning: MAPBOX_TOKEN is missing or empty.');
    }
  } catch (e) {
    debugPrint('Error setting Mapbox token: $e');
  }

  // Initialize Hive
  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint('Error initializing Hive: $e');
  }

  // Initialize Supabase
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseUrl != null && supabaseAnonKey != null) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        // OAuth is handled in-app via flutter_web_auth_2 + getSessionFromUrl
        // (see LoginScreen), so disable the built-in deep-link observer to
        // avoid a second, failing exchange of the same one-time auth code.
        authOptions:
            const FlutterAuthClientOptions(detectSessionInUri: false),
      );
    } else {
      debugPrint('Warning: SUPABASE_URL or SUPABASE_ANON_KEY is missing.');
    }
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }

  // Initialize Firebase with explicit options so it doesn't depend on the
  // GoogleService-Info.plist being bundled into the iOS target.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Warning: Firebase initialization failed. Error: $e');
  }

  // Initialize notifications (non-blocking)
  try {
    NotificationService().initialize().catchError((e) {
      debugPrint('Notification initialization error: $e');
    });
  } catch (e) {
    debugPrint('Error starting notification service: $e');
  }

  runApp(const ProviderScope(child: ZonApp()));
}

