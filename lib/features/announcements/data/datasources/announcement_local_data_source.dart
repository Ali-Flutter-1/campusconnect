import '../../../../core/services/cache_service.dart';
import '../models/announcement_model.dart';

/// Caches the first page of announcements for instant (and offline) reads.
abstract interface class AnnouncementLocalDataSource {
  Future<void> cache(List<AnnouncementModel> items);
  List<AnnouncementModel> getCached();
}

class AnnouncementLocalDataSourceImpl implements AnnouncementLocalDataSource {
  AnnouncementLocalDataSourceImpl(this._cache);

  final CacheService _cache;
  static const _key = 'announcements';

  @override
  Future<void> cache(List<AnnouncementModel> items) =>
      _cache.writeList(_key, items.map((e) => e.toJson()).toList());

  @override
  List<AnnouncementModel> getCached() =>
      (_cache.readList(_key) ?? []).map(AnnouncementModel.fromJson).toList();
}
