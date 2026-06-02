import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'raw_location_event.freezed.dart';
part 'raw_location_event.g.dart';

@freezed
class RawLocationEvent with _$RawLocationEvent {
  const factory RawLocationEvent({
    required String id,
    required String userId,
    required double lat,
    required double lng,
    double? accuracyM,
    double? altitudeM,
    required LocationSource source,
    required DateTime capturedAt,
    String? photoId,
    String? stampId,
    String? geocodedName,
  }) = _RawLocationEvent;

  factory RawLocationEvent.fromJson(Map<String, dynamic> json) =>
      _$RawLocationEventFromJson(json);
}
