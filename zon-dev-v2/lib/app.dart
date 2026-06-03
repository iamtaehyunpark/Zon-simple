import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_provider.dart';
import 'core/notifications/notification_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/feed/presentation/feed_screen.dart';
import 'features/feed/presentation/stamp_detail_screen.dart';
import 'features/map/presentation/map_screen.dart';
import 'features/checkin/presentation/checkin_entry.dart';
import 'features/timeline/presentation/timeline_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/photo_import/presentation/photo_suggestion_screen.dart';

const kBrandGreen = Color(0xFF1D9E75);

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final _routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier();

  // Listen to auth changes and notify GoRouter to trigger redirect evaluation
  ref.listen(devLoggedInProvider, (_, __) {
    debugPrint('GoRouter: devLoggedInProvider state changed, notifying listeners.');
    notifier.notify();
  });

  ref.listen(authStateStreamProvider, (_, __) {
    debugPrint('GoRouter: authStateStreamProvider state changed, notifying listeners.');
    notifier.notify();
  });

  return GoRouter(
    initialLocation: '/feed',
    refreshListenable: notifier,
    redirect: (ctx, state) {
      bool isLoggedIn = false;

      // 1. Check real Supabase Auth
      try {
        isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      } catch (e) {
        debugPrint('GoRouter Auth Redirect Error: $e');
      }

      // 2. Check Dev Bypass Auth
      if (!isLoggedIn) {
        try {
          isLoggedIn = ref.read(devLoggedInProvider);
        } catch (e) {
          debugPrint('GoRouter Dev Auth Check Error: $e');
        }
      }

      final loc = state.matchedLocation;
      debugPrint('GoRouter redirect: isLoggedIn=$isLoggedIn, loc=$loc');

      if (!isLoggedIn) {
        // Unauthenticated: everything funnels to /login.
        return loc == '/login' ? null : '/login';
      }

      // Authenticated: keep users out of /login, and off the bare '/' that the
      // OAuth deep-link callback (app.getzon://login-callback) resolves to —
      // we define no '/' route, so landing there would break navigation.
      if (loc == '/login' || loc == '/') return '/feed';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
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
      GoRoute(
        path: '/checkin',
        name: 'checkin',
        pageBuilder: (ctx, state) => MaterialPage(
          fullscreenDialog: true,
          child: CheckinEntry(
            lat: double.tryParse(state.uri.queryParameters['lat'] ?? ''),
            lng: double.tryParse(state.uri.queryParameters['lng'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: '/stamp/:id',
        name: 'stamp-detail',
        builder: (ctx, state) =>
            StampDetailScreen(stampId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/photo-suggestions',
        name: 'photo-suggestions',
        pageBuilder: (ctx, state) => const MaterialPage(
          fullscreenDialog: true,
          child: PhotoSuggestionScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/:id',
        name: 'user-profile',
        builder: (ctx, state) =>
            ProfileScreen(userId: state.pathParameters['id']),
      ),
    ],
  );
});

class ZonApp extends ConsumerStatefulWidget {
  const ZonApp({super.key});

  @override
  ConsumerState<ZonApp> createState() => _ZonAppState();
}

class _ZonAppState extends ConsumerState<ZonApp> {
  @override
  void initState() {
    super.initState();
    // Route the app when a notification is tapped
    notificationRouteStream.stream.listen((route) {
      final router = ref.read(_routerProvider);
      router.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'ZON',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kBrandGreen),
        useMaterial3: true,
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/timeline')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _locationIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: idx,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/feed');
            case 1:
              context.go('/map');
            case 3:
              context.go('/timeline');
            case 4:
              context.go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Timeline'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('checkin'),
        backgroundColor: kBrandGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
