import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_TOKEN']!);

  await Hive.initFlutter();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // GoogleService-Info.plist (iOS) is read automatically
  await Firebase.initializeApp();

  // Initialize notifications (non-blocking)
  NotificationService().initialize().catchError((_) {});

  runApp(const ProviderScope(child: ZonApp()));
}
