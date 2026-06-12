import 'dart:async';
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
import 'features/checkin/presentation/check_in_detail_screen.dart';
import 'features/checkin/presentation/providers/checkin_provider.dart';
import 'features/timeline/presentation/timeline_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/settings_screen.dart';
import 'features/profile/presentation/check_in_list_screen.dart';
import 'features/profile/presentation/user_search_screen.dart';
import 'features/profile/presentation/user_list_screen.dart';
import 'features/profile/presentation/follow_requests_screen.dart';
import 'features/profile/presentation/friend_requests_screen.dart';
import 'features/profile/presentation/activity_screen.dart';
import 'features/feed/presentation/saved_stamps_screen.dart';
import 'features/photo_import/presentation/photo_suggestion_screen.dart';
import 'features/voice_import/presentation/voice_import_screen.dart';
import 'features/settings/presentation/location_visibility_screen.dart';
import 'features/map/presentation/place_detail_screen.dart';
import 'features/compliance/presentation/consent_gate_screen.dart';
import 'features/compliance/presentation/data_privacy_screen.dart';
import 'features/compliance/presentation/inferred_data_screen.dart';
import 'features/compliance/presentation/providers/consent_provider.dart';
import 'core/sharing/shared_voice_service.dart';
import 'core/sharing/shared_photos_handler.dart';
import 'core/places/place_service_provider.dart';
import 'features/photo_import/presentation/photo_checkin_inspection_screen.dart';

