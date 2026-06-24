import 'package:equatable/equatable.dart';

/// A queued write operation that must be sent to the backend (now if online, or
/// later when connectivity returns). Persisted in Hive so it survives restarts.
class OutboxEntry extends Equatable {
  const OutboxEntry({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  /// Stable client id (also used to reconcile optimistic UI).
  final String id;

  /// Handler key, e.g. 'chat.send' or 'poll.vote'.
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  OutboxEntry copyWith({int? retryCount}) => OutboxEntry(
        id: id,
        type: type,
        payload: payload,
        createdAt: createdAt,
        retryCount: retryCount ?? this.retryCount,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };

  factory OutboxEntry.fromMap(Map<String, dynamic> m) => OutboxEntry(
        id: m['id'] as String,
        type: m['type'] as String,
        payload: Map<String, dynamic>.from(m['payload'] as Map),
        createdAt: DateTime.parse(m['created_at'] as String),
        retryCount: (m['retry_count'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, type, payload, createdAt, retryCount];
}
