// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkin_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ExternalPlace {
  String get externalPlaceId => throw _privateConstructorUsedError;
  String get externalSource => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;

  /// Create a copy of ExternalPlace
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExternalPlaceCopyWith<ExternalPlace> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExternalPlaceCopyWith<$Res> {
  factory $ExternalPlaceCopyWith(
          ExternalPlace value, $Res Function(ExternalPlace) then) =
      _$ExternalPlaceCopyWithImpl<$Res, ExternalPlace>;
  @useResult
  $Res call(
      {String externalPlaceId,
      String externalSource,
      String name,
      double lat,
      double lng,
      String? address,
      String? category});
}

/// @nodoc
class _$ExternalPlaceCopyWithImpl<$Res, $Val extends ExternalPlace>
    implements $ExternalPlaceCopyWith<$Res> {
  _$ExternalPlaceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExternalPlace
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? externalPlaceId = null,
    Object? externalSource = null,
    Object? name = null,
    Object? lat = null,
    Object? lng = null,
    Object? address = freezed,
    Object? category = freezed,
  }) {
    return _then(_value.copyWith(
      externalPlaceId: null == externalPlaceId
          ? _value.externalPlaceId
          : externalPlaceId // ignore: cast_nullable_to_non_nullable
              as String,
      externalSource: null == externalSource
          ? _value.externalSource
          : externalSource // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExternalPlaceImplCopyWith<$Res>
    implements $ExternalPlaceCopyWith<$Res> {
  factory _$$ExternalPlaceImplCopyWith(
          _$ExternalPlaceImpl value, $Res Function(_$ExternalPlaceImpl) then) =
      __$$ExternalPlaceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String externalPlaceId,
      String externalSource,
      String name,
      double lat,
      double lng,
      String? address,
      String? category});
}

/// @nodoc
class __$$ExternalPlaceImplCopyWithImpl<$Res>
    extends _$ExternalPlaceCopyWithImpl<$Res, _$ExternalPlaceImpl>
    implements _$$ExternalPlaceImplCopyWith<$Res> {
  __$$ExternalPlaceImplCopyWithImpl(
      _$ExternalPlaceImpl _value, $Res Function(_$ExternalPlaceImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExternalPlace
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? externalPlaceId = null,
    Object? externalSource = null,
    Object? name = null,
    Object? lat = null,
    Object? lng = null,
    Object? address = freezed,
    Object? category = freezed,
  }) {
    return _then(_$ExternalPlaceImpl(
      externalPlaceId: null == externalPlaceId
          ? _value.externalPlaceId
          : externalPlaceId // ignore: cast_nullable_to_non_nullable
              as String,
      externalSource: null == externalSource
          ? _value.externalSource
          : externalSource // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ExternalPlaceImpl
    with DiagnosticableTreeMixin
    implements _ExternalPlace {
  const _$ExternalPlaceImpl(
      {required this.externalPlaceId,
      required this.externalSource,
      required this.name,
      required this.lat,
      required this.lng,
      this.address,
      this.category});

  @override
  final String externalPlaceId;
  @override
  final String externalSource;
  @override
  final String name;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final String? address;
  @override
  final String? category;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ExternalPlace(externalPlaceId: $externalPlaceId, externalSource: $externalSource, name: $name, lat: $lat, lng: $lng, address: $address, category: $category)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ExternalPlace'))
      ..add(DiagnosticsProperty('externalPlaceId', externalPlaceId))
      ..add(DiagnosticsProperty('externalSource', externalSource))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('lat', lat))
      ..add(DiagnosticsProperty('lng', lng))
      ..add(DiagnosticsProperty('address', address))
      ..add(DiagnosticsProperty('category', category));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExternalPlaceImpl &&
            (identical(other.externalPlaceId, externalPlaceId) ||
                other.externalPlaceId == externalPlaceId) &&
            (identical(other.externalSource, externalSource) ||
                other.externalSource == externalSource) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @override
  int get hashCode => Object.hash(runtimeType, externalPlaceId, externalSource,
      name, lat, lng, address, category);

  /// Create a copy of ExternalPlace
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExternalPlaceImplCopyWith<_$ExternalPlaceImpl> get copyWith =>
      __$$ExternalPlaceImplCopyWithImpl<_$ExternalPlaceImpl>(this, _$identity);
}

abstract class _ExternalPlace implements ExternalPlace {
  const factory _ExternalPlace(
      {required final String externalPlaceId,
      required final String externalSource,
      required final String name,
      required final double lat,
      required final double lng,
      final String? address,
      final String? category}) = _$ExternalPlaceImpl;

  @override
  String get externalPlaceId;
  @override
  String get externalSource;
  @override
  String get name;
  @override
  double get lat;
  @override
  double get lng;
  @override
  String? get address;
  @override
  String? get category;

  /// Create a copy of ExternalPlace
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExternalPlaceImplCopyWith<_$ExternalPlaceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CheckinState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() locating,
    required TResult Function(double lat, double lng, List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace, List<ExternalPlace> placeSuggestions)
        placeSelected,
    required TResult Function(CheckInDraft draft) editingCheckIn,
    required TResult Function(StampDraft draft) editingStamp,
    required TResult Function() saving,
    required TResult Function(CheckIn checkIn) completeCheckIn,
    required TResult Function(String stampId) completeStamp,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? locating,
    TResult? Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult? Function(CheckInDraft draft)? editingCheckIn,
    TResult? Function(StampDraft draft)? editingStamp,
    TResult? Function()? saving,
    TResult? Function(CheckIn checkIn)? completeCheckIn,
    TResult? Function(String stampId)? completeStamp,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? locating,
    TResult Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult Function(CheckInDraft draft)? editingCheckIn,
    TResult Function(StampDraft draft)? editingStamp,
    TResult Function()? saving,
    TResult Function(CheckIn checkIn)? completeCheckIn,
    TResult Function(String stampId)? completeStamp,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Locating value) locating,
    required TResult Function(_PlaceSelected value) placeSelected,
    required TResult Function(_EditingCheckIn value) editingCheckIn,
    required TResult Function(_EditingStamp value) editingStamp,
    required TResult Function(_Saving value) saving,
    required TResult Function(_CompleteCheckIn value) completeCheckIn,
    required TResult Function(_CompleteStamp value) completeStamp,
    required TResult Function(_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Locating value)? locating,
    TResult? Function(_PlaceSelected value)? placeSelected,
    TResult? Function(_EditingCheckIn value)? editingCheckIn,
    TResult? Function(_EditingStamp value)? editingStamp,
    TResult? Function(_Saving value)? saving,
    TResult? Function(_CompleteCheckIn value)? completeCheckIn,
    TResult? Function(_CompleteStamp value)? completeStamp,
    TResult? Function(_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Locating value)? locating,
    TResult Function(_PlaceSelected value)? placeSelected,
    TResult Function(_EditingCheckIn value)? editingCheckIn,
    TResult Function(_EditingStamp value)? editingStamp,
    TResult Function(_Saving value)? saving,
    TResult Function(_CompleteCheckIn value)? completeCheckIn,
    TResult Function(_CompleteStamp value)? completeStamp,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckinStateCopyWith<$Res> {
  factory $CheckinStateCopyWith(
          CheckinState value, $Res Function(CheckinState) then) =
      _$CheckinStateCopyWithImpl<$Res, CheckinState>;
}

/// @nodoc
class _$CheckinStateCopyWithImpl<$Res, $Val extends CheckinState>
    implements $CheckinStateCopyWith<$Res> {
  _$CheckinStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$IdleImplCopyWith<$Res> {
  factory _$$IdleImplCopyWith(
          _$IdleImpl value, $Res Function(_$IdleImpl) then) =
      __$$IdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$IdleImplCopyWithImpl<$Res>
    extends _$CheckinStateCopyWithImpl<$Res, _$IdleImpl>
    implements _$$IdleImplCopyWith<$Res> {
  __$$IdleImplCopyWithImpl(_$IdleImpl _value, $Res Function(_$IdleImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$IdleImpl with DiagnosticableTreeMixin implements _Idle {
  const _$IdleImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CheckinState.idle()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('type', 'CheckinState.idle'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$IdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() locating,
    required TResult Function(double lat, double lng, List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace, List<ExternalPlace> placeSuggestions)
        placeSelected,
    required TResult Function(CheckInDraft draft) editingCheckIn,
    required TResult Function(StampDraft draft) editingStamp,
    required TResult Function() saving,
    required TResult Function(CheckIn checkIn) completeCheckIn,
    required TResult Function(String stampId) completeStamp,
    required TResult Function(String message) error,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? locating,
    TResult? Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult? Function(CheckInDraft draft)? editingCheckIn,
    TResult? Function(StampDraft draft)? editingStamp,
    TResult? Function()? saving,
    TResult? Function(CheckIn checkIn)? completeCheckIn,
    TResult? Function(String stampId)? completeStamp,
    TResult? Function(String message)? error,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? locating,
    TResult Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult Function(CheckInDraft draft)? editingCheckIn,
    TResult Function(StampDraft draft)? editingStamp,
    TResult Function()? saving,
    TResult Function(CheckIn checkIn)? completeCheckIn,
    TResult Function(String stampId)? completeStamp,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Locating value) locating,
    required TResult Function(_PlaceSelected value) placeSelected,
    required TResult Function(_EditingCheckIn value) editingCheckIn,
    required TResult Function(_EditingStamp value) editingStamp,
    required TResult Function(_Saving value) saving,
    required TResult Function(_CompleteCheckIn value) completeCheckIn,
    required TResult Function(_CompleteStamp value) completeStamp,
    required TResult Function(_Error value) error,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Locating value)? locating,
    TResult? Function(_PlaceSelected value)? placeSelected,
    TResult? Function(_EditingCheckIn value)? editingCheckIn,
    TResult? Function(_EditingStamp value)? editingStamp,
    TResult? Function(_Saving value)? saving,
    TResult? Function(_CompleteCheckIn value)? completeCheckIn,
    TResult? Function(_CompleteStamp value)? completeStamp,
    TResult? Function(_Error value)? error,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Locating value)? locating,
    TResult Function(_PlaceSelected value)? placeSelected,
    TResult Function(_EditingCheckIn value)? editingCheckIn,
    TResult Function(_EditingStamp value)? editingStamp,
    TResult Function(_Saving value)? saving,
    TResult Function(_CompleteCheckIn value)? completeCheckIn,
    TResult Function(_CompleteStamp value)? completeStamp,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class _Idle implements CheckinState {
  const factory _Idle() = _$IdleImpl;
}

/// @nodoc
abstract class _$$LocatingImplCopyWith<$Res> {
  factory _$$LocatingImplCopyWith(
          _$LocatingImpl value, $Res Function(_$LocatingImpl) then) =
      __$$LocatingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LocatingImplCopyWithImpl<$Res>
    extends _$CheckinStateCopyWithImpl<$Res, _$LocatingImpl>
    implements _$$LocatingImplCopyWith<$Res> {
  __$$LocatingImplCopyWithImpl(
      _$LocatingImpl _value, $Res Function(_$LocatingImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LocatingImpl with DiagnosticableTreeMixin implements _Locating {
  const _$LocatingImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CheckinState.locating()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('type', 'CheckinState.locating'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LocatingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() locating,
    required TResult Function(double lat, double lng, List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace, List<ExternalPlace> placeSuggestions)
        placeSelected,
    required TResult Function(CheckInDraft draft) editingCheckIn,
    required TResult Function(StampDraft draft) editingStamp,
    required TResult Function() saving,
    required TResult Function(CheckIn checkIn) completeCheckIn,
    required TResult Function(String stampId) completeStamp,
    required TResult Function(String message) error,
  }) {
    return locating();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? locating,
    TResult? Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult? Function(CheckInDraft draft)? editingCheckIn,
    TResult? Function(StampDraft draft)? editingStamp,
    TResult? Function()? saving,
    TResult? Function(CheckIn checkIn)? completeCheckIn,
    TResult? Function(String stampId)? completeStamp,
    TResult? Function(String message)? error,
  }) {
    return locating?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? locating,
    TResult Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult Function(CheckInDraft draft)? editingCheckIn,
    TResult Function(StampDraft draft)? editingStamp,
    TResult Function()? saving,
    TResult Function(CheckIn checkIn)? completeCheckIn,
    TResult Function(String stampId)? completeStamp,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (locating != null) {
      return locating();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Locating value) locating,
    required TResult Function(_PlaceSelected value) placeSelected,
    required TResult Function(_EditingCheckIn value) editingCheckIn,
    required TResult Function(_EditingStamp value) editingStamp,
    required TResult Function(_Saving value) saving,
    required TResult Function(_CompleteCheckIn value) completeCheckIn,
    required TResult Function(_CompleteStamp value) completeStamp,
    required TResult Function(_Error value) error,
  }) {
    return locating(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Locating value)? locating,
    TResult? Function(_PlaceSelected value)? placeSelected,
    TResult? Function(_EditingCheckIn value)? editingCheckIn,
    TResult? Function(_EditingStamp value)? editingStamp,
    TResult? Function(_Saving value)? saving,
    TResult? Function(_CompleteCheckIn value)? completeCheckIn,
    TResult? Function(_CompleteStamp value)? completeStamp,
    TResult? Function(_Error value)? error,
  }) {
    return locating?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Locating value)? locating,
    TResult Function(_PlaceSelected value)? placeSelected,
    TResult Function(_EditingCheckIn value)? editingCheckIn,
    TResult Function(_EditingStamp value)? editingStamp,
    TResult Function(_Saving value)? saving,
    TResult Function(_CompleteCheckIn value)? completeCheckIn,
    TResult Function(_CompleteStamp value)? completeStamp,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (locating != null) {
      return locating(this);
    }
    return orElse();
  }
}

abstract class _Locating implements CheckinState {
  const factory _Locating() = _$LocatingImpl;
}

/// @nodoc
abstract class _$$PlaceSelectedImplCopyWith<$Res> {
  factory _$$PlaceSelectedImplCopyWith(
          _$PlaceSelectedImpl value, $Res Function(_$PlaceSelectedImpl) then) =
      __$$PlaceSelectedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {double lat,
      double lng,
      List<Stamp> nearbyStamps,
      ExternalPlace? suggestedPlace,
      List<ExternalPlace> placeSuggestions});

  $ExternalPlaceCopyWith<$Res>? get suggestedPlace;
}

/// @nodoc
class __$$PlaceSelectedImplCopyWithImpl<$Res>
    extends _$CheckinStateCopyWithImpl<$Res, _$PlaceSelectedImpl>
    implements _$$PlaceSelectedImplCopyWith<$Res> {
  __$$PlaceSelectedImplCopyWithImpl(
      _$PlaceSelectedImpl _value, $Res Function(_$PlaceSelectedImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
    Object? nearbyStamps = null,
    Object? suggestedPlace = freezed,
    Object? placeSuggestions = null,
  }) {
    return _then(_$PlaceSelectedImpl(
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      nearbyStamps: null == nearbyStamps
          ? _value._nearbyStamps
          : nearbyStamps // ignore: cast_nullable_to_non_nullable
              as List<Stamp>,
      suggestedPlace: freezed == suggestedPlace
          ? _value.suggestedPlace
          : suggestedPlace // ignore: cast_nullable_to_non_nullable
              as ExternalPlace?,
      placeSuggestions: null == placeSuggestions
          ? _value._placeSuggestions
          : placeSuggestions // ignore: cast_nullable_to_non_nullable
              as List<ExternalPlace>,
    ));
  }

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExternalPlaceCopyWith<$Res>? get suggestedPlace {
    if (_value.suggestedPlace == null) {
      return null;
    }

    return $ExternalPlaceCopyWith<$Res>(_value.suggestedPlace!, (value) {
      return _then(_value.copyWith(suggestedPlace: value));
    });
  }
}

/// @nodoc

class _$PlaceSelectedImpl
    with DiagnosticableTreeMixin
    implements _PlaceSelected {
  const _$PlaceSelectedImpl(
      {required this.lat,
      required this.lng,
      required final List<Stamp> nearbyStamps,
      this.suggestedPlace,
      final List<ExternalPlace> placeSuggestions = const []})
      : _nearbyStamps = nearbyStamps,
        _placeSuggestions = placeSuggestions;

  @override
  final double lat;
  @override
  final double lng;
  final List<Stamp> _nearbyStamps;
  @override
  List<Stamp> get nearbyStamps {
    if (_nearbyStamps is EqualUnmodifiableListView) return _nearbyStamps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nearbyStamps);
  }

  @override
  final ExternalPlace? suggestedPlace;
  final List<ExternalPlace> _placeSuggestions;
  @override
  @JsonKey()
  List<ExternalPlace> get placeSuggestions {
    if (_placeSuggestions is EqualUnmodifiableListView)
      return _placeSuggestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_placeSuggestions);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CheckinState.placeSelected(lat: $lat, lng: $lng, nearbyStamps: $nearbyStamps, suggestedPlace: $suggestedPlace, placeSuggestions: $placeSuggestions)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CheckinState.placeSelected'))
      ..add(DiagnosticsProperty('lat', lat))
      ..add(DiagnosticsProperty('lng', lng))
      ..add(DiagnosticsProperty('nearbyStamps', nearbyStamps))
      ..add(DiagnosticsProperty('suggestedPlace', suggestedPlace))
      ..add(DiagnosticsProperty('placeSuggestions', placeSuggestions));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaceSelectedImpl &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            const DeepCollectionEquality()
                .equals(other._nearbyStamps, _nearbyStamps) &&
            (identical(other.suggestedPlace, suggestedPlace) ||
                other.suggestedPlace == suggestedPlace) &&
            const DeepCollectionEquality()
                .equals(other._placeSuggestions, _placeSuggestions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      lat,
      lng,
      const DeepCollectionEquality().hash(_nearbyStamps),
      suggestedPlace,
      const DeepCollectionEquality().hash(_placeSuggestions));

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaceSelectedImplCopyWith<_$PlaceSelectedImpl> get copyWith =>
      __$$PlaceSelectedImplCopyWithImpl<_$PlaceSelectedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() locating,
    required TResult Function(double lat, double lng, List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace, List<ExternalPlace> placeSuggestions)
        placeSelected,
    required TResult Function(CheckInDraft draft) editingCheckIn,
    required TResult Function(StampDraft draft) editingStamp,
    required TResult Function() saving,
    required TResult Function(CheckIn checkIn) completeCheckIn,
    required TResult Function(String stampId) completeStamp,
    required TResult Function(String message) error,
  }) {
    return placeSelected(
        lat, lng, nearbyStamps, suggestedPlace, placeSuggestions);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? locating,
    TResult? Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult? Function(CheckInDraft draft)? editingCheckIn,
    TResult? Function(StampDraft draft)? editingStamp,
    TResult? Function()? saving,
    TResult? Function(CheckIn checkIn)? completeCheckIn,
    TResult? Function(String stampId)? completeStamp,
    TResult? Function(String message)? error,
  }) {
    return placeSelected?.call(
        lat, lng, nearbyStamps, suggestedPlace, placeSuggestions);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? locating,
    TResult Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult Function(CheckInDraft draft)? editingCheckIn,
    TResult Function(StampDraft draft)? editingStamp,
    TResult Function()? saving,
    TResult Function(CheckIn checkIn)? completeCheckIn,
    TResult Function(String stampId)? completeStamp,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (placeSelected != null) {
      return placeSelected(
          lat, lng, nearbyStamps, suggestedPlace, placeSuggestions);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Locating value) locating,
    required TResult Function(_PlaceSelected value) placeSelected,
    required TResult Function(_EditingCheckIn value) editingCheckIn,
    required TResult Function(_EditingStamp value) editingStamp,
    required TResult Function(_Saving value) saving,
    required TResult Function(_CompleteCheckIn value) completeCheckIn,
    required TResult Function(_CompleteStamp value) completeStamp,
    required TResult Function(_Error value) error,
  }) {
    return placeSelected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Locating value)? locating,
    TResult? Function(_PlaceSelected value)? placeSelected,
    TResult? Function(_EditingCheckIn value)? editingCheckIn,
    TResult? Function(_EditingStamp value)? editingStamp,
    TResult? Function(_Saving value)? saving,
    TResult? Function(_CompleteCheckIn value)? completeCheckIn,
    TResult? Function(_CompleteStamp value)? completeStamp,
    TResult? Function(_Error value)? error,
  }) {
    return placeSelected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Locating value)? locating,
    TResult Function(_PlaceSelected value)? placeSelected,
    TResult Function(_EditingCheckIn value)? editingCheckIn,
    TResult Function(_EditingStamp value)? editingStamp,
    TResult Function(_Saving value)? saving,
    TResult Function(_CompleteCheckIn value)? completeCheckIn,
    TResult Function(_CompleteStamp value)? completeStamp,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (placeSelected != null) {
      return placeSelected(this);
    }
    return orElse();
  }
}

