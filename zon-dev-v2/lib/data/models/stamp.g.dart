// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stamp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StampImpl _$$StampImplFromJson(Map<String, dynamic> json) => _$StampImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      placeName: json['placeName'] as String,
      normalizedPlaceName: json['normalizedPlaceName'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      externalPlaceId: json['externalPlaceId'] as String?,
      externalSource: json['externalSource'] as String?,
      checkInId: json['checkInId'] as String?,
      visibility: $enumDecode(_$StampVisibilityEnumMap, json['visibility']),
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      caption: json['caption'] as String?,
      sensoryTags: (json['sensoryTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      taggedUserIds: (json['taggedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      visitedAt: DateTime.parse(json['visitedAt'] as String),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$StampImplToJson(_$StampImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'placeName': instance.placeName,
      'normalizedPlaceName': instance.normalizedPlaceName,
      'lat': instance.lat,
      'lng': instance.lng,
      'externalPlaceId': instance.externalPlaceId,
      'externalSource': instance.externalSource,
      'checkInId': instance.checkInId,
      'visibility': _$StampVisibilityEnumMap[instance.visibility]!,
      'coverPhotoUrl': instance.coverPhotoUrl,
      'caption': instance.caption,
      'sensoryTags': instance.sensoryTags,
      'taggedUserIds': instance.taggedUserIds,
      'photoUrls': instance.photoUrls,
      'visitedAt': instance.visitedAt.toIso8601String(),
      'likeCount': instance.likeCount,
      'commentCount': instance.commentCount,
      'photoCount': instance.photoCount,
      'isLiked': instance.isLiked,
      'isSaved': instance.isSaved,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$StampVisibilityEnumMap = {
  StampVisibility.private: 'private',
  StampVisibility.public: 'public',
};

_$StampDraftImpl _$$StampDraftImplFromJson(Map<String, dynamic> json) =>
    _$StampDraftImpl(
      existingStampId: json['existingStampId'] as String?,
      checkInId: json['checkInId'] as String?,
      placeName: json['placeName'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      externalPlaceId: json['externalPlaceId'] as String?,
      externalSource: json['externalSource'] as String?,
      visibility:
          $enumDecodeNullable(_$StampVisibilityEnumMap, json['visibility']) ??
              StampVisibility.private,
      caption: json['caption'] as String?,
      sensoryTags: (json['sensoryTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      taggedUserIds: (json['taggedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      selectedPhotoPaths: (json['selectedPhotoPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      existingPhotoUrls: (json['existingPhotoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      coverPhotoPath: json['coverPhotoPath'] as String?,
    );

Map<String, dynamic> _$$StampDraftImplToJson(_$StampDraftImpl instance) =>
    <String, dynamic>{
      'existingStampId': instance.existingStampId,
      'checkInId': instance.checkInId,
      'placeName': instance.placeName,
      'lat': instance.lat,
      'lng': instance.lng,
      'externalPlaceId': instance.externalPlaceId,
      'externalSource': instance.externalSource,
      'visibility': _$StampVisibilityEnumMap[instance.visibility]!,
      'caption': instance.caption,
      'sensoryTags': instance.sensoryTags,
      'taggedUserIds': instance.taggedUserIds,
      'selectedPhotoPaths': instance.selectedPhotoPaths,
      'existingPhotoUrls': instance.existingPhotoUrls,
      'coverPhotoPath': instance.coverPhotoPath,
    };
