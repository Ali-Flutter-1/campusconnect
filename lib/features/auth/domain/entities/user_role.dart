/// Application roles. Stored as the `role` column on the `profiles` table.
///
/// - [student] (default): consumes content, can like/bookmark/RSVP/vote/chat.
/// - [admin]: everything a student can, plus create/edit/delete announcements,
///   events, polls and notices.
enum UserRole {
  student,
  admin;

  /// Parses the DB string (defaults to [student] for unknown/null values).
  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.student,
    );
  }

  bool get isAdmin => this == UserRole.admin;
}
