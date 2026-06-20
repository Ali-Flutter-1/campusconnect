import 'package:equatable/equatable.dart';

/// One choice in a poll.
class PollOption extends Equatable {
  const PollOption({required this.text, required this.count});

  final String text;
  final int count;

  PollOption copyWith({int? count}) =>
      PollOption(text: text, count: count ?? this.count);

  @override
  List<Object?> get props => [text, count];
}

/// A poll. Mirrors the `polls` table (`options` is a jsonb array).
class Poll extends Equatable {
  const Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.totalVotes,
    required this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  final DateTime createdAt;
  final DateTime? expiresAt;

  /// Percentage (0–100) for [option], guarding divide-by-zero.
  double percentFor(PollOption option) =>
      totalVotes == 0 ? 0 : (option.count / totalVotes) * 100;

  @override
  List<Object?> get props =>
      [id, question, options, totalVotes, createdAt, expiresAt];
}
