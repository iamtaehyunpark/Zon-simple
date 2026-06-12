import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/user_profile.dart';
import '../../../feed/data/models/feed_item.dart';
import '../providers/profile_provider.dart';

/// Profile screen: stats, stamp grid, badge gallery.
/// userId == null → own profile; non-null → another user's.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwn = userId == null;
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;

    if (isOwn && !isLoggedIn) return const _SignedOutProfile();

    final profileAsync = ref.watch(profileNotifierProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1D9E75))),
        error: (e, _) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: Colors.white38))),
        data: (data) => data == null
            ? const Center(
                child: Text('Profile not found',
                    style: TextStyle(color: Colors.white38)))
            : RefreshIndicator(
                color: const Color(0xFF1D9E75),
                backgroundColor: const Color(0xFF141414),
                onRefresh: () =>
                    ref.read(profileNotifierProvider(userId).notifier).refresh(),
                child: _ProfileBody(
                  data: data,
                  isOwn: isOwn,
                ),
              ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.data, required this.isOwn});
  final ProfileData data;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final profile = data.profile;
    final stamps  = data.recentStamps;

    return CustomScrollView(
      slivers: [
        // ── App bar with avatar ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          backgroundColor: const Color(0xFF0A0A0A),
          pinned: true,
          leading: isOwn
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
          actions: [
            if (isOwn) ...[
              // Debug buttons (non-release only)
              if (!kReleaseMode) ...[
                IconButton(
                  icon: const Icon(Icons.memory, color: Colors.white38, size: 20),
                  onPressed: () => context.pushNamed('debug-models'),
                  tooltip: 'Validate AI Models',
                ),
                IconButton(
                  icon: const Icon(Icons.biotech, color: Colors.white38, size: 20),
                  onPressed: () => context.pushNamed('debug-pipeline'),
                  tooltip: 'Pipeline Test',
                ),
              ],
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white54),
                onPressed: () => context.pushNamed('settings'),
              ),
            ],
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D2E20), Color(0xFF0A0A0A)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Avatar(profile: profile),
                  const SizedBox(height: 10),
                  Text(
                    profile.displayName ?? profile.username,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20),
                  ),
                  Text('@${profile.username}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // ── Bio ──────────────────────────────────────────────────────────
        if (profile.bio != null && profile.bio!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(profile.bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
            ),
          ),

        // ── Stats ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              _StatBox(value: profile.placeCount,  label: 'Places'),
              const SizedBox(width: 10),
              _StatBox(value: profile.countryCount, label: 'Countries'),
              const SizedBox(width: 10),
              _StatBox(value: profile.badgeCount,   label: 'Badges'),
            ]),
          ),
        ),

        // ── Stamps grid ──────────────────────────────────────────────────
        if (stamps.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Stamps',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _StampGridCell(
                  item: stamps[i],
                  onTap: () => context.pushNamed('stamp-detail',
                      pathParameters: {'id': stamps[i].stampId}),
                ),
                childCount: stamps.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
            ),
          ),
        ] else
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyStamps(),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: CachedNetworkImageProvider(url),
      );
    }
    return CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFF1D9E75).withValues(alpha: 0.2),
      child: Text(
        profile.username.isNotEmpty
            ? profile.username[0].toUpperCase()
            : '?',
        style: const TextStyle(
            color: Color(0xFF1D9E75),
            fontWeight: FontWeight.w800,
            fontSize: 32),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(children: [
            Text('$value',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ),
      );
}

class _StampGridCell extends StatelessWidget {
  const _StampGridCell({required this.item, required this.onTap});
  final FeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
            image: item.photoUrls.isNotEmpty
                ? DecorationImage(
                    image:
                        CachedNetworkImageProvider(item.photoUrls.first),
                    fit: BoxFit.cover,
                    colorFilter: const ColorFilter.mode(
                        Colors.black38, BlendMode.darken),
                  )
                : null,
          ),
          child: Stack(children: [
            // No-photo placeholder
            if (item.photoUrls.isEmpty)
              Center(
                child: Icon(Icons.place,
                    color: const Color(0xFF1D9E75).withValues(alpha: 0.4),
                    size: 36),
              ),
            // Place name overlay
            Positioned(
              left: 10, right: 10, bottom: 10,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.placeName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        shadows: [Shadow(blurRadius: 4)]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                _TierPill(tier: item.tier),
              ]),
            ),
          ]),
        ),
      );
}

class _TierPill extends StatelessWidget {
  const _TierPill({required this.tier});
  final String tier;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (tier) {
      'tier1' => ('T1', const Color(0xFF1D9E75)),
      'tier2' => ('T2', Colors.blueAccent),
      _       => ('T3', Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

class _SignedOutProfile extends StatelessWidget {
  const _SignedOutProfile();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Column(children: [
            // Debug access even when signed out
            if (!kReleaseMode)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.memory,
                          color: Colors.white38, size: 20),
                      onPressed: () => context.pushNamed('debug-models'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.biotech,
                          color: Colors.white38, size: 20),
                      onPressed: () => context.pushNamed('debug-pipeline'),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            const Icon(Icons.person_outline, color: Colors.white24, size: 72),
            const SizedBox(height: 20),
            const Text('Your profile',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Sign in to collect Stamps and earn Badges.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () => context.pushNamed('login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Sign in',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const Spacer(),
          ]),
        ),
      );
}

class _EmptyStamps extends StatelessWidget {
  const _EmptyStamps();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.collections_bookmark_outlined,
              color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          const Text('No stamps yet',
              style:
                  TextStyle(color: Colors.white38, fontSize: 15)),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => context.pushNamed('auth-cta'),
            icon: const Icon(Icons.add_location_alt, size: 16,
                color: Color(0xFF1D9E75)),
            label: const Text('Verify your first place',
                style: TextStyle(color: Color(0xFF1D9E75))),
          ),
        ]),
      );
}
