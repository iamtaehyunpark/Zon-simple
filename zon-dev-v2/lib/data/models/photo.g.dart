// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PhotoImpl _$$PhotoImplFromJson(Map<String, dynamic> json) => _$PhotoImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      stampId: json['stampId'] as String?,
      storageUrl: json['storageUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      exifLat: (json['exifLat'] as num?)?.toDouble(),
      exifLng: (json['exifLng'] as num?)?.toDouble(),
      exifTakenAt: json['exifTakenAt'] == null
          ? null
          : DateTime.parse(json['exifTakenAt'] as String),
      rawEventId: json['rawEventId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$PhotoImplToJson(_$PhotoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'stampId': instance.stampId,
      'storageUrl': instance.storageUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'exifLat': instance.exifLat,
      'exifLng': instance.exifLng,
      'exifTakenAt': instance.exifTakenAt?.toIso8601String(),
      'rawEventId': instance.rawEventId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
