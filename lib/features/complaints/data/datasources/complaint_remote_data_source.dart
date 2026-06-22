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
}
