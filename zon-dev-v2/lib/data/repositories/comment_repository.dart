import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/supabase/supabase_provider.dart';

part 'comment_repository.g.dart';

class StampComment {
  final String id;
  final String stampId;
  final String userId;
  final String? parentId;
  final String body;
  final DateTime createdAt;
  final String? username;
  final String? avatarUrl;

  const StampComment({
    required this.id,
    required this.stampId,
    required this.userId,
    this.parentId,
    required this.body,
    required this.createdAt,
    this.username,
    this.avatarUrl,
  });
}

@riverpod
CommentRepository commentRepository(CommentRepositoryRef ref) =>
    CommentRepository(ref.watch(supabaseClientProvider));

class CommentRepository {
  final SupabaseClient _client;
  CommentRepository(this._client);

  Future<Either<AppException, List<StampComment>>> getComments(
      String stampId) async {
    try {
      final data = await _client
          .from('stamp_comments')
          .select('*, profiles(username, avatar_url)')
          .eq('stamp_id', stampId)
          .order('created_at', ascending: true);
      return right(data.map(_fromRow).toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, StampComment>> addComment({
    required String stampId,
    required String body,
    String? parentId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final data = await _client
          .from('stamp_comments')
          .insert({
            'stamp_id': stampId,
            'user_id': userId,
            'body': body,
            if (parentId != null) 'parent_id': parentId,
          })
          .select('*, profiles(username, avatar_url)')
          .single();
      return right(_fromRow(data));
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, Unit>> deleteComment(String id) async {
    try {
      await _client.from('stamp_comments').delete().eq('id', id);
      return right(unit);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  StampComment _fromRow(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    return StampComment(
      id: row['id'] as String,
      stampId: row['stamp_id'] as String,
      userId: row['user_id'] as String,
      parentId: row['parent_id'] as String?,
      body: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
