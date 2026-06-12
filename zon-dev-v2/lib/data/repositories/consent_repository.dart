import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/app_exception.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'consent_repository.g.dart';

/// Disclosure text version the user agreed to. Bump when the copy materially
/// changes — a new version forces re-consent in opt-in jurisdictions.
const kConsentVersion = 'v1-2026-06';

/// Marks an opt-out user resolved without a manual tap. `consent_version` being
/// non-null (this value) is what makes their seeded opt-out default count as a
/// real, recorded decision for [bm_place_aggregates].
const kAutoOptOutVersion = 'auto-optout-$kConsentVersion';

/// Mirror of a `data_consents` row.
class DataConsent {
  final bool bmDataUse; // secondary / big-data aggregate use
  final bool thirdPartyShare; // provision to third parties (separate purpose)
  final String? consentVersion; // null => never actively resolved
  final String? jurisdiction;

  const DataConsent({
    this.bmDataUse = false,
    this.thirdPartyShare = false,
    this.consentVersion,
    this.jurisdiction,
  });

  /// Has the user (or the app, for opt-out) actually recorded a decision?
  /// Until this is true the seeded opt-out default must NOT be treated as
  /// consent — the DB enforces the same rule in [bm_place_aggregates].
  bool get isResolved => consentVersion != null;

  DataConsent copyWith({
    bool? bmDataUse,
    bool? thirdPartyShare,
    String? consentVersion,
    String? jurisdiction,
  }) =>
      DataConsent(
        bmDataUse: bmDataUse ?? this.bmDataUse,
        thirdPartyShare: thirdPartyShare ?? this.thirdPartyShare,
        consentVersion: consentVersion ?? this.consentVersion,
        jurisdiction: jurisdiction ?? this.jurisdiction,
      );
}

@riverpod
ConsentRepository consentRepository(ConsentRepositoryRef ref) =>
    ConsentRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

class ConsentRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  ConsentRepository(this.client, {this.currentUserId});

  /// Reads the caller's consent row. A missing row (shouldn't happen — seeded by
  /// `handle_new_user`) is surfaced as an unresolved default so the gate logic
  /// still runs.
  Future<Either<AppException, DataConsent>> getMyConsent() async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final row = await client
          .from('data_consents')
          .select('bm_data_use, third_party_share, consent_version, jurisdiction')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return right(const DataConsent());
      return right(_fromRow(row));
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Records a consent decision. Always stamps `consent_version` + `jurisdiction`
  /// so the row counts as actively resolved. RLS allows a user to update only
  /// their own row.
  Future<Either<AppException, Unit>> record({
    required bool bmDataUse,
    required bool thirdPartyShare,
    required String jurisdiction,
    String consentVersion = kConsentVersion,
  }) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      await client.from('data_consents').update({
        'bm_data_use': bmDataUse,
        'third_party_share': thirdPartyShare,
        'consent_version': consentVersion,
        'jurisdiction': jurisdiction,
        'decided_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
      return right(unit);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Transparency / right-of-access: the row of attributes inferred about the
  /// caller. RLS lets a user read only their own. Returns null when no row /
  /// nothing inferred yet (inference jobs are a later workstream).
  Future<Either<AppException, Map<String, dynamic>?>> getMyAttributes() async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final row = await client
          .from('user_attributes')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return right(row);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  DataConsent _fromRow(Map<String, dynamic> r) => DataConsent(
        bmDataUse: r['bm_data_use'] as bool? ?? false,
        thirdPartyShare: r['third_party_share'] as bool? ?? false,
        consentVersion: r['consent_version'] as String?,
        jurisdiction: r['jurisdiction'] as String?,
      );
}
