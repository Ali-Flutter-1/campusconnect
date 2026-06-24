import 'package:hive_ce/hive.dart';

import 'outbox_entry.dart';

/// Hive-backed persistent FIFO queue of pending [OutboxEntry] writes.
class OutboxStore {
  OutboxStore(this._box);

  final Box _box;

  static const String boxName = 'outbox';

  static Future<Box> openBox() => Hive.openBox(boxName);

  /// All pending entries, oldest first (FIFO send order).
  List<OutboxEntry> all() {
    final entries = _box.values
        .whereType<Map>()
        .map((m) => OutboxEntry.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  /// Pending entries of a given [type], oldest first.
  List<OutboxEntry> byType(String type) =>
      all().where((e) => e.type == type).toList();

  Future<void> put(OutboxEntry entry) => _box.put(entry.id, entry.toMap());

  Future<void> remove(String id) => _box.delete(id);
}
