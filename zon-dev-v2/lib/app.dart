import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/location/providers/gps_provider.dart';
import 'shared/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/feed/presentation/feed_screen.dart';
import 'features/feed/presentation/stamp_detail_screen.dart';
import 'features/feed/presentation/edit_stamp_screen.dart';
import 'features/map/presentation/map_screen.dart';
import 'features/checkin/presentation/checkin_entry.dart';
import 'features/checkin/presentation/providers/checkin_provider.dart';
import 'features/timeline/presentation/timeline_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/settings_screen.dart';
import 'features/profile/presentation/check_in_list_screen.dart';
import 'features/profile/presentation/user_search_screen.dart';
import 'features/profile/presentation/user_list_screen.dart';
import 'features/profile/presentation/activity_screen.dart';
import 'features/feed/presentation/saved_stamps_screen.dart';
import 'features/photo_import/presentation/photo_suggestion_screen.dart';

const kBrandGreen = Color(0xFF1D9E75);

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final _routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier();

  // Re-evaluate redirects whenever Supabase auth state changes (login/logout).
  ref.listen(authStateStreamProvider, (_, __) => notifier.notify());

  return GoRouter(
    initialLocation: '/feed',
    refreshListenable: notifier,
    redirect: (ctx, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final loc = state.matchedLocation;

      // Unauthenticated: everything funnels to /login.
      if (!isLoggedIn) return loc == '/login' ? null : '/login';

      // Authenticated: keep users off /login and the bare '/' that the OAuth
      // deep-link callback resolves to (we define no '/' route).
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
            mode: state.uri.queryParameters['mode'] == 'stamp'
                ? CheckinMode.stamp
                : CheckinMode.checkIn,
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
        path: '/stamp/:id/edit',
        name: 'stamp-edit',
        builder: (ctx, state) =>
            EditStampScreen(stampId: state.pathParameters['id']!),
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
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/check-ins',
        name: 'check-ins',
        builder: (_, __) => const CheckInListScreen(),
      ),
      GoRoute(
        path: '/saved',
        name: 'saved',
        builder: (_, __) => const SavedStampsScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (_, __) => const UserSearchScreen(),
      ),
      GoRoute(
        path: '/activity',
        name: 'activity',
        builder: (_, __) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/profile/:id/followers',
        name: 'followers',
        builder: (ctx, state) =>
            UserListScreen(userId: state.pathParameters['id']!, followers: true),
      ),
      GoRoute(
        path: '/profile/:id/following',
        name: 'following',
        builder: (ctx, state) => UserListScreen(
            userId: state.pathParameters['id']!, followers: false),
      ),
    ],
  );
});

class ZonApp extends ConsumerStatefulWidget {
  const ZonApp({super.key});

  @override
  ConsumerState<ZonApp> createState() => _ZonAppState();
}

class _ZonAppState extends ConsumerState<ZonApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Route the app when a notification is tapped
    notificationRouteStream.stream.listen((route) {
      final router = ref.read(_routerProvider);
      router.go(route);
    });
    // Begin route tracking after first frame (if already signed in).
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTracking());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _syncTracking();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        ref.read(gpsNotifierProvider.notifier).stopTracking();
      case AppLifecycleState.inactive:
        break; // transient (e.g. Control Center) — keep tracking
    }
  }

  /// Track the route whenever the app is foregrounded and a user is signed in.
  void _syncTracking() {
    if (ref.read(currentUserProvider) != null) {
      ref.read(gpsNotifierProvider.notifier).startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start/stop tracking on login/logout.
    ref.listen(currentUserProvider, (prev, next) {
      final gps = ref.read(gpsNotifierProvider.notifier);
      next != null ? gps.startTracking() : gps.stopTracking();
    });
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'ZON',
      routerConfig: router,
      theme: AppTheme.theme(kBrandGreen),
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

  // FAB offers the two distinct entry points: a lightweight check-in (trace
  // log) vs. a full stamp (a check-in promoted to a post).
  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on, color: kBrandGreen),
              title: const Text('Check in here'),
              subtitle: const Text('Log a visit — quick, private'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/checkin?mode=checkin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: kBrandGreen),
              title: const Text('Create stamp'),
              subtitle: const Text('A post with photos, caption & vibe'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/checkin?mode=stamp');
              },
            ),
          ],
        ),
      ),
    );
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
        onPressed: () => _showCreateMenu(context),
        backgroundColor: kBrandGreen,
        tooltip: 'Create',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
