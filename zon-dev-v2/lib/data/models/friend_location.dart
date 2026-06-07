/// Ephemeral real-time location of a mutual friend on the Snap Map layer.
/// Not freezed — this data is never persisted or serialised to JSON.
class FriendLocation {
  final String userId;
  final double lat;
  final double lng;
  final DateTime updatedAt;
  final String username;
  final String? avatarUrl;

  const FriendLocation({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.updatedAt,
    required this.username,
    this.avatarUrl,
  });

  /// Older than 8 hours → treat as offline (matches Snapchat's window).
  bool get isStale => DateTime.now().difference(updatedAt).inHours >= 8;

  String get timeLabel {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  FriendLocation copyWith({double? lat, double? lng, DateTime? updatedAt}) =>
      FriendLocation(
        userId: userId,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        updatedAt: updatedAt ?? this.updatedAt,
        username: username,
        avatarUrl: avatarUrl,
      );
}
