// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stamp.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Stamp _$StampFromJson(Map<String, dynamic> json) {
  return _Stamp.fromJson(json);
}

/// @nodoc
mixin _$Stamp {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get placeName => throw _privateConstructorUsedError;
  String? get normalizedPlaceName => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  String? get externalPlaceId => throw _privateConstructorUsedError;
  String? get externalSource => throw _privateConstructorUsedError;
  String? get checkInId => throw _privateConstructorUsedError;
  StampVisibility get visibility => throw _privateConstructorUsedError;
  String? get coverPhotoUrl => throw _privateConstructorUsedError;
  String? get caption => throw _privateConstructorUsedError;
  List<String> get sensoryTags => throw _privateConstructorUsedError;
  List<String> get taggedUserIds => throw _privateConstructorUsedError;
  List<String> get photoUrls => throw _privateConstructorUsedError;
  DateTime get visitedAt => throw _privateConstructorUsedError;
  int get likeCount => throw _privateConstructorUsedError;
  int get commentCount => throw _privateConstructorUsedError;
  int get photoCount => throw _privateConstructorUsedError;
  bool get isLiked => throw _privateConstructorUsedError;
  bool get isSaved =>
      throw _privateConstructorUsedError; // Populated when fetched from v_feed_stamps view
  String? get username => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Stamp to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Stamp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StampCopyWith<Stamp> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StampCopyWith<$Res> {
  factory $StampCopyWith(Stamp value, $Res Function(Stamp) then) =
      _$StampCopyWithImpl<$Res, Stamp>;
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
      String? checkInId,
      StampVisibility visibility,
      String? coverPhotoUrl,
      String? caption,
      List<String> sensoryTags,
      List<String> taggedUserIds,
      List<String> photoUrls,
      DateTime visitedAt,
      int likeCount,
      int commentCount,
      int photoCount,
      bool isLiked,
      bool isSaved,
      String? username,
      String? avatarUrl,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$StampCopyWithImpl<$Res, $Val extends Stamp>
    implements $StampCopyWith<$Res> {
  _$StampCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Stamp
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
    Object? checkInId = freezed,
    Object? visibility = null,
    Object? coverPhotoUrl = freezed,
    Object? caption = freezed,
    Object? sensoryTags = null,
    Object? taggedUserIds = null,
    Object? photoUrls = null,
    Object? visitedAt = null,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? photoCount = null,
    Object? isLiked = null,
    Object? isSaved = null,
    Object? username = freezed,
    Object? avatarUrl = freezed,
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
      checkInId: freezed == checkInId
          ? _value.checkInId
          : checkInId // ignore: cast_nullable_to_non_nullable
              as String?,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as StampVisibility,
      coverPhotoUrl: freezed == coverPhotoUrl
          ? _value.coverPhotoUrl
          : coverPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      sensoryTags: null == sensoryTags
          ? _value.sensoryTags
          : sensoryTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      taggedUserIds: null == taggedUserIds
          ? _value.taggedUserIds
          : taggedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      photoUrls: null == photoUrls
          ? _value.photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      visitedAt: null == visitedAt
          ? _value.visitedAt
          : visitedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      likeCount: null == likeCount
          ? _value.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentCount: null == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int,
      photoCount: null == photoCount
          ? _value.photoCount
          : photoCount // ignore: cast_nullable_to_non_nullable
              as int,
      isLiked: null == isLiked
          ? _value.isLiked
          : isLiked // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaved: null == isSaved
          ? _value.isSaved
          : isSaved // ignore: cast_nullable_to_non_nullable
              as bool,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$StampImplCopyWith<$Res> implements $StampCopyWith<$Res> {
  factory _$$StampImplCopyWith(
          _$StampImpl value, $Res Function(_$StampImpl) then) =
      __$$StampImplCopyWithImpl<$Res>;
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
      String? checkInId,
      StampVisibility visibility,
      String? coverPhotoUrl,
      String? caption,
      List<String> sensoryTags,
      List<String> taggedUserIds,
      List<String> photoUrls,
      DateTime visitedAt,
      int likeCount,
      int commentCount,
      int photoCount,
      bool isLiked,
      bool isSaved,
      String? username,
      String? avatarUrl,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$StampImplCopyWithImpl<$Res>
    extends _$StampCopyWithImpl<$Res, _$StampImpl>
    implements _$$StampImplCopyWith<$Res> {
  __$$StampImplCopyWithImpl(
      _$StampImpl _value, $Res Function(_$StampImpl) _then)
      : super(_value, _then);

  /// Create a copy of Stamp
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
    Object? checkInId = freezed,
    Object? visibility = null,
    Object? coverPhotoUrl = freezed,
    Object? caption = freezed,
    Object? sensoryTags = null,
    Object? taggedUserIds = null,
    Object? photoUrls = null,
    Object? visitedAt = null,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? photoCount = null,
    Object? isLiked = null,
    Object? isSaved = null,
    Object? username = freezed,
    Object? avatarUrl = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$StampImpl(
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
      checkInId: freezed == checkInId
          ? _value.checkInId
          : checkInId // ignore: cast_nullable_to_non_nullable
              as String?,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as StampVisibility,
      coverPhotoUrl: freezed == coverPhotoUrl
          ? _value.coverPhotoUrl
          : coverPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      sensoryTags: null == sensoryTags
          ? _value._sensoryTags
          : sensoryTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      taggedUserIds: null == taggedUserIds
          ? _value._taggedUserIds
          : taggedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      photoUrls: null == photoUrls
          ? _value._photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      visitedAt: null == visitedAt
          ? _value.visitedAt
          : visitedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      likeCount: null == likeCount
          ? _value.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentCount: null == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int,
      photoCount: null == photoCount
          ? _value.photoCount
          : photoCount // ignore: cast_nullable_to_non_nullable
              as int,
      isLiked: null == isLiked
          ? _value.isLiked
          : isLiked // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaved: null == isSaved
          ? _value.isSaved
          : isSaved // ignore: cast_nullable_to_non_nullable
              as bool,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$StampImpl implements _Stamp {
  const _$StampImpl(
      {required this.id,
      required this.userId,
      required this.placeName,
      this.normalizedPlaceName,
      required this.lat,
      required this.lng,
      this.externalPlaceId,
      this.externalSource,
      this.checkInId,
      required this.visibility,
      this.coverPhotoUrl,
      this.caption,
      final List<String> sensoryTags = const [],
      final List<String> taggedUserIds = const [],
      final List<String> photoUrls = const [],
      required this.visitedAt,
      this.likeCount = 0,
      this.commentCount = 0,
      this.photoCount = 0,
      this.isLiked = false,
      this.isSaved = false,
      this.username,
      this.avatarUrl,
      this.createdAt,
      this.updatedAt})
      : _sensoryTags = sensoryTags,
        _taggedUserIds = taggedUserIds,
        _photoUrls = photoUrls;

  factory _$StampImpl.fromJson(Map<String, dynamic> json) =>
      _$$StampImplFromJson(json);

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
  final String? checkInId;
  @override
  final StampVisibility visibility;
  @override
  final String? coverPhotoUrl;
  @override
  final String? caption;
  final List<String> _sensoryTags;
  @override
  @JsonKey()
  List<String> get sensoryTags {
    if (_sensoryTags is EqualUnmodifiableListView) return _sensoryTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sensoryTags);
  }

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
  final DateTime visitedAt;
  @override
  @JsonKey()
  final int likeCount;
  @override
  @JsonKey()
  final int commentCount;
  @override
  @JsonKey()
  final int photoCount;
  @override
  @JsonKey()
  final bool isLiked;
  @override
  @JsonKey()
  final bool isSaved;
// Populated when fetched from v_feed_stamps view
  @override
  final String? username;
  @override
  final String? avatarUrl;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Stamp(id: $id, userId: $userId, placeName: $placeName, normalizedPlaceName: $normalizedPlaceName, lat: $lat, lng: $lng, externalPlaceId: $externalPlaceId, externalSource: $externalSource, checkInId: $checkInId, visibility: $visibility, coverPhotoUrl: $coverPhotoUrl, caption: $caption, sensoryTags: $sensoryTags, taggedUserIds: $taggedUserIds, photoUrls: $photoUrls, visitedAt: $visitedAt, likeCount: $likeCount, commentCount: $commentCount, photoCount: $photoCount, isLiked: $isLiked, isSaved: $isSaved, username: $username, avatarUrl: $avatarUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StampImpl &&
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
            (identical(other.checkInId, checkInId) ||
                other.checkInId == checkInId) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.coverPhotoUrl, coverPhotoUrl) ||
                other.coverPhotoUrl == coverPhotoUrl) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            const DeepCollectionEquality()
                .equals(other._sensoryTags, _sensoryTags) &&
            const DeepCollectionEquality()
                .equals(other._taggedUserIds, _taggedUserIds) &&
            const DeepCollectionEquality()
                .equals(other._photoUrls, _photoUrls) &&
            (identical(other.visitedAt, visitedAt) ||
                other.visitedAt == visitedAt) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.photoCount, photoCount) ||
                other.photoCount == photoCount) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked) &&
            (identical(other.isSaved, isSaved) || other.isSaved == isSaved) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        userId,
        placeName,
        normalizedPlaceName,
        lat,
        lng,
        externalPlaceId,
        externalSource,
        checkInId,
        visibility,
        coverPhotoUrl,
        caption,
        const DeepCollectionEquality().hash(_sensoryTags),
        const DeepCollectionEquality().hash(_taggedUserIds),
        const DeepCollectionEquality().hash(_photoUrls),
        visitedAt,
        likeCount,
        commentCount,
        photoCount,
        isLiked,
        isSaved,
        username,
        avatarUrl,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of Stamp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StampImplCopyWith<_$StampImpl> get copyWith =>
      __$$StampImplCopyWithImpl<_$StampImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StampImplToJson(
      this,
    );
  }
}

