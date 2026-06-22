import 'package:hive_ce/hive.dart';

/// Thin wrapper over a Hive box used to cache lists of JSON rows for
/// stale-while-revalidate reads. Stores raw maps (Supabase row shape) so each
/// feature can rebuild its models via the existing `Model.fromJson`.
class CacheService {
  CacheService(this._box);

  final Box _box;

  /// The single Hive box all caches share (opened in `bootstrap`).
  static const String boxName = 'connect_cache';

  static Future<Box> openBox() => Hive.openBox(boxName);

  /// Cache [rows] under [key].
  Future<void> writeList(String key, List<Map<String, dynamic>> rows) =>
      _box.put(key, rows);

  /// Read cached rows for [key], or `null` if nothing was cached.
  List<Map<String, dynamic>>? readList(String key) {
    final raw = _box.get(key);
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}
