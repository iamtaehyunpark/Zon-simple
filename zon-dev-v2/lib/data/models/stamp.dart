import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'stamp.freezed.dart';
part 'stamp.g.dart';

@freezed
class Stamp with _$Stamp {
  const factory Stamp({
    required String id,
    required String userId,
    required String placeName,
    String? normalizedPlaceName,
    required double lat,
    required double lng,
    String? externalPlaceId,
    String? externalSource,
    required StampVisibility visibility,
    String? coverPhotoUrl,
    String? caption,
    @Default([]) List<String> sensoryTags,
    @Default([]) List<String> taggedUserIds,
    @Default([]) List<String> photoUrls,
    required DateTime visitedAt,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(0) int photoCount,
    @Default(false) bool isLiked,
    @Default(false) bool isSaved,
    // Populated when fetched from v_feed_stamps view
    String? username,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Stamp;

  factory Stamp.fromJson(Map<String, dynamic> json) => _$StampFromJson(json);
}

@freezed
class StampDraft with _$StampDraft {
  const factory StampDraft({
    String? existingStampId,
    required String placeName,
    required double lat,
    required double lng,
    String? externalPlaceId,
    String? externalSource,
    @Default(StampVisibility.private) StampVisibility visibility,
    String? caption,
    @Default([]) List<String> sensoryTags,
    @Default([]) List<String> taggedUserIds,
    @Default([]) List<String> selectedPhotoPaths,
    String? coverPhotoPath,
  }) = _StampDraft;

  factory StampDraft.fromJson(Map<String, dynamic> json) =>
      _$StampDraftFromJson(json);
}
