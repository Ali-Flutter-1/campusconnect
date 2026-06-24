import 'package:connect/core/sync/outbox_entry.dart';
import 'package:connect/core/sync/outbox_handler.dart';
import 'package:connect/core/sync/outbox_store.dart';
import 'package:connect/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mocktail/mocktail.dart';

class _MockStore extends Mock implements OutboxStore {}

class _MockConnection extends Mock implements InternetConnection {}

/// Records the order it was called and returns a scripted outcome.
class _RecordingHandler implements OutboxHandler {
  _RecordingHandler(this.outcomeFor);
  final SyncOutcome Function(Map<String, dynamic>) outcomeFor;
  final calls = <String>[];

  @override
  String get type => 'test';

  @override
  Future<SyncOutcome> handle(Map<String, dynamic> payload) async {
    calls.add(payload['n'].toString());
    return outcomeFor(payload);
  }
}

OutboxEntry _entry(String id, int n, int secondsAgo) => OutboxEntry(
      id: id,
      type: 'test',
      payload: {'n': n},
      createdAt: DateTime(2026).add(Duration(seconds: secondsAgo)),
    );

void main() {
  late _MockStore store;
  late _MockConnection conn;

  setUp(() {
    store = _MockStore();
    conn = _MockConnection();
    when(() => conn.hasInternetAccess).thenAnswer((_) async => true);
    when(() => store.remove(any())).thenAnswer((_) async {});
  });

  test('drains in FIFO order and removes each on success', () async {
    final handler = _RecordingHandler((_) => SyncOutcome.success);
    when(() => store.all()).thenReturn([
      _entry('a', 1, 0),
      _entry('b', 2, 1),
      _entry('c', 3, 2),
    ]);

    final service = SyncService(
      store: store,
      connection: conn,
      handlers: [handler],
    );
    await service.processPending();

    expect(handler.calls, ['1', '2', '3']); // oldest first
    verify(() => store.remove('a')).called(1);
    verify(() => store.remove('b')).called(1);
    verify(() => store.remove('c')).called(1);
  });

  test('a retry stops processing so order is preserved', () async {
    // Entry 2 needs a retry → entry 3 must NOT be sent before it.
    final handler = _RecordingHandler(
      (p) => p['n'] == 2 ? SyncOutcome.retry : SyncOutcome.success,
    );
    when(() => store.all()).thenReturn([
      _entry('a', 1, 0),
      _entry('b', 2, 1),
      _entry('c', 3, 2),
    ]);

    final service = SyncService(
      store: store,
      connection: conn,
      handlers: [handler],
    );
    await service.processPending();

    expect(handler.calls, ['1', '2']); // stopped at the retry; never reached 3
    verify(() => store.remove('a')).called(1);
    verifyNever(() => store.remove('b'));
    verifyNever(() => store.remove('c'));
  });
}
