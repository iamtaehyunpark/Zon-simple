// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raw_location_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RawLocationEventImpl _$$RawLocationEventImplFromJson(
        Map<String, dynamic> json) =>
    _$RawLocationEventImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      accuracyM: (json['accuracyM'] as num?)?.toDouble(),
      altitudeM: (json['altitudeM'] as num?)?.toDouble(),
      source: $enumDecode(_$LocationSourceEnumMap, json['source']),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      photoId: json['photoId'] as String?,
      stampId: json['stampId'] as String?,
      geocodedName: json['geocodedName'] as String?,
    );

Map<String, dynamic> _$$RawLocationEventImplToJson(
        _$RawLocationEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'lat': instance.lat,
      'lng': instance.lng,
      'accuracyM': instance.accuracyM,
      'altitudeM': instance.altitudeM,
      'source': _$LocationSourceEnumMap[instance.source]!,
      'capturedAt': instance.capturedAt.toIso8601String(),
      'photoId': instance.photoId,
      'stampId': instance.stampId,
      'geocodedName': instance.geocodedName,
    };

const _$LocationSourceEnumMap = {
  LocationSource.gps: 'gps',
  LocationSource.exif: 'exif',
  LocationSource.cellTower: 'cellTower',
};
