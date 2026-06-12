import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent bottom tab bar wrapping the 4 main tabs.
/// The center FAB triggers the Auth CTA flow.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    ('/feed', Icons.home_outlined, Icons.home, 'Feed'),
    ('/map', Icons.map_outlined, Icons.map, 'Map'),
    ('/timeline', Icons.calendar_today_outlined, Icons.calendar_today, 'Timeline'),
    ('/profile', Icons.person_outline, Icons.person, 'Profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    const paths = ['/feed', '/map', '/timeline', '/profile'];
    final idx = paths.indexWhere((p) => location.startsWith(p));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('auth-cta'),
        backgroundColor: const Color(0xFF1D9E75),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < _tabs.length; i++) ...[
              if (i == 2) const SizedBox(width: 56), // FAB gap
              _TabItem(
                icon: currentIndex == i ? _tabs[i].$3 : _tabs[i].$2,
                label: _tabs[i].$4,
                selected: currentIndex == i,
                onTap: () => context.goNamed(
                  ['feed', 'map', 'timeline', 'profile'][i],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
