import '../../domain/entities/event.dart';

/// Data-layer [Event] with Supabase (de)serialization.
class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.date,
    required super.time,
    required super.location,
    required super.category,
    super.imageUrl,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      time: (json['time'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'general',
      imageUrl: json['image_url'] as String?,
    );
  }

  /// Full row shape (snake_case) for caching; round-trips through [fromJson].
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toUtc().toIso8601String(),
        'time': time,
        'location': location,
        'category': category,
        'image_url': imageUrl,
      };

  /// Fields written when an admin creates an event.
  static Map<String, dynamic> toInsert({
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String location,
    required String category,
    String? imageUrl,
  }) =>
      {
        'title': title,
        'description': description,
        'date': date.toIso8601String().split('T').first,
        'time': time,
        'location': location,
        'category': category,
        'image_url': ?imageUrl,
      };
}
