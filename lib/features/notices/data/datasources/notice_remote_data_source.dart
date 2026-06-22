import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../models/notice_model.dart';

abstract interface class NoticeRemoteDataSource {
  Future<List<NoticeModel>> getNotices({int limit, int offset});
  Future<NoticeModel> createNotice({
    required String title,
    required String content,
    required String category,
    required String priority,
    String? department,
  });
  Future<NoticeModel> updateNotice({
    required String id,
    required String title,
    required String content,
    required String category,
    required String priority,
    String? department,
  });
  Future<void> deleteNotice(String noticeId);
}

class NoticeRemoteDataSourceImpl implements NoticeRemoteDataSource {
  NoticeRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<NoticeModel>> getNotices({int limit = 20, int offset = 0}) async {
    try {
      final rows = await _client
          .from('notices')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map(NoticeModel.fromJson).toList();
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<NoticeModel> createNotice({
    required String title,
    required String content,
    required String category,
    required String priority,
    String? department,
  }) async {
    try {
      final row = await _client
          .from('notices')
          .insert(NoticeModel.toInsert(
            title: title,
            content: content,
            category: category,
            priority: priority,
            department: department,
          ))
          .select()
          .single();
      return NoticeModel.fromJson(row);
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<NoticeModel> updateNotice({
    required String id,
    required String title,
    required String content,
    required String category,
    required String priority,
    String? department,
  }) async {
    try {
      final row = await _client
          .from('notices')
          .update({
            'title': title,
            'content': content,
            'category': category,
            'priority': priority,
            'department': department,
          })
          .eq('id', id)
          .select()
          .single();
      return NoticeModel.fromJson(row);
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> deleteNotice(String noticeId) async {
    try {
      await _client.from('notices').delete().eq('id', noticeId);
    } catch (_) {
      throw const ServerException();
    }
  }
}
