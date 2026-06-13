import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'diary_repository.g.dart';

@riverpod
DiaryRepository diaryRepository(DiaryRepositoryRef ref) => DiaryRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

/// Per-day free-text diary entry.
class DiaryRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  DiaryRepository(this.client, {this.currentUserId});

  Future<String> getDiary(DateTime date) async {
    final uid = userId;
    if (uid == null) return '';
    try {
      final row = await client
          .from('day_diaries')
          .select('body')
          .eq('user_id', uid)
          .eq('date', isoDate(date))
          .maybeSingle();
      return (row?['body'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Call the generate-diary Edge Function with pre-processed events.
  /// Events must already have [photos] as base64 JPEG strings (resized
  /// client-side via PhotoService.resizeForLlm). Returns the generated text.
  Future<String> generateDiary(
    DateTime date,
    List<Map<String, dynamic>> events,
  ) async {
    if (userId == null) throw Exception('Unauthorized');
    // invoke() throws on HTTP error; on success, result.data is the decoded JSON.
    final result = await client.functions.invoke(
      'generate-diary',
      body: {'date': isoDate(date), 'events': events},
    );
    return (result.data as Map<String, dynamic>?)?['diary'] as String? ?? '';
  }

  Future<List<({DateTime date, String body})>> getDiaries() async {
    final uid = userId;
    if (uid == null) return [];
    try {
      final rows = await client
          .from('day_diaries')
          .select('date, body')
          .eq('user_id', uid)
          .order('date', ascending: false)
          .limit(60);
      return [
        for (final r in rows as List)
          (
            date: DateTime.parse(r['date'] as String),
            body: (r['body'] as String?) ?? '',
          ),
      ].where((e) => e.body.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns ISO date strings (yyyy-MM-dd) for all days that have a non-empty
  /// diary entry on or after [from].
  Future<Set<String>> getDiaryDates({required String from}) async {
    final uid = userId;
    if (uid == null) return {};
    try {
      final rows = await client
          .from('day_diaries')
          .select('date')
          .eq('user_id', uid)
          .not('body', 'eq', '')
          .gte('date', from);
      return {for (final r in rows as List) r['date'] as String};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDiary(DateTime date, String body) async {
    final uid = userId;
    if (uid == null) return;
    await client.from('day_diaries').upsert({
      'user_id': uid,
      'date': isoDate(date),
      'body': body,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
