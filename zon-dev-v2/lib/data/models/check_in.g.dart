// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CheckInImpl _$$CheckInImplFromJson(Map<String, dynamic> json) =>
    _$CheckInImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      placeName: json['placeName'] as String,
      normalizedPlaceName: json['normalizedPlaceName'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      externalPlaceId: json['externalPlaceId'] as String?,
      externalSource: json['externalSource'] as String?,
      note: json['note'] as String?,
      source: $enumDecodeNullable(_$CheckInSourceEnumMap, json['source']) ??
          CheckInSource.manual,
      visibility:
          $enumDecodeNullable(_$StampVisibilityEnumMap, json['visibility']) ??
              StampVisibility.private,
      taggedUserIds: (json['taggedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      stampId: json['stampId'] as String?,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$CheckInImplToJson(_$CheckInImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'placeName': instance.placeName,
      'normalizedPlaceName': instance.normalizedPlaceName,
      'lat': instance.lat,
      'lng': instance.lng,
      'externalPlaceId': instance.externalPlaceId,
      'externalSource': instance.externalSource,
      'note': instance.note,
      'source': _$CheckInSourceEnumMap[instance.source]!,
      'visibility': _$StampVisibilityEnumMap[instance.visibility]!,
      'taggedUserIds': instance.taggedUserIds,
      'photoUrls': instance.photoUrls,
      'photoCount': instance.photoCount,
      'stampId': instance.stampId,
      'visitedAt': instance.visitedAt.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$CheckInSourceEnumMap = {
  CheckInSource.manual: 'manual',
  CheckInSource.photo: 'photo',
  CheckInSource.auto: 'auto',
};

const _$StampVisibilityEnumMap = {
  StampVisibility.private: 'private',
  StampVisibility.public: 'public',
};

_$CheckInDraftImpl _$$CheckInDraftImplFromJson(Map<String, dynamic> json) =>
    _$CheckInDraftImpl(
      placeName: json['placeName'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      externalPlaceId: json['externalPlaceId'] as String?,
      externalSource: json['externalSource'] as String?,
      note: json['note'] as String?,
      source: $enumDecodeNullable(_$CheckInSourceEnumMap, json['source']) ??
          CheckInSource.manual,
      visibility:
          $enumDecodeNullable(_$StampVisibilityEnumMap, json['visibility']) ??
              StampVisibility.private,
      taggedUserIds: (json['taggedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      photoPaths: (json['photoPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CheckInDraftImplToJson(_$CheckInDraftImpl instance) =>
    <String, dynamic>{
      'placeName': instance.placeName,
      'lat': instance.lat,
      'lng': instance.lng,
      'externalPlaceId': instance.externalPlaceId,
      'externalSource': instance.externalSource,
      'note': instance.note,
      'source': _$CheckInSourceEnumMap[instance.source]!,
      'visibility': _$StampVisibilityEnumMap[instance.visibility]!,
      'taggedUserIds': instance.taggedUserIds,
      'photoPaths': instance.photoPaths,
    };