abstract class _PlaceSelected implements CheckinState {
  const factory _PlaceSelected(
      {required final double lat,
      required final double lng,
      required final List<Stamp> nearbyStamps,
      final ExternalPlace? suggestedPlace,
      final List<ExternalPlace> placeSuggestions}) = _$PlaceSelectedImpl;

  double get lat;
  double get lng;
  List<Stamp> get nearbyStamps;
  ExternalPlace? get suggestedPlace;
  List<ExternalPlace> get placeSuggestions;

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaceSelectedImplCopyWith<_$PlaceSelectedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EditingCheckInImplCopyWith<$Res> {
  factory _$$EditingCheckInImplCopyWith(_$EditingCheckInImpl value,
          $Res Function(_$EditingCheckInImpl) then) =
      __$$EditingCheckInImplCopyWithImpl<$Res>;
  @useResult
  $Res call({CheckInDraft draft});

  $CheckInDraftCopyWith<$Res> get draft;
}

/// @nodoc
class __$$EditingCheckInImplCopyWithImpl<$Res>
    extends _$CheckinStateCopyWithImpl<$Res, _$EditingCheckInImpl>
    implements _$$EditingCheckInImplCopyWith<$Res> {
  __$$EditingCheckInImplCopyWithImpl(
      _$EditingCheckInImpl _value, $Res Function(_$EditingCheckInImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? draft = null,
  }) {
    return _then(_$EditingCheckInImpl(
      draft: null == draft
          ? _value.draft
          : draft // ignore: cast_nullable_to_non_nullable
              as CheckInDraft,
    ));
  }

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CheckInDraftCopyWith<$Res> get draft {
    return $CheckInDraftCopyWith<$Res>(_value.draft, (value) {
      return _then(_value.copyWith(draft: value));
    });
  }
}

/// @nodoc

class _$EditingCheckInImpl
    with DiagnosticableTreeMixin
    implements _EditingCheckIn {
  const _$EditingCheckInImpl({required this.draft});

  @override
  final CheckInDraft draft;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CheckinState.editingCheckIn(draft: $draft)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CheckinState.editingCheckIn'))
      ..add(DiagnosticsProperty('draft', draft));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditingCheckInImpl &&
            (identical(other.draft, draft) || other.draft == draft));
  }

  @override
  int get hashCode => Object.hash(runtimeType, draft);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditingCheckInImplCopyWith<_$EditingCheckInImpl> get copyWith =>
      __$$EditingCheckInImplCopyWithImpl<_$EditingCheckInImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() locating,
    required TResult Function(double lat, double lng, List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace, List<ExternalPlace> placeSuggestions)
        placeSelected,
    required TResult Function(CheckInDraft draft) editingCheckIn,
    required TResult Function(StampDraft draft) editingStamp,
    required TResult Function() saving,
    required TResult Function(CheckIn checkIn) completeCheckIn,
    required TResult Function(String stampId) completeStamp,
    required TResult Function(String message) error,
  }) {
    return editingCheckIn(draft);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? locating,
    TResult? Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult? Function(CheckInDraft draft)? editingCheckIn,
    TResult? Function(StampDraft draft)? editingStamp,
    TResult? Function()? saving,
    TResult? Function(CheckIn checkIn)? completeCheckIn,
    TResult? Function(String stampId)? completeStamp,
    TResult? Function(String message)? error,
  }) {
    return editingCheckIn?.call(draft);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? locating,
    TResult Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult Function(CheckInDraft draft)? editingCheckIn,
    TResult Function(StampDraft draft)? editingStamp,
    TResult Function()? saving,
    TResult Function(CheckIn checkIn)? completeCheckIn,
    TResult Function(String stampId)? completeStamp,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (editingCheckIn != null) {
      return editingCheckIn(draft);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Locating value) locating,
    required TResult Function(_PlaceSelected value) placeSelected,
    required TResult Function(_EditingCheckIn value) editingCheckIn,
    required TResult Function(_EditingStamp value) editingStamp,
    required TResult Function(_Saving value) saving,
    required TResult Function(_CompleteCheckIn value) completeCheckIn,
    required TResult Function(_CompleteStamp value) completeStamp,
    required TResult Function(_Error value) error,
  }) {
    return editingCheckIn(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Locating value)? locating,
    TResult? Function(_PlaceSelected value)? placeSelected,
    TResult? Function(_EditingCheckIn value)? editingCheckIn,
    TResult? Function(_EditingStamp value)? editingStamp,
    TResult? Function(_Saving value)? saving,
    TResult? Function(_CompleteCheckIn value)? completeCheckIn,
    TResult? Function(_CompleteStamp value)? completeStamp,
    TResult? Function(_Error value)? error,
  }) {
    return editingCheckIn?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Locating value)? locating,
    TResult Function(_PlaceSelected value)? placeSelected,
    TResult Function(_EditingCheckIn value)? editingCheckIn,
    TResult Function(_EditingStamp value)? editingStamp,
    TResult Function(_Saving value)? saving,
    TResult Function(_CompleteCheckIn value)? completeCheckIn,
    TResult Function(_CompleteStamp value)? completeStamp,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (editingCheckIn != null) {
      return editingCheckIn(this);
    }
    return orElse();
  }
}

