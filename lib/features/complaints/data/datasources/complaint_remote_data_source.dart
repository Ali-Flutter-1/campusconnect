import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../models/complaint_model.dart';

abstract interface class ComplaintRemoteDataSource {
  Future<List<ComplaintModel>> getMyComplaints();
  Future<ComplaintModel> createComplaint({
    required String title,
    required String description,
    required String category,
  });

  /// Admin-only: every request, newest first, enriched with the submitter's
  /// name/email from `profiles`. RLS restricts this to admins server-side.
  Future<List<ComplaintModel>> getAllComplaints();

  /// Admin-only: move a request to [status]
  /// ('open' | 'in_progress' | 'resolved' | 'rejected').
  Future<ComplaintModel> updateStatus({
    required String id,
    required String status,
  });
}

class ComplaintRemoteDataSourceImpl implements ComplaintRemoteDataSource {
  ComplaintRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _requireUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException();
    return id;
  }

  @override
  Future<List<ComplaintModel>> getMyComplaints() async {
    final userId = _requireUserId;
    try {
      final rows = await _client
          .from('complaints')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows.map(ComplaintModel.fromJson).toList();
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<ComplaintModel> createComplaint({
    required String title,
    required String description,
    required String category,
  }) async {
    final userId = _requireUserId;
    try {
      final row = await _client
          .from('complaints')
          .insert(ComplaintModel.toInsert(
            userId: userId,
            title: title,
            description: description,
            category: category,
          ))
          .select()
          .single();
      return ComplaintModel.fromJson(row);
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<List<ComplaintModel>> getAllComplaints() async {
    try {
      // Cap the triage queue at the 100 most recent requests (index-backed by
      // idx_complaints_created_at) so the admin view stays bounded as the table
      // grows. Older resolved requests fall off the live queue.
      final rows = await _client
          .from('complaints')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      final list = List<Map<String, dynamic>>.from(rows);

      // Enrich with submitter details in a single follow-up query. The FK on
      // complaints.user_id points at auth.users (not profiles), so we resolve
      // names by id rather than relying on a PostgREST embed.
      final ids = list
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      if (ids.isNotEmpty) {
        final profiles = await _client
            .from('profiles')
            .select('id, full_name, email')
            .inFilter('id', ids);
        final byId = {
          for (final p in List<Map<String, dynamic>>.from(profiles))
            p['id'] as String: p,
        };
        for (final r in list) {
          final p = byId[r['user_id']];
          if (p != null) {
            r['author_name'] = p['full_name'];
            r['author_email'] = p['email'];
          }
        }
      }

      return list.map(ComplaintModel.fromJson).toList();
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<ComplaintModel> updateStatus({
    required String id,
    required String status,
  }) async {
    try {
      final row = await _client
          .from('complaints')
          .update({'status': status})
          .eq('id', id)
          .select()
          .single();
      return ComplaintModel.fromJson(row);
    } catch (_) {
      throw const ServerException();
    }
  }
}
