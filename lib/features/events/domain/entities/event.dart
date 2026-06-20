import 'package:equatable/equatable.dart';

/// A campus event. Mirrors the `events` table.
class Event extends Equatable {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String category;

  /// Optional banner image (Supabase Storage public URL).
  final String? imageUrl;

  @override
  List<Object?> get props =>
      [id, title, description, date, time, location, category, imageUrl];
}