abstract class _EditingCheckIn implements CheckinState {
  const factory _EditingCheckIn({required final CheckInDraft draft}) =
      _$EditingCheckInImpl;

  CheckInDraft get draft;

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditingCheckInImplCopyWith<_$EditingCheckInImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EditingStampImplCopyWith<$Res> {
  factory _$$EditingStampImplCopyWith(
          _$EditingStampImpl value, $Res Function(_$EditingStampImpl) then) =
      __$$EditingStampImplCopyWithImpl<$Res>;
  @useResult
  $Res call({StampDraft draft});

  $StampDraftCopyWith<$Res> get draft;
}

/// @nodoc
class __$$EditingStampImplCopyWithImpl<$Res>
    extends _$CheckinStateCopyWithImpl<$Res, _$EditingStampImpl>
    implements _$$EditingStampImplCopyWith<$Res> {
  __$$EditingStampImplCopyWithImpl(
      _$EditingStampImpl _value, $Res Function(_$EditingStampImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? draft = null,
  }) {
    return _then(_$EditingStampImpl(
      draft: null == draft
          ? _value.draft
          : draft // ignore: cast_nullable_to_non_nullable
              as StampDraft,
    ));
  }

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StampDraftCopyWith<$Res> get draft {
    return $StampDraftCopyWith<$Res>(_value.draft, (value) {
      return _then(_value.copyWith(draft: value));
    });
  }
}

/// @nodoc

class _$EditingStampImpl with DiagnosticableTreeMixin implements _EditingStamp {
  const _$EditingStampImpl({required this.draft});

