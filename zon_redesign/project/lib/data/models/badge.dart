import 'package:freezed_annotation/freezed_annotation.dart';
import 'badge_type.dart';

part 'badge.freezed.dart';
part 'badge.g.dart';

@freezed
class Badge with _$Badge {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Badge({
    required String id,
    required String name,
    required BadgeType badgeType,
    required String rarity,
    String? description,
    String? iconUrl,
    String? placeId,
    @Default(false) bool isLimited,
    DateTime? availableFrom,
    DateTime? availableUntil,
    DateTime? earnedAt,
    @Default(false) bool isEarned,
    @Default(false) bool isBackfilled,
  }) = _Badge;

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
}
