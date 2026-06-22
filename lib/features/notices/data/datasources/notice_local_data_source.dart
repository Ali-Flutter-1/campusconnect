import '../../../../core/services/cache_service.dart';
import '../models/notice_model.dart';

/// Caches the first page of notices for instant/offline reads.
abstract interface class NoticeLocalDataSource {
  Future<void> cache(List<NoticeModel> items);
  List<NoticeModel> getCached();
}

class NoticeLocalDataSourceImpl implements NoticeLocalDataSource {
  NoticeLocalDataSourceImpl(this._cache);

  final CacheService _cache;
  static const _key = 'notices';

  @override
  Future<void> cache(List<NoticeModel> items) =>
      _cache.writeList(_key, items.map((e) => e.toJson()).toList());

  @override
  List<NoticeModel> getCached() =>
      (_cache.readList(_key) ?? []).map(NoticeModel.fromJson).toList();
}