  @override
  final StampDraft draft;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CheckinState.editingStamp(draft: $draft)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CheckinState.editingStamp'))
      ..add(DiagnosticsProperty('draft', draft));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditingStampImpl &&
            (identical(other.draft, draft) || other.draft == draft));
  }

  @override
  int get hashCode => Object.hash(runtimeType, draft);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditingStampImplCopyWith<_$EditingStampImpl> get copyWith =>
      __$$EditingStampImplCopyWithImpl<_$EditingStampImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() locating,
    required TResult Function(double lat, double lng, List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace, List<ExternalPlace> placeSuggestions)
        placeSelected,
    required TResult Function(CheckInDraft draft) editingCheckIn,
    required TResult Function(StampDraft draft) editingStamp,
    required TResult Function() saving,
    required TResult Function(CheckIn checkIn) completeCheckIn,
    required TResult Function(String stampId) completeStamp,
    required TResult Function(String message) error,
  }) {
    return editingStamp(draft);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? locating,
    TResult? Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult? Function(CheckInDraft draft)? editingCheckIn,
    TResult? Function(StampDraft draft)? editingStamp,
    TResult? Function()? saving,
    TResult? Function(CheckIn checkIn)? completeCheckIn,
    TResult? Function(String stampId)? completeStamp,
    TResult? Function(String message)? error,
  }) {
    return editingStamp?.call(draft);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? locating,
    TResult Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult Function(CheckInDraft draft)? editingCheckIn,
    TResult Function(StampDraft draft)? editingStamp,
    TResult Function()? saving,
    TResult Function(CheckIn checkIn)? completeCheckIn,
    TResult Function(String stampId)? completeStamp,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (editingStamp != null) {
      return editingStamp(draft);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Locating value) locating,
    required TResult Function(_PlaceSelected value) placeSelected,
    required TResult Function(_EditingCheckIn value) editingCheckIn,
    required TResult Function(_EditingStamp value) editingStamp,
    required TResult Function(_Saving value) saving,
    required TResult Function(_CompleteCheckIn value) completeCheckIn,
    required TResult Function(_CompleteStamp value) completeStamp,
    required TResult Function(_Error value) error,
  }) {
    return editingStamp(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Locating value)? locating,
    TResult? Function(_PlaceSelected value)? placeSelected,
    TResult? Function(_EditingCheckIn value)? editingCheckIn,
    TResult? Function(_EditingStamp value)? editingStamp,
    TResult? Function(_Saving value)? saving,
    TResult? Function(_CompleteCheckIn value)? completeCheckIn,
    TResult? Function(_CompleteStamp value)? completeStamp,
    TResult? Function(_Error value)? error,
  }) {
    return editingStamp?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Locating value)? locating,
    TResult Function(_PlaceSelected value)? placeSelected,
    TResult Function(_EditingCheckIn value)? editingCheckIn,
    TResult Function(_EditingStamp value)? editingStamp,
    TResult Function(_Saving value)? saving,
    TResult Function(_CompleteCheckIn value)? completeCheckIn,
    TResult Function(_CompleteStamp value)? completeStamp,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (editingStamp != null) {
      return editingStamp(this);
    }
    return orElse();
  }
}

