import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'outbox_entry.dart';
import 'outbox_handler.dart';
import 'outbox_store.dart';

/// Drains the persistent outbox: sends queued writes in FIFO order when online,
/// retries transient failures when connectivity returns, and reports each
/// outcome on [results] so features can reconcile optimistic UI.
///
/// Only opted-in writes (chat send, poll vote) go through here — the rest of the
/// app writes directly.
class SyncService {
  SyncService({
    required OutboxStore store,
    required InternetConnection connection,
    required List<OutboxHandler> handlers,
  })  : _store = store,
        _connection = connection,
        _handlers = {for (final h in handlers) h.type: h};

  final OutboxStore _store;
  final InternetConnection _connection;
  final Map<String, OutboxHandler> _handlers;

  final _results = StreamController<SyncResult>.broadcast();
  StreamSubscription<InternetStatus>? _connSub;
  bool _draining = false;
  int _seq = 0;

  /// Outcomes of processed entries (success / fail), for features to react to.
  Stream<SyncResult> get results => _results.stream;

  /// Begin: flush anything left over from last session, and flush again each
  /// time the device comes back online.
  void start() {
    _connSub = _connection.onStatusChange.listen((status) {
      if (status == InternetStatus.connected) processPending();
    });
    processPending();
  }

  /// Pending entries of [type] (e.g. to restore unsent chat messages on open).
  List<OutboxEntry> pending(String type) => _store.byType(type);

  /// Queue a write and attempt to flush immediately. Returns the entry id so the
  /// caller can match it back to its optimistic UI. Pass [id] to reuse a client
  /// id you already showed in the UI.
  Future<String> enqueue(
    String type,
    Map<String, dynamic> payload, {
    String? id,
  }) async {
    final entryId = id ?? '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
    await _store.put(OutboxEntry(
      id: entryId,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    ));
    unawaited(processPending());
    return entryId;
  }

  /// Flush the queue oldest-first. Stops at the first entry that needs a retry
  /// so order is preserved; drops permanently-failed entries and moves on.
  Future<void> processPending() async {
    if (_draining) return;
    _draining = true;
    try {
      if (!await _connection.hasInternetAccess) return;
      for (final entry in _store.all()) {
        final handler = _handlers[entry.type];
        if (handler == null) {
          await _store.remove(entry.id);
          continue;
        }
        SyncOutcome outcome;
        try {
          outcome = await handler.handle(entry.payload);
        } catch (_) {
          outcome = SyncOutcome.retry;
        }

        switch (outcome) {
          case SyncOutcome.success:
            await _store.remove(entry.id);
            _emit(entry, SyncOutcome.success);
          case SyncOutcome.fail:
            await _store.remove(entry.id);
            _emit(entry, SyncOutcome.fail);
          case SyncOutcome.retry:
            // Keep it; bail so the next online tick retries in order.
            return;
        }
      }
    } finally {
      _draining = false;
    }
  }

  void _emit(OutboxEntry entry, SyncOutcome outcome) {
    if (_results.isClosed) return;
    _results.add(SyncResult(
      id: entry.id,
      type: entry.type,
      payload: entry.payload,
      outcome: outcome,
    ));
  }

  Future<void> dispose() async {
    await _connSub?.cancel();
    await _results.close();
  }
}
