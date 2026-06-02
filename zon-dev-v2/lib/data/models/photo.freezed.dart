// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Photo _$PhotoFromJson(Map<String, dynamic> json) {
  return _Photo.fromJson(json);
}

/// @nodoc
mixin _$Photo {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get stampId => throw _privateConstructorUsedError;
  String get storageUrl => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  double? get exifLat => throw _privateConstructorUsedError;
  double? get exifLng => throw _privateConstructorUsedError;
  DateTime? get exifTakenAt => throw _privateConstructorUsedError;
  String? get rawEventId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Photo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Photo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PhotoCopyWith<Photo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PhotoCopyWith<$Res> {
  factory $PhotoCopyWith(Photo value, $Res Function(Photo) then) =
      _$PhotoCopyWithImpl<$Res, Photo>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String? stampId,
      String storageUrl,
      String? thumbnailUrl,
      double? exifLat,
      double? exifLng,
      DateTime? exifTakenAt,
      String? rawEventId,
      DateTime createdAt});
}

/// @nodoc
class _$PhotoCopyWithImpl<$Res, $Val extends Photo>
    implements $PhotoCopyWith<$Res> {
  _$PhotoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Photo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? stampId = freezed,
    Object? storageUrl = null,
    Object? thumbnailUrl = freezed,
    Object? exifLat = freezed,
    Object? exifLng = freezed,
    Object? exifTakenAt = freezed,
    Object? rawEventId = freezed,
    Object? createdAt = null,
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
      stampId: freezed == stampId
          ? _value.stampId
          : stampId // ignore: cast_nullable_to_non_nullable
              as String?,
      storageUrl: null == storageUrl
          ? _value.storageUrl
          : storageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      exifLat: freezed == exifLat
          ? _value.exifLat
          : exifLat // ignore: cast_nullable_to_non_nullable
              as double?,
      exifLng: freezed == exifLng
          ? _value.exifLng
          : exifLng // ignore: cast_nullable_to_non_nullable
              as double?,
      exifTakenAt: freezed == exifTakenAt
          ? _value.exifTakenAt
          : exifTakenAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      rawEventId: freezed == rawEventId
          ? _value.rawEventId
          : rawEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PhotoImplCopyWith<$Res> implements $PhotoCopyWith<$Res> {
  factory _$$PhotoImplCopyWith(
          _$PhotoImpl value, $Res Function(_$PhotoImpl) then) =
      __$$PhotoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String? stampId,
      String storageUrl,
      String? thumbnailUrl,
      double? exifLat,
      double? exifLng,
      DateTime? exifTakenAt,
      String? rawEventId,
      DateTime createdAt});
}

/// @nodoc
class __$$PhotoImplCopyWithImpl<$Res>
    extends _$PhotoCopyWithImpl<$Res, _$PhotoImpl>
    implements _$$PhotoImplCopyWith<$Res> {
  __$$PhotoImplCopyWithImpl(
      _$PhotoImpl _value, $Res Function(_$PhotoImpl) _then)
      : super(_value, _then);

  /// Create a copy of Photo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? stampId = freezed,
    Object? storageUrl = null,
    Object? thumbnailUrl = freezed,
    Object? exifLat = freezed,
    Object? exifLng = freezed,
    Object? exifTakenAt = freezed,
    Object? rawEventId = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$PhotoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      stampId: freezed == stampId
          ? _value.stampId
          : stampId // ignore: cast_nullable_to_non_nullable
              as String?,
      storageUrl: null == storageUrl
          ? _value.storageUrl
          : storageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      exifLat: freezed == exifLat
          ? _value.exifLat
          : exifLat // ignore: cast_nullable_to_non_nullable
              as double?,
      exifLng: freezed == exifLng
          ? _value.exifLng
          : exifLng // ignore: cast_nullable_to_non_nullable
              as double?,
      exifTakenAt: freezed == exifTakenAt
          ? _value.exifTakenAt
          : exifTakenAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      rawEventId: freezed == rawEventId
          ? _value.rawEventId
          : rawEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PhotoImpl implements _Photo {
  const _$PhotoImpl(
      {required this.id,
      required this.userId,
      this.stampId,
      required this.storageUrl,
      this.thumbnailUrl,
      this.exifLat,
      this.exifLng,
      this.exifTakenAt,
      this.rawEventId,
      required this.createdAt});

  factory _$PhotoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PhotoImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? stampId;
  @override
  final String storageUrl;
  @override
  final String? thumbnailUrl;
  @override
  final double? exifLat;
  @override
  final double? exifLng;
  @override
  final DateTime? exifTakenAt;
  @override
  final String? rawEventId;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Photo(id: $id, userId: $userId, stampId: $stampId, storageUrl: $storageUrl, thumbnailUrl: $thumbnailUrl, exifLat: $exifLat, exifLng: $exifLng, exifTakenAt: $exifTakenAt, rawEventId: $rawEventId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PhotoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.stampId, stampId) || other.stampId == stampId) &&
            (identical(other.storageUrl, storageUrl) ||
                other.storageUrl == storageUrl) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.exifLat, exifLat) || other.exifLat == exifLat) &&
            (identical(other.exifLng, exifLng) || other.exifLng == exifLng) &&
            (identical(other.exifTakenAt, exifTakenAt) ||
                other.exifTakenAt == exifTakenAt) &&
            (identical(other.rawEventId, rawEventId) ||
                other.rawEventId == rawEventId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, stampId, storageUrl,
      thumbnailUrl, exifLat, exifLng, exifTakenAt, rawEventId, createdAt);

  /// Create a copy of Photo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PhotoImplCopyWith<_$PhotoImpl> get copyWith =>
      __$$PhotoImplCopyWithImpl<_$PhotoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PhotoImplToJson(
      this,
    );
  }
}

abstract class _Photo implements Photo {
  const factory _Photo(
      {required final String id,
      required final String userId,
      final String? stampId,
      required final String storageUrl,
      final String? thumbnailUrl,
      final double? exifLat,
      final double? exifLng,
      final DateTime? exifTakenAt,
      final String? rawEventId,
      required final DateTime createdAt}) = _$PhotoImpl;

  factory _Photo.fromJson(Map<String, dynamic> json) = _$PhotoImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get stampId;
  @override
  String get storageUrl;
  @override
  String? get thumbnailUrl;
  @override
  double? get exifLat;
  @override
  double? get exifLng;
  @override
  DateTime? get exifTakenAt;
  @override
  String? get rawEventId;
  @override
  DateTime get createdAt;

  /// Create a copy of Photo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PhotoImplCopyWith<_$PhotoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