abstract class _EditingStamp implements CheckinState {
  const factory _EditingStamp({required final StampDraft draft}) =
      _$EditingStampImpl;

  StampDraft get draft;

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditingStampImplCopyWith<_$EditingStampImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SavingImplCopyWith<$Res> {
  factory _$$SavingImplCopyWith(
          _$SavingImpl value, $Res Function(_$SavingImpl) then) =
      __$$SavingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SavingImplCopyWithImpl<$Res>
    extends _$CheckinStateCopyWithImpl<$Res, _$SavingImpl>
    implements _$$SavingImplCopyWith<$Res> {
  __$$SavingImplCopyWithImpl(
      _$SavingImpl _value, $Res Function(_$SavingImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SavingImpl with DiagnosticableTreeMixin implements _Saving {
  const _$SavingImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CheckinState.saving()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('type', 'CheckinState.saving'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SavingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() locating,
    required TResult Function(double lat, double lng, List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace, List<ExternalPlace> placeSuggestions)
        placeSelected,
    required TResult Function(CheckInDraft draft) editingCheckIn,
    required TResult Function(StampDraft draft) editingStamp,
    required TResult Function() saving,
    required TResult Function(CheckIn checkIn) completeCheckIn,
    required TResult Function(String stampId) completeStamp,
    required TResult Function(String message) error,
  }) {
    return saving();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? locating,
    TResult? Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult? Function(CheckInDraft draft)? editingCheckIn,
    TResult? Function(StampDraft draft)? editingStamp,
    TResult? Function()? saving,
    TResult? Function(CheckIn checkIn)? completeCheckIn,
    TResult? Function(String stampId)? completeStamp,
    TResult? Function(String message)? error,
  }) {
    return saving?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? locating,
    TResult Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult Function(CheckInDraft draft)? editingCheckIn,
    TResult Function(StampDraft draft)? editingStamp,
    TResult Function()? saving,
    TResult Function(CheckIn checkIn)? completeCheckIn,
    TResult Function(String stampId)? completeStamp,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (saving != null) {
      return saving();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Locating value) locating,
    required TResult Function(_PlaceSelected value) placeSelected,
    required TResult Function(_EditingCheckIn value) editingCheckIn,
    required TResult Function(_EditingStamp value) editingStamp,
    required TResult Function(_Saving value) saving,
    required TResult Function(_CompleteCheckIn value) completeCheckIn,
    required TResult Function(_CompleteStamp value) completeStamp,
    required TResult Function(_Error value) error,
  }) {
    return saving(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Locating value)? locating,
    TResult? Function(_PlaceSelected value)? placeSelected,
    TResult? Function(_EditingCheckIn value)? editingCheckIn,
    TResult? Function(_EditingStamp value)? editingStamp,
    TResult? Function(_Saving value)? saving,
    TResult? Function(_CompleteCheckIn value)? completeCheckIn,
    TResult? Function(_CompleteStamp value)? completeStamp,
    TResult? Function(_Error value)? error,
  }) {
    return saving?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Locating value)? locating,
    TResult Function(_PlaceSelected value)? placeSelected,
    TResult Function(_EditingCheckIn value)? editingCheckIn,
    TResult Function(_EditingStamp value)? editingStamp,
    TResult Function(_Saving value)? saving,
    TResult Function(_CompleteCheckIn value)? completeCheckIn,
    TResult Function(_CompleteStamp value)? completeStamp,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (saving != null) {
      return saving(this);
    }
    return orElse();
  }
}

