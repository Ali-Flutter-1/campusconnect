import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../models/poll_model.dart';

abstract interface class PollRemoteDataSource {
  Future<List<PollModel>> getPolls({int? limit});
  Future<Map<String, int>> getUserVotes();
  Future<void> vote({required String pollId, required int optionIndex});
  Future<PollModel> createPoll({
    required String question,
    required List<String> options,
  });
}

class PollRemoteDataSourceImpl implements PollRemoteDataSource {
  PollRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PollModel>> getPolls({int? limit}) async {
    try {
      var query =
          _client.from('polls').select().order('created_at', ascending: false);
      if (limit != null) query = query.limit(limit);
      final rows = await query;
      return rows.map(PollModel.fromJson).toList();
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<Map<String, int>> getUserVotes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};
    try {
      final rows = await _client
          .from('user_poll_votes')
          .select('poll_id, option_index')
          .eq('user_id', userId);
      return {
        for (final r in rows)
          r['poll_id'] as String: (r['option_index'] as num).toInt(),
      };
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> vote({
    required String pollId,
    required int optionIndex,
  }) async {
    if (_client.auth.currentUser == null) throw const AuthException();
    try {
      final result = await _client.rpc('vote_poll', params: {
        'poll_id': pollId,
        'option_index': optionIndex,
      });
      if (result == 'already_voted') {
        throw const ServerException('You have already voted in this poll.');
      }
      if (result == 'unauthenticated') {
        throw const AuthException();
      }
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<PollModel> createPoll({
    required String question,
    required List<String> options,
  }) async {
    try {
      final row = await _client
          .from('polls')
          .insert({
            'question': question,
            'options': [
              for (final o in options) {'text': o, 'count': 0},
            ],
            'total_votes': 0,
          })
          .select()
          .single();
      return PollModel.fromJson(row);
    } catch (_) {
      throw const ServerException();
    }
  }
}
