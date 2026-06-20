import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../models/event_model.dart';

/// Supabase-backed source for events.
abstract interface class EventRemoteDataSource {
  Future<List<EventModel>> getEvents({String? category});
  Future<EventModel> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String location,
    required String category,
    Uint8List? imageBytes,
    String? imageExt,
  });
  Future<void> deleteEvent(String eventId);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  EventRemoteDataSourceImpl(this._client, this._storage);

  final SupabaseClient _client;
  final StorageService _storage;

  @override
  Future<List<EventModel>> getEvents({String? category}) async {
    try {
      var query = _client.from('events').select();
      if (category != null && category != 'all') {
        query = query.eq('category', category);
      }
      final rows = await query.order('date', ascending: true);
      return rows.map(EventModel.fromJson).toList();
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<EventModel> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String location,
    required String category,
    Uint8List? imageBytes,
    String? imageExt,
  }) async {
    try {
      String? imageUrl;
      if (imageBytes != null) {
        imageUrl = await _storage.uploadImage(
          folder: 'events',
          bytes: imageBytes,
          ext: imageExt ?? 'jpg',
        );
      }
      final row = await _client
          .from('events')
          .insert(EventModel.toInsert(
            title: title,
            description: description,
            date: date,
            time: time,
            location: location,
            category: category,
            imageUrl: imageUrl,
          ))
          .select()
          .single();
      return EventModel.fromJson(row);
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      await _client.from('events').delete().eq('id', eventId);
    } catch (_) {
      throw const ServerException();
    }
  }
}