abstract class _Saving implements CheckinState {
  const factory _Saving() = _$SavingImpl;
}

/// @nodoc
abstract class _$$CompleteCheckInImplCopyWith<$Res> {
  factory _$$CompleteCheckInImplCopyWith(_$CompleteCheckInImpl value,
          $Res Function(_$CompleteCheckInImpl) then) =
      __$$CompleteCheckInImplCopyWithImpl<$Res>;
  @useResult
  $Res call({CheckIn checkIn});

  $CheckInCopyWith<$Res> get checkIn;
}

/// @nodoc
class __$$CompleteCheckInImplCopyWithImpl<$Res>
    extends _$CheckinStateCopyWithImpl<$Res, _$CompleteCheckInImpl>
    implements _$$CompleteCheckInImplCopyWith<$Res> {
  __$$CompleteCheckInImplCopyWithImpl(
      _$CompleteCheckInImpl _value, $Res Function(_$CompleteCheckInImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checkIn = null,
  }) {
    return _then(_$CompleteCheckInImpl(
      null == checkIn
          ? _value.checkIn
          : checkIn // ignore: cast_nullable_to_non_nullable
              as CheckIn,
    ));
  }

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CheckInCopyWith<$Res> get checkIn {
    return $CheckInCopyWith<$Res>(_value.checkIn, (value) {
      return _then(_value.copyWith(checkIn: value));
    });
  }
}

