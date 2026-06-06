import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'timeline_note_repository.g.dart';

class TimelineNote {
  final String id;
  final String body;
  final DateTime notedAt;
  const TimelineNote({
    required this.id,
    required this.body,
    required this.notedAt,
  });
}

@riverpod
TimelineNoteRepository timelineNoteRepository(TimelineNoteRepositoryRef ref) =>
    TimelineNoteRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

class TimelineNoteRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  TimelineNoteRepository(this.client, {this.currentUserId});

  Future<List<TimelineNote>> getForDay(DateTime date) async {
    final uid = userId;
    if (uid == null) return [];
    try {
      final rows = await client
          .from('timeline_notes')
          .select()
          .eq('user_id', uid)
          .eq('date', isoDate(date))
          .order('noted_at', ascending: true);
      return [
        for (final r in rows)
          TimelineNote(
            id: r['id'] as String,
            body: r['body'] as String,
            notedAt: DateTime.parse(r['noted_at'] as String),
          )
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> add(DateTime date, String body, DateTime notedAt) async {
    final uid = userId;
    if (uid == null) return;
    await client.from('timeline_notes').insert({
      'user_id': uid,
      'date': isoDate(date),
      'body': body,
      'noted_at': notedAt.toIso8601String(),
    });
  }

  Future<void> update(String id, String body) async {
    await client.from('timeline_notes').update({
      'body': body,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Reposition a note within the day by changing its time.
  Future<void> setTime(String id, DateTime notedAt) async {
    await client.from('timeline_notes').update({
      'noted_at': notedAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await client.from('timeline_notes').delete().eq('id', id);
  }
}
