import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

/// Data-layer representation of [AppUser]. Knows how to (de)serialize the
/// Supabase `profiles` row.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.role,
    super.fullName,
    super.avatarUrl,
    super.course,
    super.department,
    super.year,
  });

  /// Builds a model from a `profiles` row. [authEmail] is used as a fallback
  /// when the row has no email column populated.
  factory AppUserModel.fromProfile(
    Map<String, dynamic> row, {
    String? authEmail,
  }) {
    return AppUserModel(
      id: row['id'] as String,
      email: (row['email'] as String?) ?? authEmail ?? '',
      role: UserRole.fromString(row['role'] as String?),
      fullName: row['full_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      course: row['course'] as String?,
      department: row['department'] as String?,
      year: row['year'] as String?,
    );
  }

  /// The row inserted when a profile is first created (sign-up).
  ///
  /// `role` is intentionally omitted — that column is locked server-side (see
  /// migration 0002) and defaults to 'student'; promotion happens only via the
  /// `redeem_admin_code` RPC.
  Map<String, dynamic> toInsert() => {
        'id': id,
        'email': email,
        'full_name': fullName,
      };
}
