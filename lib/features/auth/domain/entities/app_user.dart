import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// The authenticated user plus their profile data, as consumed by the app.
///
/// Combines Supabase Auth identity (`id`, `email`) with the `profiles` row
/// (name, role, course, etc.). Pure domain object — no JSON here (see
/// `AppUserModel` in the data layer).
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarUrl,
    this.course,
    this.department,
    this.year,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? fullName;
  final String? avatarUrl;
  final String? course;
  final String? department;
  final String? year;

  bool get isAdmin => role.isAdmin;

  /// Display name with a sensible fallback.
  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : 'Student';

  @override
  List<Object?> get props =>
      [id, email, role, fullName, avatarUrl, course, department, year];
}
