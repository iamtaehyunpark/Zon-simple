import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'privacy_repository.g.dart';

class UserPrivacy {
  final StampVisibility defaultStampVisibility;
  final bool locationSharingEnabled;
  final bool significantChangeEnabled;
  final bool photoAutoSuggest;
  final bool eveningSummaryEnabled;

  const UserPrivacy({
    this.defaultStampVisibility = StampVisibility.private,
    this.locationSharingEnabled = false,
    this.significantChangeEnabled = true,
    this.photoAutoSuggest = true,
    this.eveningSummaryEnabled = true,
  });

  UserPrivacy copyWith({
    StampVisibility? defaultStampVisibility,
    bool? locationSharingEnabled,
    bool? significantChangeEnabled,
    bool? photoAutoSuggest,
    bool? eveningSummaryEnabled,
  }) =>
      UserPrivacy(
        defaultStampVisibility:
            defaultStampVisibility ?? this.defaultStampVisibility,
        locationSharingEnabled:
            locationSharingEnabled ?? this.locationSharingEnabled,
        significantChangeEnabled:
            significantChangeEnabled ?? this.significantChangeEnabled,
        photoAutoSuggest: photoAutoSuggest ?? this.photoAutoSuggest,
        eveningSummaryEnabled:
            eveningSummaryEnabled ?? this.eveningSummaryEnabled,
      );
}

@riverpod
PrivacyRepository privacyRepository(PrivacyRepositoryRef ref) =>
    PrivacyRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

class PrivacyRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  PrivacyRepository(this.client, {this.currentUserId});

  Future<Either<AppException, UserPrivacy>> getMyPrivacy() async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final row = await client
          .from('user_privacy')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return right(const UserPrivacy());
      return right(_fromRow(row));
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, Unit>> update(Map<String, dynamic> updates) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      await client
          .from('user_privacy')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId);
      return right(unit);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  UserPrivacy _fromRow(Map<String, dynamic> r) => UserPrivacy(
        defaultStampVisibility:
            (r['default_stamp_visibility'] as String?) == 'public'
                ? StampVisibility.public
                : StampVisibility.private,
        locationSharingEnabled: r['location_sharing_enabled'] as bool? ?? false,
        significantChangeEnabled:
            r['significant_change_enabled'] as bool? ?? true,
        photoAutoSuggest: r['photo_auto_suggest'] as bool? ?? true,
        eveningSummaryEnabled: r['evening_summary_enabled'] as bool? ?? true,
      );
}