/// @nodoc

class _$CompleteCheckInImpl
    with DiagnosticableTreeMixin
    implements _CompleteCheckIn {
  const _$CompleteCheckInImpl(this.checkIn);

  @override
  final CheckIn checkIn;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CheckinState.completeCheckIn(checkIn: $checkIn)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CheckinState.completeCheckIn'))
      ..add(DiagnosticsProperty('checkIn', checkIn));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompleteCheckInImpl &&
            (identical(other.checkIn, checkIn) || other.checkIn == checkIn));
  }

  @override
  int get hashCode => Object.hash(runtimeType, checkIn);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompleteCheckInImplCopyWith<_$CompleteCheckInImpl> get copyWith =>
      __$$CompleteCheckInImplCopyWithImpl<_$CompleteCheckInImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() locating,
    required TResult Function(double lat, double lng, List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace, List<ExternalPlace> placeSuggestions)
        placeSelected,
    required TResult Function(CheckInDraft draft) editingCheckIn,
    required TResult Function(StampDraft draft) editingStamp,
    required TResult Function() saving,
    required TResult Function(CheckIn checkIn) completeCheckIn,
    required TResult Function(String stampId) completeStamp,
    required TResult Function(String message) error,
  }) {
    return completeCheckIn(checkIn);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? locating,
    TResult? Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult? Function(CheckInDraft draft)? editingCheckIn,
    TResult? Function(StampDraft draft)? editingStamp,
    TResult? Function()? saving,
    TResult? Function(CheckIn checkIn)? completeCheckIn,
    TResult? Function(String stampId)? completeStamp,
    TResult? Function(String message)? error,
  }) {
    return completeCheckIn?.call(checkIn);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? locating,
    TResult Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult Function(CheckInDraft draft)? editingCheckIn,
    TResult Function(StampDraft draft)? editingStamp,
    TResult Function()? saving,
    TResult Function(CheckIn checkIn)? completeCheckIn,
    TResult Function(String stampId)? completeStamp,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (completeCheckIn != null) {
      return completeCheckIn(checkIn);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Locating value) locating,
    required TResult Function(_PlaceSelected value) placeSelected,
    required TResult Function(_EditingCheckIn value) editingCheckIn,
    required TResult Function(_EditingStamp value) editingStamp,
    required TResult Function(_Saving value) saving,
    required TResult Function(_CompleteCheckIn value) completeCheckIn,
    required TResult Function(_CompleteStamp value) completeStamp,
    required TResult Function(_Error value) error,
  }) {
    return completeCheckIn(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Locating value)? locating,
    TResult? Function(_PlaceSelected value)? placeSelected,
    TResult? Function(_EditingCheckIn value)? editingCheckIn,
    TResult? Function(_EditingStamp value)? editingStamp,
    TResult? Function(_Saving value)? saving,
    TResult? Function(_CompleteCheckIn value)? completeCheckIn,
    TResult? Function(_CompleteStamp value)? completeStamp,
    TResult? Function(_Error value)? error,
  }) {
    return completeCheckIn?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Locating value)? locating,
    TResult Function(_PlaceSelected value)? placeSelected,
    TResult Function(_EditingCheckIn value)? editingCheckIn,
    TResult Function(_EditingStamp value)? editingStamp,
    TResult Function(_Saving value)? saving,
    TResult Function(_CompleteCheckIn value)? completeCheckIn,
    TResult Function(_CompleteStamp value)? completeStamp,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (completeCheckIn != null) {
      return completeCheckIn(this);
    }
    return orElse();
  }
}

abstract class _CompleteCheckIn implements CheckinState {
  const factory _CompleteCheckIn(final CheckIn checkIn) = _$CompleteCheckInImpl;

  CheckIn get checkIn;

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompleteCheckInImplCopyWith<_$CompleteCheckInImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CompleteStampImplCopyWith<$Res> {
  factory _$$CompleteStampImplCopyWith(
          _$CompleteStampImpl value, $Res Function(_$CompleteStampImpl) then) =
      __$$CompleteStampImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String stampId});
}

