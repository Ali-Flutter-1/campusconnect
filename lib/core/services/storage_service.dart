import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/exceptions.dart';

/// Uploads images to Supabase Storage and returns their public URLs.
///
/// All media lives in a single public-read `media` bucket (see migration 0005);
/// writes are restricted to admins by storage RLS.
class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  static const String bucket = 'media';

  /// Uploads [bytes] under [folder] (e.g. 'announcements') and returns the
  /// public URL. [ext] is the file extension without a dot (e.g. 'jpg').
  Future<String> uploadImage({
    required String folder,
    required Uint8List bytes,
    required String ext,
  }) async {
    try {
      final safeExt = ext.isEmpty ? 'jpg' : ext.toLowerCase();
      final path =
          '$folder/${DateTime.now().microsecondsSinceEpoch}.$safeExt';
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${safeExt == 'jpg' ? 'jpeg' : safeExt}',
              upsert: true,
            ),
          );
      return _client.storage.from(bucket).getPublicUrl(path);
    } catch (_) {
      throw const ServerException('Image upload failed.');
    }
  }

  /// Uploads a user's avatar under `avatars/<userId>/…` (the path that storage
  /// RLS lets that user write — see migration 0008) and returns the public URL.
  /// Each upload uses a unique filename so the URL changes and clients don't
  /// show a stale cached image.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String ext,
  }) async {
    try {
      final safeExt = ext.isEmpty ? 'jpg' : ext.toLowerCase();
      final path =
          'avatars/$userId/${DateTime.now().microsecondsSinceEpoch}.$safeExt';
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${safeExt == 'jpg' ? 'jpeg' : safeExt}',
              upsert: true,
            ),
          );
      return _client.storage.from(bucket).getPublicUrl(path);
    } catch (_) {
      throw const ServerException('Avatar upload failed.');
    }
  }
}