const kBrandPurple = Color(0xFF8B6EC4);

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final _routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier();

  // Re-evaluate redirects whenever Supabase auth state changes (login/logout)
  // or the data-consent gate resolves (opt-in users must pass it post-login).
  ref.listen(authStateStreamProvider, (_, __) => notifier.notify());
  ref.listen(consentGateProvider, (_, __) => notifier.notify());

  return GoRouter(
    initialLocation: '/map',
    refreshListenable: notifier,
    redirect: (ctx, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final loc = state.matchedLocation;

      // Unauthenticated: everything funnels to /login.
      if (!isLoggedIn) return loc == '/login' ? null : '/login';

      // Authenticated but in an opt-in jurisdiction without a recorded consent
      // decision → blocking consent gate. `valueOrNull` is null only while the
      // consent state is still loading; the listener above re-runs this redirect
      // once it resolves, so a brief pre-gate frame is the worst case.
      final gate = ref.read(consentGateProvider).valueOrNull;
      if (gate != null && gate.needsGate) {
        return loc == '/consent' ? null : '/consent';
      }
      // Decided (or opt-out): the gate is not a place they can sit.
      if (loc == '/consent') return '/map';

      // Authenticated: keep users off /login and the bare '/' that the OAuth
      // deep-link callback resolves to (we define no '/' route).
      if (loc == '/login' || loc == '/') return '/map';
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
        pageBuilder: (ctx, state) => CustomTransitionPage(
          key: state.pageKey,
          fullscreenDialog: true,
          // Non-opaque so the page beneath stays painted — CheckinEntry is a
          // collapsible bottom-sheet popup (scrim + sheet), not a full page.
          opaque: false,
          barrierColor: Colors.transparent,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Sheet slides up; the dim scrim (inside CheckinEntry) fades in.
            final slide = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(slide),
                child: child,
              ),
            );
          },
          child: CheckinEntry(
            lat: double.tryParse(state.uri.queryParameters['lat'] ?? ''),
            lng: double.tryParse(state.uri.queryParameters['lng'] ?? ''),
            mode: state.uri.queryParameters['mode'] == 'stamp'
                ? CheckinMode.stamp
                : CheckinMode.checkIn,
            fromCheckInId: state.uri.queryParameters['fromCheckIn'],
            visitedAt: state.uri.queryParameters['time'] != null
                ? DateTime.tryParse(state.uri.queryParameters['time']!)
                : null,
          ),
        ),
      ),
      GoRoute(
        path: '/check-in/:id',
        name: 'checkin-detail',
        builder: (ctx, state) =>
            CheckInDetailScreen(checkInId: state.pathParameters['id']!),
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
        path: '/voice-import',
        name: 'voice-import',
        pageBuilder: (ctx, state) => MaterialPage(
          fullscreenDialog: true,
          child: VoiceImportScreen(
              memos: (state.extra as List<SharedVoiceMemo>?) ?? const []),
        ),
      ),
      GoRoute(
        path: '/photo-inspection',
        name: 'photo-inspection',
        pageBuilder: (ctx, state) => MaterialPage(
          fullscreenDialog: true,
          child: PhotoCheckInInspectionScreen(
            groups: (state.extra as List<InspectionGroup>?) ?? const [],
          ),
        ),
      ),
      GoRoute(
        path: '/profile/:id',
        name: 'user-profile',
        builder: (ctx, state) =>
            ProfileScreen(userId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/consent',
        name: 'consent',
        builder: (_, __) => const ConsentGateScreen(),
      ),
      GoRoute(
        path: '/data-privacy',
        name: 'data-privacy',
        builder: (_, __) => const DataPrivacyScreen(),
      ),
      GoRoute(
        path: '/inferred-data',
        name: 'inferred-data',
        builder: (_, __) => const InferredDataScreen(),
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
        path: '/follow-requests',
        name: 'follow-requests',
        builder: (_, __) => const FollowRequestsScreen(),
      ),
      GoRoute(
        path: '/friend-requests',
        name: 'friend-requests',
        builder: (_, __) => const FriendRequestsScreen(),
      ),
      GoRoute(
        path: '/location-visibility',
        name: 'location-visibility',
        builder: (_, __) => const LocationVisibilityScreen(),
      ),
      GoRoute(
        path: '/place/:id',
        name: 'place-detail',
        builder: (ctx, state) =>
            PlaceDetailScreen(placeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile/:id/friends',
        name: 'friends',
        builder: (ctx, state) => UserListScreen(
            userId: state.pathParameters['id']!, followers: false, friends: true),
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
  StreamSubscription<String>? _notifSub;
  StreamSubscription<List<SharedVoiceMemo>>? _shareSub;
  StreamSubscription<List<InspectionGroup>>? _photoShareSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Route the app when a notification is tapped
    _notifSub = notificationRouteStream.stream.listen((route) {
      final router = ref.read(_routerProvider);
      router.go(route);
    });
    // Begin route tracking after first frame (if already signed in).
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTracking());
    _initShareIntake();
  }

  // Voice memos shared from the iOS Voice Memos app via the Share Extension.
  // Warm app → `sharedVoiceMemos` stream; cold launch → getPending poll.
  // Requires the Share Extension target — see ios/SHARE_EXTENSION_SETUP.md.
  void _initShareIntake() {
    _shareSub = SharedVoiceService.instance.stream.listen(
      _onSharedVoiceMemos,
      onError: (e) => debugPrint('share stream: $e'),
    );
    SharedVoiceService.instance.getPending().then(_onSharedVoiceMemos);

    // Photo sharing from iOS Photos.app via Share Extension.
    SharedPhotosHandler.init((lat, lng) => ref.read(placeServiceForProvider(lat, lng)));
    _photoShareSub = SharedPhotosHandler.stream.listen(_onSharedPhotos);
  }

  void _onSharedVoiceMemos(List<SharedVoiceMemo> memos) {
    if (memos.isEmpty) return;
    // Only route signed-in users; the redirect guard would bounce them.
    if (Supabase.instance.client.auth.currentUser == null) return;
    ref.read(_routerProvider).push('/voice-import', extra: memos);
  }

  void _onSharedPhotos(List<InspectionGroup> groups) {
    if (groups.isEmpty) return;
    if (Supabase.instance.client.auth.currentUser == null) return;
    ref.read(_routerProvider).push('/photo-inspection', extra: groups);
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _shareSub?.cancel();
    _photoShareSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _syncTracking();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        ref.read(gpsNotifierProvider.notifier).stopTracking();
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break; // transient (system alerts, notification banners) — keep tracking
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
      theme: AppTheme.theme,
      // Dismiss the keyboard whenever the user taps outside a text field.
      // Wrapping the router's child applies this app-wide. The translucent
      // behavior lets taps still reach buttons/links underneath; only taps
      // not claimed by a deeper widget trigger the unfocus.
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    );
  }
}


