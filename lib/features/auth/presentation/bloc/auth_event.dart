part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to Supabase session changes (dispatched once at startup).
class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

/// Internal: the session user changed (sign-in/out elsewhere, token refresh).
class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final AppUser? user;

  @override
  List<Object?> get props => [user];
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.fullName,
    required this.email,
    required this.password,
    this.adminCode,
  });
  final String fullName;
  final String email;
  final String password;

  /// Secret phrase entered when "Admin" is selected on the signup form.
  final String? adminCode;

  @override
  List<Object?> get props => [fullName, email, password, adminCode];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Update editable profile fields (name, course, department, year) and/or the
/// avatar image.
class AuthProfileUpdateRequested extends AuthEvent {
  const AuthProfileUpdateRequested({
    this.fullName,
    this.course,
    this.department,
    this.year,
    this.avatarBytes,
    this.avatarExt,
  });

  final String? fullName;
  final String? course;
  final String? department;
  final String? year;
  final Uint8List? avatarBytes;
  final String? avatarExt;

  @override
  List<Object?> get props =>
      [fullName, course, department, year, avatarBytes, avatarExt];
}