/// @nodoc
class __$$CompleteStampImplCopyWithImpl<$Res>
    extends _$CheckinStateCopyWithImpl<$Res, _$CompleteStampImpl>
    implements _$$CompleteStampImplCopyWith<$Res> {
  __$$CompleteStampImplCopyWithImpl(
      _$CompleteStampImpl _value, $Res Function(_$CompleteStampImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stampId = null,
  }) {
    return _then(_$CompleteStampImpl(
      null == stampId
          ? _value.stampId
          : stampId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$CompleteStampImpl
    with DiagnosticableTreeMixin
    implements _CompleteStamp {
  const _$CompleteStampImpl(this.stampId);

  @override
  final String stampId;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CheckinState.completeStamp(stampId: $stampId)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CheckinState.completeStamp'))
      ..add(DiagnosticsProperty('stampId', stampId));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompleteStampImpl &&
            (identical(other.stampId, stampId) || other.stampId == stampId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, stampId);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompleteStampImplCopyWith<_$CompleteStampImpl> get copyWith =>
      __$$CompleteStampImplCopyWithImpl<_$CompleteStampImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() locating,
    required TResult Function(double lat, double lng, List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace, List<ExternalPlace> placeSuggestions)
        placeSelected,
    required TResult Function(CheckInDraft draft) editingCheckIn,
    required TResult Function(StampDraft draft) editingStamp,
    required TResult Function() saving,
    required TResult Function(CheckIn checkIn) completeCheckIn,
    required TResult Function(String stampId) completeStamp,
    required TResult Function(String message) error,
  }) {
    return completeStamp(stampId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? locating,
    TResult? Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult? Function(CheckInDraft draft)? editingCheckIn,
    TResult? Function(StampDraft draft)? editingStamp,
    TResult? Function()? saving,
    TResult? Function(CheckIn checkIn)? completeCheckIn,
    TResult? Function(String stampId)? completeStamp,
    TResult? Function(String message)? error,
  }) {
    return completeStamp?.call(stampId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? locating,
    TResult Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult Function(CheckInDraft draft)? editingCheckIn,
    TResult Function(StampDraft draft)? editingStamp,
    TResult Function()? saving,
    TResult Function(CheckIn checkIn)? completeCheckIn,
    TResult Function(String stampId)? completeStamp,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (completeStamp != null) {
      return completeStamp(stampId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Locating value) locating,
    required TResult Function(_PlaceSelected value) placeSelected,
    required TResult Function(_EditingCheckIn value) editingCheckIn,
    required TResult Function(_EditingStamp value) editingStamp,
    required TResult Function(_Saving value) saving,
    required TResult Function(_CompleteCheckIn value) completeCheckIn,
    required TResult Function(_CompleteStamp value) completeStamp,
    required TResult Function(_Error value) error,
  }) {
    return completeStamp(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Locating value)? locating,
    TResult? Function(_PlaceSelected value)? placeSelected,
    TResult? Function(_EditingCheckIn value)? editingCheckIn,
    TResult? Function(_EditingStamp value)? editingStamp,
    TResult? Function(_Saving value)? saving,
    TResult? Function(_CompleteCheckIn value)? completeCheckIn,
    TResult? Function(_CompleteStamp value)? completeStamp,
    TResult? Function(_Error value)? error,
  }) {
    return completeStamp?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Locating value)? locating,
    TResult Function(_PlaceSelected value)? placeSelected,
    TResult Function(_EditingCheckIn value)? editingCheckIn,
    TResult Function(_EditingStamp value)? editingStamp,
    TResult Function(_Saving value)? saving,
    TResult Function(_CompleteCheckIn value)? completeCheckIn,
    TResult Function(_CompleteStamp value)? completeStamp,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (completeStamp != null) {
      return completeStamp(this);
    }
    return orElse();
  }
}

abstract class _CompleteStamp implements CheckinState {
  const factory _CompleteStamp(final String stampId) = _$CompleteStampImpl;

  String get stampId;

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompleteStampImplCopyWith<_$CompleteStampImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
          _$ErrorImpl value, $Res Function(_$ErrorImpl) then) =
      __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$CheckinStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ErrorImpl with DiagnosticableTreeMixin implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CheckinState.error(message: $message)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CheckinState.error'))
      ..add(DiagnosticsProperty('message', message));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() locating,
    required TResult Function(double lat, double lng, List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace, List<ExternalPlace> placeSuggestions)
        placeSelected,
    required TResult Function(CheckInDraft draft) editingCheckIn,
    required TResult Function(StampDraft draft) editingStamp,
    required TResult Function() saving,
    required TResult Function(CheckIn checkIn) completeCheckIn,
    required TResult Function(String stampId) completeStamp,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? locating,
    TResult? Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult? Function(CheckInDraft draft)? editingCheckIn,
    TResult? Function(StampDraft draft)? editingStamp,
    TResult? Function()? saving,
    TResult? Function(CheckIn checkIn)? completeCheckIn,
    TResult? Function(String stampId)? completeStamp,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? locating,
    TResult Function(
            double lat,
            double lng,
            List<Stamp> nearbyStamps,
            ExternalPlace? suggestedPlace,
            List<ExternalPlace> placeSuggestions)?
        placeSelected,
    TResult Function(CheckInDraft draft)? editingCheckIn,
    TResult Function(StampDraft draft)? editingStamp,
    TResult Function()? saving,
    TResult Function(CheckIn checkIn)? completeCheckIn,
    TResult Function(String stampId)? completeStamp,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Idle value) idle,
    required TResult Function(_Locating value) locating,
    required TResult Function(_PlaceSelected value) placeSelected,
    required TResult Function(_EditingCheckIn value) editingCheckIn,
    required TResult Function(_EditingStamp value) editingStamp,
    required TResult Function(_Saving value) saving,
    required TResult Function(_CompleteCheckIn value) completeCheckIn,
    required TResult Function(_CompleteStamp value) completeStamp,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Idle value)? idle,
    TResult? Function(_Locating value)? locating,
    TResult? Function(_PlaceSelected value)? placeSelected,
    TResult? Function(_EditingCheckIn value)? editingCheckIn,
    TResult? Function(_EditingStamp value)? editingStamp,
    TResult? Function(_Saving value)? saving,
    TResult? Function(_CompleteCheckIn value)? completeCheckIn,
    TResult? Function(_CompleteStamp value)? completeStamp,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Idle value)? idle,
    TResult Function(_Locating value)? locating,
    TResult Function(_PlaceSelected value)? placeSelected,
    TResult Function(_EditingCheckIn value)? editingCheckIn,
    TResult Function(_EditingStamp value)? editingStamp,
    TResult Function(_Saving value)? saving,
    TResult Function(_CompleteCheckIn value)? completeCheckIn,
    TResult Function(_CompleteStamp value)? completeStamp,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements CheckinState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of CheckinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
