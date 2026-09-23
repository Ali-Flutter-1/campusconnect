import 'dart:async';

import 'package:connect/core/error/failures.dart';
import 'package:connect/core/sync/outbox_handler.dart';
import 'package:connect/features/chat/data/sync/chat_send_handler.dart';
import 'package:connect/core/sync/sync_service.dart';
import 'package:connect/features/chat/domain/entities/chat_change.dart';
import 'package:connect/features/chat/domain/entities/chat_message.dart';
import 'package:connect/features/chat/domain/usecases/chat_usecases.dart';
import 'package:connect/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMessages extends Mock implements GetMessages {}

class _MockWatchMessages extends Mock implements WatchMessages {}

class _MockWatchReactions extends Mock implements WatchReactions {}

class _MockGetCurrentUserId extends Mock implements GetCurrentUserId {}

class _MockEditMessage extends Mock implements EditMessage {}

class _MockDeleteMessage extends Mock implements DeleteMessage {}

class _MockToggleReaction extends Mock implements ToggleReaction {}

class _MockSyncService extends Mock implements SyncService {}

void main() {
  const uid = 'u1';
  late _MockGetMessages getMessages;
  late _MockWatchMessages watchMessages;
  late _MockWatchReactions watchReactions;
  late _MockGetCurrentUserId getCurrentUserId;
  late _MockEditMessage editMessage;
  late _MockDeleteMessage deleteMessage;
  late _MockToggleReaction toggleReaction;
  late _MockSyncService sync;
  late StreamController<SyncResult> syncResults;

  final mine = ChatMessage(
    id: 'm1',
    senderId: uid,
    senderName: 'Me',
    content: 'hello',
    room: 'global',
    createdAt: DateTime(2026, 1, 1, 9),
  );

  setUpAll(() {
    registerFallbackValue(const GetMessagesParams(room: 'global'));
    registerFallbackValue(const EditMessageParams(id: '', content: ''));
    registerFallbackValue(
      const ToggleReactionParams(messageId: '', emoji: '', add: true),
    );
  });

  setUp(() {
    getMessages = _MockGetMessages();
    watchMessages = _MockWatchMessages();
    watchReactions = _MockWatchReactions();
    getCurrentUserId = _MockGetCurrentUserId();
    editMessage = _MockEditMessage();
    deleteMessage = _MockDeleteMessage();
    toggleReaction = _MockToggleReaction();
    sync = _MockSyncService();
    syncResults = StreamController<SyncResult>.broadcast();

    when(() => getCurrentUserId()).thenReturn(uid);
    when(() => getMessages(any())).thenAnswer((_) async => Right([mine]));
    when(() => watchMessages(any())).thenAnswer((_) => const Stream.empty());
    when(() => watchReactions(any())).thenAnswer((_) => const Stream.empty());
    when(() => sync.pending(any())).thenReturn(const []);
    when(() => sync.results).thenAnswer((_) => syncResults.stream);
    when(() => sync.enqueue(any(), any(), id: any(named: 'id')))
        .thenAnswer((_) async => 'queued');
  });

  tearDown(() => syncResults.close());

  /// Emits the outbox outcome for the queued send with [id].
  void flush(String id, SyncOutcome outcome) => syncResults.add(SyncResult(
        id: id,
        type: ChatSendHandler.kType,
        payload: const {},
        outcome: outcome,
      ));

  ChatBloc build() => ChatBloc(
        getMessages: getMessages,
        watchMessages: watchMessages,
        watchReactions: watchReactions,
        getCurrentUserId: getCurrentUserId,
        editMessage: editMessage,
        deleteMessage: deleteMessage,
        toggleReaction: toggleReaction,
        syncService: sync,
      );

  /// Starts a bloc with [mine] already loaded.
  Future<ChatBloc> started() async {
    final bloc = build();
    bloc.add(const ChatStarted());
    await bloc.stream.firstWhere((s) => s.status == ChatStatus.success);
    return bloc;
  }

  test('replying then sending queues the reply anchor and clears the composer',
      () async {
    final bloc = await started();

    bloc.add(ChatReplyStarted(mine));
    await bloc.stream.firstWhere((s) => s.replyingTo != null);

    bloc.add(const ChatSendRequested('a reply'));
    final state = await bloc.stream.firstWhere((s) => s.replyingTo == null);

    expect(state.messages.first.replyToId, mine.id);
    expect(state.messages.first.replyTo?.content, 'hello');
    final payload = verify(
      () => sync.enqueue(any(), captureAny(), id: any(named: 'id')),
    ).captured.single as Map<String, dynamic>;
    expect(payload['reply_to_id'], mine.id);
  });

  test('editing rewrites the message optimistically and marks it edited',
      () async {
    when(() => editMessage(any())).thenAnswer((_) async => const Right(unit));
    final bloc = await started();

    bloc.add(ChatEditStarted(mine));
    await bloc.stream.firstWhere((s) => s.editing != null);

    bloc.add(const ChatEditSubmitted('hello there'));
    final state = await bloc.stream.firstWhere((s) => s.editing == null);

    expect(state.messages.single.content, 'hello there');
    expect(state.messages.single.isEdited, isTrue);
    verify(() => editMessage(
        const EditMessageParams(id: 'm1', content: 'hello there'))).called(1);
  });

  test('a failed edit rolls the message back', () async {
    when(() => editMessage(any()))
        .thenAnswer((_) async => const Left(ServerFailure('nope')));
    final bloc = await started();

    bloc.add(ChatEditStarted(mine));
    await bloc.stream.firstWhere((s) => s.editing != null);
    bloc.add(const ChatEditSubmitted('hello there'));

    final state =
        await bloc.stream.firstWhere((s) => s.errorMessage == 'nope');
    expect(state.messages.single.content, 'hello');
  });

  test('deleting soft-deletes locally and drops the body', () async {
    when(() => deleteMessage(any())).thenAnswer((_) async => const Right(unit));
    final bloc = await started();

    bloc.add(const ChatDeleteRequested('m1'));
    final state = await bloc.stream.firstWhere((s) => s.messages.single.isDeleted);

    expect(state.messages.single.content, isEmpty);
    verify(() => deleteMessage('m1')).called(1);
  });

  test('toggling a reaction adds then removes the current user', () async {
    when(() => toggleReaction(any())).thenAnswer((_) async => const Right(unit));
    final bloc = await started();

    bloc.add(const ChatReactionToggled(messageId: 'm1', emoji: '👍'));
    var state = await bloc.stream
        .firstWhere((s) => s.messages.single.reactions.isNotEmpty);
    expect(state.messages.single.reactions['👍'], [uid]);

    bloc.add(const ChatReactionToggled(messageId: 'm1', emoji: '👍'));
    state = await bloc.stream
        .firstWhere((s) => s.messages.single.reactions.isEmpty);
    expect(state.messages.single.hasReaction('👍', uid), isFalse);

    verify(() => toggleReaction(any())).called(2);
  });

  test('a realtime reaction from another user merges in', () async {
    final bloc = await started();

    bloc.add(const ChatReactionChanged(ReactionChange(
      messageId: 'm1',
      userId: 'u2',
      emoji: '❤️',
      added: true,
    )));
    final state = await bloc.stream
        .firstWhere((s) => s.messages.single.reactions.isNotEmpty);

    expect(state.messages.single.reactions['❤️'], ['u2']);
  });

  test('a realtime edit refreshes the quote on messages replying to it',
      () async {
    final reply = ChatMessage(
      id: 'm2',
      senderId: 'u2',
      senderName: 'Them',
      content: 'sure',
      room: 'global',
      createdAt: DateTime(2026, 1, 1, 10),
      replyToId: 'm1',
      replyTo: const ReplyPreview(
        id: 'm1',
        senderName: 'Me',
        content: 'hello',
      ),
    );
    when(() => getMessages(any())).thenAnswer((_) async => Right([reply, mine]));
    final bloc = await started();

    bloc.add(ChatMessageChanged(ChatChange.update(
      mine.copyWith(content: 'hello there', editedAt: DateTime(2026, 1, 1, 11)),
    )));
    final state = await bloc.stream.firstWhere(
      (s) => s.messages.first.replyTo?.content == 'hello there',
    );

    expect(state.messages.last.content, 'hello there');
  });

  test('a send confirmed by the outbox clears the clock with no echo', () async {
    // The realtime echo can be missed entirely (the channel is still joining
    // when the insert lands). The outbox outcome must be enough on its own,
    // otherwise the message shows "sending" forever despite having been sent.
    final bloc = await started();

    bloc.add(const ChatSendRequested('hello world'));
    var state = await bloc.stream.firstWhere((s) => s.messages.length == 2);
    final queued = state.messages.first;
    expect(queued.pending, isTrue);

    flush(queued.id, SyncOutcome.success);
    state = await bloc.stream.firstWhere((s) => !s.messages.first.pending);

    expect(state.messages.first.failed, isFalse);
    expect(state.messages.first.content, 'hello world');
    // Still replaceable, so a late echo swaps in the server row.
    expect(state.messages.first.local, isTrue);
  });

  test('a late echo replaces the confirmed copy instead of duplicating it',
      () async {
    final bloc = await started();

    bloc.add(const ChatSendRequested('hello world'));
    var state = await bloc.stream.firstWhere((s) => s.messages.length == 2);
    flush(state.messages.first.id, SyncOutcome.success);
    await bloc.stream.firstWhere((s) => !s.messages.first.pending);

    bloc.add(ChatMessageChanged(ChatChange.insert(ChatMessage(
      id: 'server-1',
      senderId: uid,
      senderName: 'Me',
      content: 'hello world',
      room: 'global',
      createdAt: DateTime(2026, 1, 1, 12),
    ))));
    state = await bloc.stream.firstWhere(
      (s) => s.messages.any((m) => m.id == 'server-1'),
    );

    expect(state.messages.where((m) => m.content == 'hello world'), hasLength(1));
    expect(state.messages.length, 2);
  });

  test('a permanently failed send is still marked failed', () async {
    final bloc = await started();

    bloc.add(const ChatSendRequested('nope'));
    var state = await bloc.stream.firstWhere((s) => s.messages.length == 2);

    flush(state.messages.first.id, SyncOutcome.fail);
    state = await bloc.stream.firstWhere((s) => s.messages.first.failed);

    expect(state.messages.first.pending, isFalse);
  });
}
