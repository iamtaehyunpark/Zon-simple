import 'package:freezed_annotation/freezed_annotation.dart';
import 'place_status.dart';
import 'space_type.dart';

part 'place.freezed.dart';
part 'place.g.dart';

@freezed
class Place with _$Place {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Place({
    required String id,
    required String name,
    required String category,
    required SpaceType spaceType,
    required PlaceStatus status,
    required double lat,
    required double lng,
    String? address,
    int? pendingCount,
    int? referenceCount,
    bool? hasBadge,
  }) = _Place;

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
}
