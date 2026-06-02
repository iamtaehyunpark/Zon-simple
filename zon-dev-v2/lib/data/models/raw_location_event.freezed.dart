// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'raw_location_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RawLocationEvent _$RawLocationEventFromJson(Map<String, dynamic> json) {
  return _RawLocationEvent.fromJson(json);
}

/// @nodoc
mixin _$RawLocationEvent {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  double? get accuracyM => throw _privateConstructorUsedError;
  double? get altitudeM => throw _privateConstructorUsedError;
  LocationSource get source => throw _privateConstructorUsedError;
  DateTime get capturedAt => throw _privateConstructorUsedError;
  String? get photoId => throw _privateConstructorUsedError;
  String? get stampId => throw _privateConstructorUsedError;
  String? get geocodedName => throw _privateConstructorUsedError;

  /// Serializes this RawLocationEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RawLocationEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RawLocationEventCopyWith<RawLocationEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RawLocationEventCopyWith<$Res> {
  factory $RawLocationEventCopyWith(
          RawLocationEvent value, $Res Function(RawLocationEvent) then) =
      _$RawLocationEventCopyWithImpl<$Res, RawLocationEvent>;
  @useResult
  $Res call(
      {String id,
      String userId,
      double lat,
      double lng,
      double? accuracyM,
      double? altitudeM,
      LocationSource source,
      DateTime capturedAt,
      String? photoId,
      String? stampId,
      String? geocodedName});
}

/// @nodoc
class _$RawLocationEventCopyWithImpl<$Res, $Val extends RawLocationEvent>
    implements $RawLocationEventCopyWith<$Res> {
  _$RawLocationEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RawLocationEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? lat = null,
    Object? lng = null,
    Object? accuracyM = freezed,
    Object? altitudeM = freezed,
    Object? source = null,
    Object? capturedAt = null,
    Object? photoId = freezed,
    Object? stampId = freezed,
    Object? geocodedName = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      accuracyM: freezed == accuracyM
          ? _value.accuracyM
          : accuracyM // ignore: cast_nullable_to_non_nullable
              as double?,
      altitudeM: freezed == altitudeM
          ? _value.altitudeM
          : altitudeM // ignore: cast_nullable_to_non_nullable
              as double?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as LocationSource,
      capturedAt: null == capturedAt
          ? _value.capturedAt
          : capturedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      photoId: freezed == photoId
          ? _value.photoId
          : photoId // ignore: cast_nullable_to_non_nullable
              as String?,
      stampId: freezed == stampId
          ? _value.stampId
          : stampId // ignore: cast_nullable_to_non_nullable
              as String?,
      geocodedName: freezed == geocodedName
          ? _value.geocodedName
          : geocodedName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RawLocationEventImplCopyWith<$Res>
    implements $RawLocationEventCopyWith<$Res> {
  factory _$$RawLocationEventImplCopyWith(_$RawLocationEventImpl value,
          $Res Function(_$RawLocationEventImpl) then) =
      __$$RawLocationEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      double lat,
      double lng,
      double? accuracyM,
      double? altitudeM,
      LocationSource source,
      DateTime capturedAt,
      String? photoId,
      String? stampId,
      String? geocodedName});
}

/// @nodoc
class __$$RawLocationEventImplCopyWithImpl<$Res>
    extends _$RawLocationEventCopyWithImpl<$Res, _$RawLocationEventImpl>
    implements _$$RawLocationEventImplCopyWith<$Res> {
  __$$RawLocationEventImplCopyWithImpl(_$RawLocationEventImpl _value,
      $Res Function(_$RawLocationEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of RawLocationEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? lat = null,
    Object? lng = null,
    Object? accuracyM = freezed,
    Object? altitudeM = freezed,
    Object? source = null,
    Object? capturedAt = null,
    Object? photoId = freezed,
    Object? stampId = freezed,
    Object? geocodedName = freezed,
  }) {
    return _then(_$RawLocationEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      accuracyM: freezed == accuracyM
          ? _value.accuracyM
          : accuracyM // ignore: cast_nullable_to_non_nullable
              as double?,
      altitudeM: freezed == altitudeM
          ? _value.altitudeM
          : altitudeM // ignore: cast_nullable_to_non_nullable
              as double?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as LocationSource,
      capturedAt: null == capturedAt
          ? _value.capturedAt
          : capturedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      photoId: freezed == photoId
          ? _value.photoId
          : photoId // ignore: cast_nullable_to_non_nullable
              as String?,
      stampId: freezed == stampId
          ? _value.stampId
          : stampId // ignore: cast_nullable_to_non_nullable
              as String?,
      geocodedName: freezed == geocodedName
          ? _value.geocodedName
          : geocodedName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RawLocationEventImpl implements _RawLocationEvent {
  const _$RawLocationEventImpl(
      {required this.id,
      required this.userId,
      required this.lat,
      required this.lng,
      this.accuracyM,
      this.altitudeM,
      required this.source,
      required this.capturedAt,
      this.photoId,
      this.stampId,
      this.geocodedName});

  factory _$RawLocationEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$RawLocationEventImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final double? accuracyM;
  @override
  final double? altitudeM;
  @override
  final LocationSource source;
  @override
  final DateTime capturedAt;
  @override
  final String? photoId;
  @override
  final String? stampId;
  @override
  final String? geocodedName;

  @override
  String toString() {
    return 'RawLocationEvent(id: $id, userId: $userId, lat: $lat, lng: $lng, accuracyM: $accuracyM, altitudeM: $altitudeM, source: $source, capturedAt: $capturedAt, photoId: $photoId, stampId: $stampId, geocodedName: $geocodedName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RawLocationEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.accuracyM, accuracyM) ||
                other.accuracyM == accuracyM) &&
            (identical(other.altitudeM, altitudeM) ||
                other.altitudeM == altitudeM) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.capturedAt, capturedAt) ||
                other.capturedAt == capturedAt) &&
            (identical(other.photoId, photoId) || other.photoId == photoId) &&
            (identical(other.stampId, stampId) || other.stampId == stampId) &&
            (identical(other.geocodedName, geocodedName) ||
                other.geocodedName == geocodedName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, lat, lng, accuracyM,
      altitudeM, source, capturedAt, photoId, stampId, geocodedName);

  /// Create a copy of RawLocationEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RawLocationEventImplCopyWith<_$RawLocationEventImpl> get copyWith =>
      __$$RawLocationEventImplCopyWithImpl<_$RawLocationEventImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RawLocationEventImplToJson(
      this,
    );
  }
}

abstract class _RawLocationEvent implements RawLocationEvent {
  const factory _RawLocationEvent(
      {required final String id,
      required final String userId,
      required final double lat,
      required final double lng,
      final double? accuracyM,
      final double? altitudeM,
      required final LocationSource source,
      required final DateTime capturedAt,
      final String? photoId,
      final String? stampId,
      final String? geocodedName}) = _$RawLocationEventImpl;

  factory _RawLocationEvent.fromJson(Map<String, dynamic> json) =
      _$RawLocationEventImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  double get lat;
  @override
  double get lng;
  @override
  double? get accuracyM;
  @override
  double? get altitudeM;
  @override
  LocationSource get source;
  @override
  DateTime get capturedAt;
  @override
  String? get photoId;
  @override
  String? get stampId;
  @override
  String? get geocodedName;

  /// Create a copy of RawLocationEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RawLocationEventImplCopyWith<_$RawLocationEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
