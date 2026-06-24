/// Outcome of attempting to flush one outbox entry.
enum SyncOutcome {
  /// Sent successfully — remove from the queue.
  success,

  /// Transient failure (e.g. offline / network) — keep and retry later.
  /// Processing stops at this entry to preserve send order.
  retry,

  /// Permanent failure (e.g. rejected by the server) — drop it; the originating
  /// feature is told via [SyncResult] so it can undo any optimistic UI.
  fail,
}

/// Result emitted after an entry is processed, so features can react (e.g. mark
/// a chat message sent/failed, or revert an optimistic poll vote).
class SyncResult {
  const SyncResult({
    required this.id,
    required this.type,
    required this.payload,
    required this.outcome,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final SyncOutcome outcome;
}

/// Executes one kind of queued write. Each feature provides a handler keyed by
/// [type] (e.g. 'chat.send'); the `SyncService` routes entries to them. Lives in
/// core so the sync engine never imports feature code — features implement this.
abstract interface class OutboxHandler {
  String get type;

  Future<SyncOutcome> handle(Map<String, dynamic> payload);
}
