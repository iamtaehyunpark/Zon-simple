import 'package:freezed_annotation/freezed_annotation.dart';
import 'auth_tier.dart';
import 'stamp_visibility.dart';

part 'stamp.freezed.dart';
part 'stamp.g.dart';

@freezed
class Stamp with _$Stamp {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Stamp({
    required String id,
    required String userId,
    required String placeId,
    required AuthTier tier,
    required DateTime createdAt,
    required StampVisibility visibility,
    String? caption,
    @Default([]) List<String> photoUrls,
    String? audioUrl,
    String? weather,
    String? season,
    String? timeOfDay,
    double? visionScore,
    double? sensorScore,
    double? finalScore,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(false) bool isLiked,
    @Default(false) bool isSaved,
  }) = _Stamp;

  factory Stamp.fromJson(Map<String, dynamic> json) => _$StampFromJson(json);
}
