import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo.freezed.dart';
part 'photo.g.dart';

@freezed
class Photo with _$Photo {
  const factory Photo({
    required String id,
    required String userId,
    String? stampId,
    required String storageUrl,
    String? thumbnailUrl,
    double? exifLat,
    double? exifLng,
    DateTime? exifTakenAt,
    String? rawEventId,
    required DateTime createdAt,
  }) = _Photo;

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
}
