import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/announcement.dart';
import '../models/announcement_model.dart';

/// Supabase-backed source for announcements. Throws [ServerException] /
/// [AuthException]; the repository maps these to `Failure`s.
abstract interface class AnnouncementRemoteDataSource {
  Future<List<AnnouncementModel>> getAnnouncements();
  Future<AnnouncementInteractions> getInteractions();
  Future<void> toggleLike({required String announcementId, required bool liked});
  Future<void> toggleBookmark({
    required String announcementId,
    required bool bookmarked,
  });
  Future<AnnouncementModel> createAnnouncement({
    required String title,
    required String content,
    required String category,
    required String author,
    Uint8List? imageBytes,
    String? imageExt,
  });
  Future<void> deleteAnnouncement(String announcementId);
}

class AnnouncementRemoteDataSourceImpl implements AnnouncementRemoteDataSource {
  AnnouncementRemoteDataSourceImpl(this._client, this._storage);

  final SupabaseClient _client;
  final StorageService _storage;

  String get _requireUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException();
    return id;
  }

  @override
  Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final rows = await _client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);
      return rows.map(AnnouncementModel.fromJson).toList();
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<AnnouncementInteractions> getInteractions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const AnnouncementInteractions();
    try {
      final likes = await _client
          .from('user_likes')
          .select('announcement_id')
          .eq('user_id', userId);
      final bookmarks = await _client
          .from('user_bookmarks')
          .select('announcement_id')
          .eq('user_id', userId);
      return AnnouncementInteractions(
        likedIds: {for (final r in likes) r['announcement_id'] as String},
        bookmarkedIds: {
          for (final r in bookmarks) r['announcement_id'] as String,
        },
      );
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> toggleLike({
    required String announcementId,
    required bool liked,
  }) async {
    final userId = _requireUserId;
    try {
      if (liked) {
        await _client
            .from('user_likes')
            .insert({'user_id': userId, 'announcement_id': announcementId});
        await _client.rpc('increment_likes',
            params: {'announcement_id': announcementId});
      } else {
        await _client
            .from('user_likes')
            .delete()
            .eq('user_id', userId)
            .eq('announcement_id', announcementId);
        await _client.rpc('decrement_likes',
            params: {'announcement_id': announcementId});
      }
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> toggleBookmark({
    required String announcementId,
    required bool bookmarked,
  }) async {
    final userId = _requireUserId;
    try {
      if (bookmarked) {
        await _client
            .from('user_bookmarks')
            .insert({'user_id': userId, 'announcement_id': announcementId});
        await _client.rpc('increment_bookmarks',
            params: {'announcement_id': announcementId});
      } else {
        await _client
            .from('user_bookmarks')
            .delete()
            .eq('user_id', userId)
            .eq('announcement_id', announcementId);
        await _client.rpc('decrement_bookmarks',
            params: {'announcement_id': announcementId});
      }
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<AnnouncementModel> createAnnouncement({
    required String title,
    required String content,
    required String category,
    required String author,
    Uint8List? imageBytes,
    String? imageExt,
  }) async {
    try {
      String? imageUrl;
      if (imageBytes != null) {
        imageUrl = await _storage.uploadImage(
          folder: 'announcements',
          bytes: imageBytes,
          ext: imageExt ?? 'jpg',
        );
      }
      final row = await _client
          .from('announcements')
          .insert(AnnouncementModel.toInsert(
            title: title,
            content: content,
            category: category,
            author: author,
            imageUrl: imageUrl,
          ))
          .select()
          .single();
      return AnnouncementModel.fromJson(row);
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _client.from('announcements').delete().eq('id', announcementId);
    } catch (_) {
      throw const ServerException();
    }
  }
}
