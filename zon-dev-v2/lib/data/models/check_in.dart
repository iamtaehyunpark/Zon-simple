import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'check_in.freezed.dart';
part 'check_in.g.dart';

/// How a check-in came to exist.
enum CheckInSource { manual, photo, auto }

/// A discrete, always-private visit log — the "pin" layer of the trace.
/// A [Stamp] is a check-in promoted to a post (`stamp ⊂ check-in`).
@freezed
class CheckIn with _$CheckIn {
  const factory CheckIn({
    required String id,
    required String userId,
    required String placeName,
    String? normalizedPlaceName,
    required double lat,
    required double lng,
    String? externalPlaceId,
    String? externalSource,
    String? note,
    @Default(CheckInSource.manual) CheckInSource source,
    // Private by default (trace layer); public ones surface as feed stories.
    @Default(StampVisibility.private) StampVisibility visibility,
    @Default([]) List<String> taggedUserIds,
    @Default([]) List<String> photoUrls,
    @Default(0) int photoCount,
    // Set (via lookup) when this check-in has already been promoted to a stamp.
    String? stampId,
    required DateTime visitedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CheckIn;

  factory CheckIn.fromJson(Map<String, dynamic> json) => _$CheckInFromJson(json);
}

/// Draft for creating a check-in. [photoPaths] are local files to upload.
@freezed
class CheckInDraft with _$CheckInDraft {
  const factory CheckInDraft({
    required String placeName,
    required double lat,
    required double lng,
    String? externalPlaceId,
    String? externalSource,
    String? note,
    @Default(CheckInSource.manual) CheckInSource source,
    @Default(StampVisibility.private) StampVisibility visibility,
    @Default([]) List<String> taggedUserIds,
    @Default([]) List<String> photoPaths,
  }) = _CheckInDraft;

  factory CheckInDraft.fromJson(Map<String, dynamic> json) =>
      _$CheckInDraftFromJson(json);
}