// ── ZON Main Shell — custom tab bar + FAB menu matching zon-primitives.jsx ────
class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  bool _fabOpen = false;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    _fabOpen ? _ctrl.forward() : _ctrl.reverse();
  }

  void _closeFab() {
    if (!_fabOpen) return;
    setState(() => _fabOpen = false);
    _ctrl.reverse();
  }

  Animation<double> _itemAnim(int i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(i * 0.15, (i * 0.15 + 0.65).clamp(0, 1),
            curve: Curves.easeOut),
      );

  String _activeTab(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).uri.toString();
    if (loc.startsWith('/map')) return 'map';
    if (loc.startsWith('/timeline')) return 'timeline';
    if (loc.startsWith('/profile')) return 'profile';
    return 'feed';
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeTab(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Z.surface0,
      body: Stack(
        children: [
          // Main screen content — leave room for tab bar (83 + system pad)
          Positioned.fill(
            bottom: 83 + bottomPad,
            child: widget.child,
          ),

          // FAB backdrop overlay
          if (_fabOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeFab,
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Color(0x2E1A1714)),
              ),
            ),

          // FAB expand menu — pill items above tab bar
          if (_fabOpen)
            Positioned(
              bottom: 83 + bottomPad + 12,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FabMenuItem(
                    anim: _itemAnim(2),
                    icon: Icons.location_on,
                    label: 'Check in',
                    onTap: () { _closeFab(); context.push('/checkin?mode=checkin'); },
                  ),
                  const SizedBox(height: 10),
                  _FabMenuItem(
                    anim: _itemAnim(1),
                    icon: Icons.photo_camera,
                    label: 'Photo check-in',
                    onTap: () { _closeFab(); context.push('/photo-suggestions'); },
                  ),
                  const SizedBox(height: 10),
                  _FabMenuItem(
                    anim: _itemAnim(0),
                    icon: Icons.workspace_premium,
                    label: 'Create stamp',
                    onTap: () { _closeFab(); context.push('/checkin?mode=stamp'); },
                  ),
                ],
              ),
            ),

          // Tab bar — fixed at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _ZonTabBar(
              active: active,
              fabOpen: _fabOpen,
              bottomPad: bottomPad,
              onTab: (id) {
                _closeFab();
                switch (id) {
                  case 'map':      context.go('/map');
                  case 'feed':     context.go('/feed');
                  case 'timeline': context.go('/timeline');
                  case 'profile':  context.go('/profile');
                }
              },
              onFab: _toggleFab,
            ),
          ),
        ],
      ),
    );
  }
}

/// FAB pill menu item — matches FabMenu in zon-primitives.jsx
class _FabMenuItem extends StatelessWidget {
  final Animation<double> anim;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FabMenuItem({
    required this.anim,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
            .animate(anim),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 80),
            padding: const EdgeInsets.fromLTRB(14, 10, 20, 10),
            decoration: BoxDecoration(
              color: Z.surface1,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x23000000),
                    blurRadius: 20,
                    offset: Offset(0, 6)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Z.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 19, color: Z.brand),
                ),
                const SizedBox(width: 12),
                Text(label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Z.text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom 5-tab bar matching TabBar in zon-primitives.jsx:
///   Map | Feed | [FAB +52px elevated] | Days | Me
class _ZonTabBar extends StatelessWidget {
  final String active;
  final bool fabOpen;
  final double bottomPad;
  final void Function(String) onTab;
  final VoidCallback onFab;
  const _ZonTabBar({
    required this.active,
    required this.fabOpen,
    required this.bottomPad,
    required this.onTab,
    required this.onFab,
  });

  static const _tabs = [
    _TabDef('map',      Icons.map,           Icons.map_outlined,           'Map'),
    _TabDef('feed',     Icons.article,       Icons.article_outlined,       'Feed'),
    _TabDef('_fab',     Icons.add,           Icons.add,                    ''),
    _TabDef('timeline', Icons.calendar_today,Icons.calendar_today_outlined,'Days'),
    _TabDef('profile',  Icons.person,        Icons.person_outline,         'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 83 + bottomPad,
      decoration: const BoxDecoration(
        color: Z.surface1,
        border: Border(top: BorderSide(color: Z.outline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _tabs.map((tab) {
          if (tab.id == '_fab') {
            return Expanded(
              child: GestureDetector(
                onTap: onFab,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: AnimatedRotation(
                          turns: fabOpen ? 0.125 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Z.brand,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x738B6EC4),
                                  blurRadius: 18,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 26),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final isActive = active == tab.id;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTab(tab.id),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? tab.iconFilled : tab.iconOutline,
                      size: 24,
                      color: isActive ? Z.brand : Z.textMuted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Z.brand : Z.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabDef {
  final String id;
  final IconData iconFilled;
  final IconData iconOutline;
  final String label;
  const _TabDef(this.id, this.iconFilled, this.iconOutline, this.label);
}
