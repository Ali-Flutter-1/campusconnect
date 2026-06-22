import '../../../../core/services/cache_service.dart';
import '../models/event_model.dart';

/// Caches the first page of events per category for instant/offline reads.
abstract interface class EventLocalDataSource {
  Future<void> cache(String category, List<EventModel> items);
  List<EventModel> getCached(String category);
}

class EventLocalDataSourceImpl implements EventLocalDataSource {
  EventLocalDataSourceImpl(this._cache);

  final CacheService _cache;

  String _key(String category) => 'events:$category';

  @override
  Future<void> cache(String category, List<EventModel> items) =>
      _cache.writeList(_key(category), items.map((e) => e.toJson()).toList());

  @override
  List<EventModel> getCached(String category) =>
      (_cache.readList(_key(category)) ?? [])
          .map(EventModel.fromJson)
          .toList();
}
