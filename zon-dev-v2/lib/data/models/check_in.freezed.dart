// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'check_in.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CheckIn _$CheckInFromJson(Map<String, dynamic> json) {
  return _CheckIn.fromJson(json);
}

/// @nodoc
mixin _$CheckIn {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get placeName => throw _privateConstructorUsedError;
  String? get normalizedPlaceName => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  String? get externalPlaceId => throw _privateConstructorUsedError;
  String? get externalSource => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  CheckInSource get source =>
      throw _privateConstructorUsedError; // Private by default (trace layer); public ones surface as feed stories.
  StampVisibility get visibility => throw _privateConstructorUsedError;
  List<String> get taggedUserIds => throw _privateConstructorUsedError;
  List<String> get photoUrls => throw _privateConstructorUsedError;
  int get photoCount =>
      throw _privateConstructorUsedError; // Set (via lookup) when this check-in has already been promoted to a stamp.
  String? get stampId => throw _privateConstructorUsedError;
  DateTime get visitedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CheckIn to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CheckIn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckInCopyWith<CheckIn> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckInCopyWith<$Res> {
  factory $CheckInCopyWith(CheckIn value, $Res Function(CheckIn) then) =
      _$CheckInCopyWithImpl<$Res, CheckIn>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String placeName,
      String? normalizedPlaceName,
      double lat,
      double lng,
      String? externalPlaceId,
      String? externalSource,
      String? note,
      CheckInSource source,
      StampVisibility visibility,
      List<String> taggedUserIds,
      List<String> photoUrls,
      int photoCount,
      String? stampId,
      DateTime visitedAt,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$CheckInCopyWithImpl<$Res, $Val extends CheckIn>
    implements $CheckInCopyWith<$Res> {
  _$CheckInCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CheckIn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? placeName = null,
    Object? normalizedPlaceName = freezed,
    Object? lat = null,
    Object? lng = null,
    Object? externalPlaceId = freezed,
    Object? externalSource = freezed,
    Object? note = freezed,
    Object? source = null,
    Object? visibility = null,
    Object? taggedUserIds = null,
    Object? photoUrls = null,
    Object? photoCount = null,
    Object? stampId = freezed,
    Object? visitedAt = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
      placeName: null == placeName
          ? _value.placeName
          : placeName // ignore: cast_nullable_to_non_nullable
              as String,
      normalizedPlaceName: freezed == normalizedPlaceName
          ? _value.normalizedPlaceName
          : normalizedPlaceName // ignore: cast_nullable_to_non_nullable
              as String?,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      externalPlaceId: freezed == externalPlaceId
          ? _value.externalPlaceId
          : externalPlaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      externalSource: freezed == externalSource
          ? _value.externalSource
          : externalSource // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as CheckInSource,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as StampVisibility,
      taggedUserIds: null == taggedUserIds
          ? _value.taggedUserIds
          : taggedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      photoUrls: null == photoUrls
          ? _value.photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      photoCount: null == photoCount
          ? _value.photoCount
          : photoCount // ignore: cast_nullable_to_non_nullable
              as int,
      stampId: freezed == stampId
          ? _value.stampId
          : stampId // ignore: cast_nullable_to_non_nullable
              as String?,
      visitedAt: null == visitedAt
          ? _value.visitedAt
          : visitedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CheckInImplCopyWith<$Res> implements $CheckInCopyWith<$Res> {
  factory _$$CheckInImplCopyWith(
          _$CheckInImpl value, $Res Function(_$CheckInImpl) then) =
      __$$CheckInImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String placeName,
      String? normalizedPlaceName,
      double lat,
      double lng,
      String? externalPlaceId,
      String? externalSource,
      String? note,
      CheckInSource source,
      StampVisibility visibility,
      List<String> taggedUserIds,
      List<String> photoUrls,
      int photoCount,
      String? stampId,
      DateTime visitedAt,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$CheckInImplCopyWithImpl<$Res>
    extends _$CheckInCopyWithImpl<$Res, _$CheckInImpl>
    implements _$$CheckInImplCopyWith<$Res> {
  __$$CheckInImplCopyWithImpl(
      _$CheckInImpl _value, $Res Function(_$CheckInImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckIn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? placeName = null,
    Object? normalizedPlaceName = freezed,
    Object? lat = null,
    Object? lng = null,
    Object? externalPlaceId = freezed,
    Object? externalSource = freezed,
    Object? note = freezed,
    Object? source = null,
    Object? visibility = null,
    Object? taggedUserIds = null,
    Object? photoUrls = null,
    Object? photoCount = null,
    Object? stampId = freezed,
    Object? visitedAt = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$CheckInImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      placeName: null == placeName
          ? _value.placeName
          : placeName // ignore: cast_nullable_to_non_nullable
              as String,
      normalizedPlaceName: freezed == normalizedPlaceName
          ? _value.normalizedPlaceName
          : normalizedPlaceName // ignore: cast_nullable_to_non_nullable
              as String?,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      externalPlaceId: freezed == externalPlaceId
          ? _value.externalPlaceId
          : externalPlaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      externalSource: freezed == externalSource
          ? _value.externalSource
          : externalSource // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as CheckInSource,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as StampVisibility,
      taggedUserIds: null == taggedUserIds
          ? _value._taggedUserIds
          : taggedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      photoUrls: null == photoUrls
          ? _value._photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      photoCount: null == photoCount
          ? _value.photoCount
          : photoCount // ignore: cast_nullable_to_non_nullable
              as int,
      stampId: freezed == stampId
          ? _value.stampId
          : stampId // ignore: cast_nullable_to_non_nullable
              as String?,
      visitedAt: null == visitedAt
          ? _value.visitedAt
          : visitedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CheckInImpl implements _CheckIn {
  const _$CheckInImpl(
      {required this.id,
      required this.userId,
      required this.placeName,
      this.normalizedPlaceName,
      required this.lat,
      required this.lng,
      this.externalPlaceId,
      this.externalSource,
      this.note,
      this.source = CheckInSource.manual,
      this.visibility = StampVisibility.private,
      final List<String> taggedUserIds = const [],
      final List<String> photoUrls = const [],
      this.photoCount = 0,
      this.stampId,
      required this.visitedAt,
      this.createdAt,
      this.updatedAt})
      : _taggedUserIds = taggedUserIds,
        _photoUrls = photoUrls;

  factory _$CheckInImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckInImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String placeName;
  @override
  final String? normalizedPlaceName;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final String? externalPlaceId;
  @override
  final String? externalSource;
  @override
  final String? note;
  @override
  @JsonKey()
  final CheckInSource source;
// Private by default (trace layer); public ones surface as feed stories.
  @override
  @JsonKey()
  final StampVisibility visibility;
  final List<String> _taggedUserIds;
  @override
  @JsonKey()
  List<String> get taggedUserIds {
    if (_taggedUserIds is EqualUnmodifiableListView) return _taggedUserIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_taggedUserIds);
  }

  final List<String> _photoUrls;
  @override
  @JsonKey()
  List<String> get photoUrls {
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoUrls);
  }

  @override
  @JsonKey()
  final int photoCount;
// Set (via lookup) when this check-in has already been promoted to a stamp.
  @override
  final String? stampId;
  @override
  final DateTime visitedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'CheckIn(id: $id, userId: $userId, placeName: $placeName, normalizedPlaceName: $normalizedPlaceName, lat: $lat, lng: $lng, externalPlaceId: $externalPlaceId, externalSource: $externalSource, note: $note, source: $source, visibility: $visibility, taggedUserIds: $taggedUserIds, photoUrls: $photoUrls, photoCount: $photoCount, stampId: $stampId, visitedAt: $visitedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckInImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.placeName, placeName) ||
                other.placeName == placeName) &&
            (identical(other.normalizedPlaceName, normalizedPlaceName) ||
                other.normalizedPlaceName == normalizedPlaceName) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.externalPlaceId, externalPlaceId) ||
                other.externalPlaceId == externalPlaceId) &&
            (identical(other.externalSource, externalSource) ||
                other.externalSource == externalSource) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            const DeepCollectionEquality()
                .equals(other._taggedUserIds, _taggedUserIds) &&
            const DeepCollectionEquality()
                .equals(other._photoUrls, _photoUrls) &&
            (identical(other.photoCount, photoCount) ||
                other.photoCount == photoCount) &&
            (identical(other.stampId, stampId) || other.stampId == stampId) &&
            (identical(other.visitedAt, visitedAt) ||
                other.visitedAt == visitedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      placeName,
      normalizedPlaceName,
      lat,
      lng,
      externalPlaceId,
      externalSource,
      note,
      source,
      visibility,
      const DeepCollectionEquality().hash(_taggedUserIds),
      const DeepCollectionEquality().hash(_photoUrls),
      photoCount,
      stampId,
      visitedAt,
      createdAt,
      updatedAt);

  /// Create a copy of CheckIn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckInImplCopyWith<_$CheckInImpl> get copyWith =>
      __$$CheckInImplCopyWithImpl<_$CheckInImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CheckInImplToJson(
      this,
    );
  }
}

abstract class _CheckIn implements CheckIn {
  const factory _CheckIn(
      {required final String id,
      required final String userId,
      required final String placeName,
      final String? normalizedPlaceName,
      required final double lat,
      required final double lng,
      final String? externalPlaceId,
      final String? externalSource,
      final String? note,
      final CheckInSource source,
      final StampVisibility visibility,
      final List<String> taggedUserIds,
      final List<String> photoUrls,
      final int photoCount,
      final String? stampId,
      required final DateTime visitedAt,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$CheckInImpl;

  factory _CheckIn.fromJson(Map<String, dynamic> json) = _$CheckInImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get placeName;
  @override
  String? get normalizedPlaceName;
  @override
  double get lat;
  @override
  double get lng;
  @override
  String? get externalPlaceId;
  @override
  String? get externalSource;
  @override
  String? get note;
  @override
  CheckInSource
      get source; // Private by default (trace layer); public ones surface as feed stories.
  @override
  StampVisibility get visibility;
  @override
  List<String> get taggedUserIds;
  @override
  List<String> get photoUrls;
  @override
  int get photoCount; // Set (via lookup) when this check-in has already been promoted to a stamp.
  @override
  String? get stampId;
  @override
  DateTime get visitedAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of CheckIn
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckInImplCopyWith<_$CheckInImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CheckInDraft _$CheckInDraftFromJson(Map<String, dynamic> json) {
  return _CheckInDraft.fromJson(json);
}

/// @nodoc
mixin _$CheckInDraft {
  String get placeName => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  String? get externalPlaceId => throw _privateConstructorUsedError;
  String? get externalSource => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  CheckInSource get source => throw _privateConstructorUsedError;
  StampVisibility get visibility => throw _privateConstructorUsedError;
  List<String> get taggedUserIds => throw _privateConstructorUsedError;
  List<String> get photoPaths => throw _privateConstructorUsedError;

  /// Serializes this CheckInDraft to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CheckInDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckInDraftCopyWith<CheckInDraft> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckInDraftCopyWith<$Res> {
  factory $CheckInDraftCopyWith(
          CheckInDraft value, $Res Function(CheckInDraft) then) =
      _$CheckInDraftCopyWithImpl<$Res, CheckInDraft>;
  @useResult
  $Res call(
      {String placeName,
      double lat,
      double lng,
      String? externalPlaceId,
      String? externalSource,
      String? note,
      CheckInSource source,
      StampVisibility visibility,
      List<String> taggedUserIds,
      List<String> photoPaths});
}

/// @nodoc
class _$CheckInDraftCopyWithImpl<$Res, $Val extends CheckInDraft>
    implements $CheckInDraftCopyWith<$Res> {
  _$CheckInDraftCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CheckInDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? placeName = null,
    Object? lat = null,
    Object? lng = null,
    Object? externalPlaceId = freezed,
    Object? externalSource = freezed,
    Object? note = freezed,
    Object? source = null,
    Object? visibility = null,
    Object? taggedUserIds = null,
    Object? photoPaths = null,
  }) {
    return _then(_value.copyWith(
      placeName: null == placeName
          ? _value.placeName
          : placeName // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      externalPlaceId: freezed == externalPlaceId
          ? _value.externalPlaceId
          : externalPlaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      externalSource: freezed == externalSource
          ? _value.externalSource
          : externalSource // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as CheckInSource,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as StampVisibility,
      taggedUserIds: null == taggedUserIds
          ? _value.taggedUserIds
          : taggedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      photoPaths: null == photoPaths
          ? _value.photoPaths
          : photoPaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CheckInDraftImplCopyWith<$Res>
    implements $CheckInDraftCopyWith<$Res> {
  factory _$$CheckInDraftImplCopyWith(
          _$CheckInDraftImpl value, $Res Function(_$CheckInDraftImpl) then) =
      __$$CheckInDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String placeName,
      double lat,
      double lng,
      String? externalPlaceId,
      String? externalSource,
      String? note,
      CheckInSource source,
      StampVisibility visibility,
      List<String> taggedUserIds,
      List<String> photoPaths});
}

/// @nodoc
class __$$CheckInDraftImplCopyWithImpl<$Res>
    extends _$CheckInDraftCopyWithImpl<$Res, _$CheckInDraftImpl>
    implements _$$CheckInDraftImplCopyWith<$Res> {
  __$$CheckInDraftImplCopyWithImpl(
      _$CheckInDraftImpl _value, $Res Function(_$CheckInDraftImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckInDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? placeName = null,
    Object? lat = null,
    Object? lng = null,
    Object? externalPlaceId = freezed,
    Object? externalSource = freezed,
    Object? note = freezed,
    Object? source = null,
    Object? visibility = null,
    Object? taggedUserIds = null,
    Object? photoPaths = null,
  }) {
    return _then(_$CheckInDraftImpl(
      placeName: null == placeName
          ? _value.placeName
          : placeName // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      externalPlaceId: freezed == externalPlaceId
          ? _value.externalPlaceId
          : externalPlaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      externalSource: freezed == externalSource
          ? _value.externalSource
          : externalSource // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as CheckInSource,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as StampVisibility,
      taggedUserIds: null == taggedUserIds
          ? _value._taggedUserIds
          : taggedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      photoPaths: null == photoPaths
          ? _value._photoPaths
          : photoPaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CheckInDraftImpl implements _CheckInDraft {
  const _$CheckInDraftImpl(
      {required this.placeName,
      required this.lat,
      required this.lng,
      this.externalPlaceId,
      this.externalSource,
      this.note,
      this.source = CheckInSource.manual,
      this.visibility = StampVisibility.private,
      final List<String> taggedUserIds = const [],
      final List<String> photoPaths = const []})
      : _taggedUserIds = taggedUserIds,
        _photoPaths = photoPaths;

  factory _$CheckInDraftImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckInDraftImplFromJson(json);

  @override
  final String placeName;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final String? externalPlaceId;
  @override
  final String? externalSource;
  @override
  final String? note;
  @override
  @JsonKey()
  final CheckInSource source;
  @override
  @JsonKey()
  final StampVisibility visibility;
  final List<String> _taggedUserIds;
  @override
  @JsonKey()
  List<String> get taggedUserIds {
    if (_taggedUserIds is EqualUnmodifiableListView) return _taggedUserIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_taggedUserIds);
  }

  final List<String> _photoPaths;
  @override
  @JsonKey()
  List<String> get photoPaths {
    if (_photoPaths is EqualUnmodifiableListView) return _photoPaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoPaths);
  }

  @override
  String toString() {
    return 'CheckInDraft(placeName: $placeName, lat: $lat, lng: $lng, externalPlaceId: $externalPlaceId, externalSource: $externalSource, note: $note, source: $source, visibility: $visibility, taggedUserIds: $taggedUserIds, photoPaths: $photoPaths)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckInDraftImpl &&
            (identical(other.placeName, placeName) ||
                other.placeName == placeName) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.externalPlaceId, externalPlaceId) ||
                other.externalPlaceId == externalPlaceId) &&
            (identical(other.externalSource, externalSource) ||
                other.externalSource == externalSource) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            const DeepCollectionEquality()
                .equals(other._taggedUserIds, _taggedUserIds) &&
            const DeepCollectionEquality()
                .equals(other._photoPaths, _photoPaths));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      placeName,
      lat,
      lng,
      externalPlaceId,
      externalSource,
      note,
      source,
      visibility,
      const DeepCollectionEquality().hash(_taggedUserIds),
      const DeepCollectionEquality().hash(_photoPaths));

  /// Create a copy of CheckInDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckInDraftImplCopyWith<_$CheckInDraftImpl> get copyWith =>
      __$$CheckInDraftImplCopyWithImpl<_$CheckInDraftImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CheckInDraftImplToJson(
      this,
    );
  }
}

abstract class _CheckInDraft implements CheckInDraft {
  const factory _CheckInDraft(
      {required final String placeName,
      required final double lat,
      required final double lng,
      final String? externalPlaceId,
      final String? externalSource,
      final String? note,
      final CheckInSource source,
      final StampVisibility visibility,
      final List<String> taggedUserIds,
      final List<String> photoPaths}) = _$CheckInDraftImpl;

  factory _CheckInDraft.fromJson(Map<String, dynamic> json) =
      _$CheckInDraftImpl.fromJson;

  @override
  String get placeName;
  @override
  double get lat;
  @override
  double get lng;
  @override
  String? get externalPlaceId;
  @override
  String? get externalSource;
  @override
  String? get note;
  @override
  CheckInSource get source;
  @override
  StampVisibility get visibility;
  @override
  List<String> get taggedUserIds;
  @override
  List<String> get photoPaths;

  /// Create a copy of CheckInDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckInDraftImplCopyWith<_$CheckInDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