abstract class _Stamp implements Stamp {
  const factory _Stamp(
      {required final String id,
      required final String userId,
      required final String placeName,
      final String? normalizedPlaceName,
      required final double lat,
      required final double lng,
      final String? externalPlaceId,
      final String? externalSource,
      final String? checkInId,
      required final StampVisibility visibility,
      final String? coverPhotoUrl,
      final String? caption,
      final List<String> sensoryTags,
      final List<String> taggedUserIds,
      final List<String> photoUrls,
      required final DateTime visitedAt,
      final int likeCount,
      final int commentCount,
      final int photoCount,
      final bool isLiked,
      final bool isSaved,
      final String? username,
      final String? avatarUrl,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$StampImpl;

  factory _Stamp.fromJson(Map<String, dynamic> json) = _$StampImpl.fromJson;

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
  String? get checkInId;
  @override
  StampVisibility get visibility;
  @override
  String? get coverPhotoUrl;
  @override
  String? get caption;
  @override
  List<String> get sensoryTags;
  @override
  List<String> get taggedUserIds;
  @override
  List<String> get photoUrls;
  @override
  DateTime get visitedAt;
  @override
  int get likeCount;
  @override
  int get commentCount;
  @override
  int get photoCount;
  @override
  bool get isLiked;
  @override
  bool get isSaved; // Populated when fetched from v_feed_stamps view
  @override
  String? get username;
  @override
  String? get avatarUrl;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Stamp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StampImplCopyWith<_$StampImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StampDraft _$StampDraftFromJson(Map<String, dynamic> json) {
  return _StampDraft.fromJson(json);
}

/// @nodoc
mixin _$StampDraft {
  String? get existingStampId => throw _privateConstructorUsedError;
  String? get checkInId => throw _privateConstructorUsedError;
  String get placeName => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  String? get externalPlaceId => throw _privateConstructorUsedError;
  String? get externalSource => throw _privateConstructorUsedError;
  StampVisibility get visibility => throw _privateConstructorUsedError;
  String? get caption => throw _privateConstructorUsedError;
  List<String> get sensoryTags => throw _privateConstructorUsedError;
  List<String> get taggedUserIds => throw _privateConstructorUsedError;
  List<String> get selectedPhotoPaths => throw _privateConstructorUsedError;
  String? get coverPhotoPath => throw _privateConstructorUsedError;

  /// Serializes this StampDraft to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StampDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StampDraftCopyWith<StampDraft> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StampDraftCopyWith<$Res> {
  factory $StampDraftCopyWith(
          StampDraft value, $Res Function(StampDraft) then) =
      _$StampDraftCopyWithImpl<$Res, StampDraft>;
  @useResult
  $Res call(
      {String? existingStampId,
      String? checkInId,
      String placeName,
      double lat,
      double lng,
      String? externalPlaceId,
      String? externalSource,
      StampVisibility visibility,
      String? caption,
      List<String> sensoryTags,
      List<String> taggedUserIds,
      List<String> selectedPhotoPaths,
      String? coverPhotoPath});
}

/// @nodoc
class _$StampDraftCopyWithImpl<$Res, $Val extends StampDraft>
    implements $StampDraftCopyWith<$Res> {
  _$StampDraftCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StampDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? existingStampId = freezed,
    Object? checkInId = freezed,
    Object? placeName = null,
    Object? lat = null,
    Object? lng = null,
    Object? externalPlaceId = freezed,
    Object? externalSource = freezed,
    Object? visibility = null,
    Object? caption = freezed,
    Object? sensoryTags = null,
    Object? taggedUserIds = null,
    Object? selectedPhotoPaths = null,
    Object? coverPhotoPath = freezed,
  }) {
    return _then(_value.copyWith(
      existingStampId: freezed == existingStampId
          ? _value.existingStampId
          : existingStampId // ignore: cast_nullable_to_non_nullable
              as String?,
      checkInId: freezed == checkInId
          ? _value.checkInId
          : checkInId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as StampVisibility,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      sensoryTags: null == sensoryTags
          ? _value.sensoryTags
          : sensoryTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      taggedUserIds: null == taggedUserIds
          ? _value.taggedUserIds
          : taggedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      selectedPhotoPaths: null == selectedPhotoPaths
          ? _value.selectedPhotoPaths
          : selectedPhotoPaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
      coverPhotoPath: freezed == coverPhotoPath
          ? _value.coverPhotoPath
          : coverPhotoPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StampDraftImplCopyWith<$Res>
    implements $StampDraftCopyWith<$Res> {
  factory _$$StampDraftImplCopyWith(
          _$StampDraftImpl value, $Res Function(_$StampDraftImpl) then) =
      __$$StampDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? existingStampId,
      String? checkInId,
      String placeName,
      double lat,
      double lng,
      String? externalPlaceId,
      String? externalSource,
      StampVisibility visibility,
      String? caption,
      List<String> sensoryTags,
      List<String> taggedUserIds,
      List<String> selectedPhotoPaths,
      String? coverPhotoPath});
}

/// @nodoc
class __$$StampDraftImplCopyWithImpl<$Res>
    extends _$StampDraftCopyWithImpl<$Res, _$StampDraftImpl>
    implements _$$StampDraftImplCopyWith<$Res> {
  __$$StampDraftImplCopyWithImpl(
      _$StampDraftImpl _value, $Res Function(_$StampDraftImpl) _then)
      : super(_value, _then);

  /// Create a copy of StampDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? existingStampId = freezed,
    Object? checkInId = freezed,
    Object? placeName = null,
    Object? lat = null,
    Object? lng = null,
    Object? externalPlaceId = freezed,
    Object? externalSource = freezed,
    Object? visibility = null,
    Object? caption = freezed,
    Object? sensoryTags = null,
    Object? taggedUserIds = null,
    Object? selectedPhotoPaths = null,
    Object? coverPhotoPath = freezed,
  }) {
    return _then(_$StampDraftImpl(
      existingStampId: freezed == existingStampId
          ? _value.existingStampId
          : existingStampId // ignore: cast_nullable_to_non_nullable
              as String?,
      checkInId: freezed == checkInId
          ? _value.checkInId
          : checkInId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as StampVisibility,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      sensoryTags: null == sensoryTags
          ? _value._sensoryTags
          : sensoryTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      taggedUserIds: null == taggedUserIds
          ? _value._taggedUserIds
          : taggedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      selectedPhotoPaths: null == selectedPhotoPaths
          ? _value._selectedPhotoPaths
          : selectedPhotoPaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
      coverPhotoPath: freezed == coverPhotoPath
          ? _value.coverPhotoPath
          : coverPhotoPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StampDraftImpl implements _StampDraft {
  const _$StampDraftImpl(
      {this.existingStampId,
      this.checkInId,
      required this.placeName,
      required this.lat,
      required this.lng,
      this.externalPlaceId,
      this.externalSource,
      this.visibility = StampVisibility.private,
      this.caption,
      final List<String> sensoryTags = const [],
      final List<String> taggedUserIds = const [],
      final List<String> selectedPhotoPaths = const [],
      this.coverPhotoPath})
      : _sensoryTags = sensoryTags,
        _taggedUserIds = taggedUserIds,
        _selectedPhotoPaths = selectedPhotoPaths;

  factory _$StampDraftImpl.fromJson(Map<String, dynamic> json) =>
      _$$StampDraftImplFromJson(json);

  @override
  final String? existingStampId;
  @override
  final String? checkInId;
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
  @JsonKey()
  final StampVisibility visibility;
  @override
  final String? caption;
  final List<String> _sensoryTags;
  @override
  @JsonKey()
  List<String> get sensoryTags {
    if (_sensoryTags is EqualUnmodifiableListView) return _sensoryTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sensoryTags);
  }

  final List<String> _taggedUserIds;
  @override
  @JsonKey()
  List<String> get taggedUserIds {
    if (_taggedUserIds is EqualUnmodifiableListView) return _taggedUserIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_taggedUserIds);
  }

  final List<String> _selectedPhotoPaths;
  @override
  @JsonKey()
  List<String> get selectedPhotoPaths {
    if (_selectedPhotoPaths is EqualUnmodifiableListView)
      return _selectedPhotoPaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedPhotoPaths);
  }

  @override
  final String? coverPhotoPath;

  @override
  String toString() {
    return 'StampDraft(existingStampId: $existingStampId, checkInId: $checkInId, placeName: $placeName, lat: $lat, lng: $lng, externalPlaceId: $externalPlaceId, externalSource: $externalSource, visibility: $visibility, caption: $caption, sensoryTags: $sensoryTags, taggedUserIds: $taggedUserIds, selectedPhotoPaths: $selectedPhotoPaths, coverPhotoPath: $coverPhotoPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StampDraftImpl &&
            (identical(other.existingStampId, existingStampId) ||
                other.existingStampId == existingStampId) &&
            (identical(other.checkInId, checkInId) ||
                other.checkInId == checkInId) &&
            (identical(other.placeName, placeName) ||
                other.placeName == placeName) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.externalPlaceId, externalPlaceId) ||
                other.externalPlaceId == externalPlaceId) &&
            (identical(other.externalSource, externalSource) ||
                other.externalSource == externalSource) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            const DeepCollectionEquality()
                .equals(other._sensoryTags, _sensoryTags) &&
            const DeepCollectionEquality()
                .equals(other._taggedUserIds, _taggedUserIds) &&
            const DeepCollectionEquality()
                .equals(other._selectedPhotoPaths, _selectedPhotoPaths) &&
            (identical(other.coverPhotoPath, coverPhotoPath) ||
                other.coverPhotoPath == coverPhotoPath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      existingStampId,
      checkInId,
      placeName,
      lat,
      lng,
      externalPlaceId,
      externalSource,
      visibility,
      caption,
      const DeepCollectionEquality().hash(_sensoryTags),
      const DeepCollectionEquality().hash(_taggedUserIds),
      const DeepCollectionEquality().hash(_selectedPhotoPaths),
      coverPhotoPath);

  /// Create a copy of StampDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StampDraftImplCopyWith<_$StampDraftImpl> get copyWith =>
      __$$StampDraftImplCopyWithImpl<_$StampDraftImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StampDraftImplToJson(
      this,
    );
  }
}

abstract class _StampDraft implements StampDraft {
  const factory _StampDraft(
      {final String? existingStampId,
      final String? checkInId,
      required final String placeName,
      required final double lat,
      required final double lng,
      final String? externalPlaceId,
      final String? externalSource,
      final StampVisibility visibility,
      final String? caption,
      final List<String> sensoryTags,
      final List<String> taggedUserIds,
      final List<String> selectedPhotoPaths,
      final String? coverPhotoPath}) = _$StampDraftImpl;

  factory _StampDraft.fromJson(Map<String, dynamic> json) =
      _$StampDraftImpl.fromJson;

  @override
  String? get existingStampId;
  @override
  String? get checkInId;
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
  StampVisibility get visibility;
  @override
  String? get caption;
  @override
  List<String> get sensoryTags;
  @override
  List<String> get taggedUserIds;
  @override
  List<String> get selectedPhotoPaths;
  @override
  String? get coverPhotoPath;

  /// Create a copy of StampDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StampDraftImplCopyWith<_$StampDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
