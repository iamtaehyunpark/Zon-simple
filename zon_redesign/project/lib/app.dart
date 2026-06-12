import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/ai/pipeline.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/feed/presentation/screens/feed_screen.dart';
import 'features/feed/presentation/screens/stamp_detail_screen.dart';
import 'features/map/presentation/screens/map_screen.dart';
import 'features/map/presentation/screens/place_detail_screen.dart';
import 'features/auth_cta/presentation/screens/place_select_screen.dart';
import 'features/auth_cta/presentation/screens/video_sweep_screen.dart';
import 'features/auth_cta/presentation/screens/ai_processing_screen.dart';
import 'features/auth_cta/presentation/screens/record_edit_screen.dart';
import 'features/auth_cta/presentation/screens/stamp_complete_screen.dart';
import 'features/place_register/presentation/screens/place_register_screen.dart';
import 'features/profile/presentation/screens/settings_screen.dart';
import 'features/timeline/presentation/screens/timeline_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/debug/presentation/screens/model_validation_screen.dart';
import 'features/debug/presentation/screens/pipeline_test_screen.dart';
import 'shared/widgets/main_shell.dart';

GoRouter _buildRouter() => GoRouter(
      initialLocation: '/feed',
      redirect: (context, state) {
        final isLoggedIn =
            Supabase.instance.client.auth.currentUser != null;
        final path = state.uri.path;

        if (isLoggedIn && path == '/login') return '/feed';

        // Only these flows require auth — browsing feed/map stays public
        const protectedPrefixes = ['/auth-cta', '/register-place'];
        final needsAuth =
            protectedPrefixes.any((p) => path.startsWith(p));

        if (needsAuth && !isLoggedIn) return '/login';
        return null;
      },
      refreshListenable: _AuthListenable(),
      routes: [
        GoRoute(
          path: '/',
          redirect: (_, __) => '/feed',
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/feed',
              name: 'feed',
              builder: (_, __) => const FeedScreen(),
            ),
            GoRoute(
              path: '/map',
              name: 'map',
              builder: (_, __) => const MapScreen(),
            ),
            GoRoute(
              path: '/timeline',
              name: 'timeline',
              builder: (_, __) => const TimelineScreen(),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
        // Auth CTA — full-screen modal flow
        GoRoute(
          path: '/auth-cta',
          name: 'auth-cta',
          pageBuilder: (context, state) => const MaterialPage(
            fullscreenDialog: true,
            child: PlaceSelectScreen(),
          ),
          routes: [
            GoRoute(
              path: 'sweep/:id',
              name: 'video-sweep',
              builder: (_, s) =>
                  VideoSweepScreen(placeId: s.pathParameters['id']!),
            ),
            GoRoute(
              path: 'processing',
              name: 'ai-processing',
              builder: (_, state) => AiProcessingScreen(
                args: state.extra as AiProcessingArgs?,
              ),
            ),
            GoRoute(
              path: 'edit',
              name: 'record-edit',
              builder: (_, state) => RecordEditScreen(
                verification: state.extra as VerificationResult?,
              ),
            ),
            GoRoute(
              path: 'complete',
              name: 'stamp-complete',
              builder: (_, state) => StampCompleteScreen(
                args: state.extra as StampDraftArgs?,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/place/:id',
          name: 'place-detail',
          builder: (context, state) =>
              PlaceDetailScreen(placeId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/stamp/:id',
          name: 'stamp-detail',
          builder: (context, state) =>
              StampDetailScreen(stampId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/register-place',
          name: 'register-place',
          pageBuilder: (context, state) => const MaterialPage(
            fullscreenDialog: true,
            child: PlaceRegisterScreen(),
          ),
        ),
        GoRoute(
          path: '/profile/:id',
          name: 'user-profile',
          builder: (context, state) =>
              ProfileScreen(userId: state.pathParameters['id']),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (_, __) => const SettingsScreen(),
        ),
        if (!kReleaseMode) ...[
          GoRoute(
            path: '/debug/models',
            name: 'debug-models',
            builder: (_, __) => const ModelValidationScreen(),
          ),
          GoRoute(
            path: '/debug/pipeline',
            name: 'debug-pipeline',
            builder: (_, __) => const PipelineTestScreen(),
          ),
        ],
      ],
    );

/// Notifies GoRouter to re-evaluate redirects when auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable() {
    _sub = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Root widget. Owns the GoRouter and MaterialApp theme.
class ZonApp extends StatefulWidget {
  const ZonApp({super.key});

  @override
  State<ZonApp> createState() => _ZonAppState();
}

class _ZonAppState extends State<ZonApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZON',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
