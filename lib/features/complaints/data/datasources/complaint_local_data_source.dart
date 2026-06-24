import '../../../../core/services/cache_service.dart';
import '../models/complaint_model.dart';

/// Caches the admin "Approvals" list for instant paint and offline reads.
abstract interface class ComplaintLocalDataSource {
  Future<void> cacheAll(List<ComplaintModel> items);
  List<ComplaintModel> getCachedAll();
}

class ComplaintLocalDataSourceImpl implements ComplaintLocalDataSource {
  ComplaintLocalDataSourceImpl(this._cache);

  final CacheService _cache;
  static const _key = 'complaints_admin';

  @override
  Future<void> cacheAll(List<ComplaintModel> items) =>
      _cache.writeList(_key, items.map((e) => e.toJson()).toList());

  @override
  List<ComplaintModel> getCachedAll() =>
      (_cache.readList(_key) ?? []).map(ComplaintModel.fromJson).toList();
}
