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

  String _date(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<String> getDiary(DateTime date) async {
    final uid = userId;
    if (uid == null) return '';
    try {
      final row = await client
          .from('day_diaries')
          .select('body')
          .eq('user_id', uid)
          .eq('date', _date(date))
          .maybeSingle();
      return (row?['body'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> saveDiary(DateTime date, String body) async {
    final uid = userId;
    if (uid == null) return;
    await client.from('day_diaries').upsert({
      'user_id': uid,
      'date': _date(date),
      'body': body,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
