import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_location.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'location_sharing_repository.g.dart';

@riverpod
LocationSharingRepository locationSharingRepository(
        LocationSharingRepositoryRef ref) =>
    LocationSharingRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

/// Stream of mutual-friend live locations, filtered to ≤ 8 h stale.
@riverpod
Stream<List<FriendLocation>> friendLocations(FriendLocationsRef ref) =>
    ref.watch(locationSharingRepositoryProvider).streamFriendLocations();

/// Ghost Mode state for the current user.
@riverpod
Future<bool> ghostMode(GhostModeRef ref) =>
    ref.watch(locationSharingRepositoryProvider).getGhostMode();

class LocationSharingRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;

  LocationSharingRepository(this.client, {this.currentUserId});

  // ── Broadcasting ──────────────────────────────────────────────────────────

  /// Upsert the caller's current position. Called from the map screen on each
  /// significant GPS update (throttled to ≥ 30 s or ≥ 50 m movement).
  Future<void> upsertMyLocation(
      double lat, double lng, double? accuracy, double? heading) async {
    final uid = userId;
    if (uid == null) return;
    try {
      await client.from('user_locations').upsert({
        'user_id': uid,
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'heading': heading,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[LocationSharing] upsertMyLocation failed: $e');
    }
  }

  // ── Reading ───────────────────────────────────────────────────────────────

  /// One-shot fetch of all friends' current locations (< 8 h stale).
  Future<List<FriendLocation>> getFriendLocations() async {
    final uid = userId;
    if (uid == null) return [];
    try {
      final rows = await client
          .from('user_locations')
          .select('user_id, lat, lng, updated_at, profiles!inner(username, avatar_url)')
          .neq('user_id', uid); // RLS enforces mutual-friend + ghost-mode gates
      final cutoff = DateTime.now().subtract(const Duration(hours: 8));
      return [
        for (final r in rows)
          if (DateTime.parse(r['updated_at'] as String).isAfter(cutoff))
            _fromRow(r),
      ];
    } catch (e) {
      debugPrint('[LocationSharing] getFriendLocations failed: $e');
      return [];
    }
  }

  /// Realtime stream: initial snapshot + pushed updates whenever any mutual
  /// friend upserts their position. Cleans up the channel on cancellation.
  Stream<List<FriendLocation>> streamFriendLocations() {
    final uid = userId;
    StreamController<List<FriendLocation>>? controller;
    RealtimeChannel? channel;

    controller = StreamController<List<FriendLocation>>(
      onCancel: () async {
        // Capture locals to avoid closure promotion issues.
        final ch = channel;
        final ctrl = controller;
        if (ch != null) await client.removeChannel(ch);
        if (ctrl != null && !ctrl.isClosed) await ctrl.close();
      },
    );

    // Emit initial snapshot
    getFriendLocations().then((list) {
      final ctrl = controller;
      if (ctrl != null && !ctrl.isClosed) ctrl.add(list);
    });

    if (uid != null) {
      channel = client
          .channel('friend-locations-$uid')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_locations',
            callback: (_) async {
              final ctrl = controller;
              if (ctrl == null || ctrl.isClosed) return;
              final updated = await getFriendLocations();
              if (!ctrl.isClosed) ctrl.add(updated);
            },
          )
        ..subscribe();
    }

    return controller.stream;
  }

  // ── Ghost Mode ────────────────────────────────────────────────────────────

  Future<bool> getGhostMode() async {
    final uid = userId;
    if (uid == null) return false;
    try {
      final row = await client
          .from('profiles')
          .select('is_ghost_mode')
          .eq('id', uid)
          .single();
      return row['is_ghost_mode'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setGhostMode(bool value) async {
    final uid = userId;
    if (uid == null) return;
    await client
        .from('profiles')
        .update({'is_ghost_mode': value})
        .eq('id', uid);
  }

  // ── Per-friend visibility (hide-from list) ────────────────────────────────

  /// Returns IDs of friends this user has hidden their location from.
  Future<Set<String>> getHiddenFromIds() async {
    final uid = userId;
    if (uid == null) return {};
    try {
      final rows = await client
          .from('location_hidden_from')
          .select('hidden_from_id')
          .eq('user_id', uid);
      return {for (final r in rows) r['hidden_from_id'] as String};
    } catch (_) {
      return {};
    }
  }

  Future<void> hideFromFriend(String friendId) async {
    final uid = userId;
    if (uid == null) return;
    await client.from('location_hidden_from').upsert({
      'user_id': uid,
      'hidden_from_id': friendId,
    });
  }

  Future<void> showToFriend(String friendId) async {
    final uid = userId;
    if (uid == null) return;
    await client
        .from('location_hidden_from')
        .delete()
        .eq('user_id', uid)
        .eq('hidden_from_id', friendId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  FriendLocation _fromRow(Map<String, dynamic> r) {
    final prof = r['profiles'] as Map<String, dynamic>? ?? {};
    return FriendLocation(
      userId: r['user_id'] as String,
      lat: (r['lat'] as num).toDouble(),
      lng: (r['lng'] as num).toDouble(),
      updatedAt: DateTime.parse(r['updated_at'] as String),
      username: prof['username'] as String? ?? 'friend',
      avatarUrl: prof['avatar_url'] as String?,
    );
  }
}
