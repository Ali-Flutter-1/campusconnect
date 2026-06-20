import '../../domain/entities/poll.dart';

/// Data-layer [Poll] with Supabase (de)serialization of the `options` jsonb.
class PollModel extends Poll {
  const PollModel({
    required super.id,
    required super.question,
    required super.options,
    required super.totalVotes,
    required super.createdAt,
    super.expiresAt,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? []);
    return PollModel(
      id: json['id'] as String,
      question: (json['question'] as String?) ?? '',
      options: rawOptions
          .whereType<Map<String, dynamic>>()
          .map((o) => PollOption(
                text: (o['text'] as String?) ?? '',
                count: (o['count'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
      totalVotes: (json['total_votes'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '')?.toLocal(),
    );
  }
}
