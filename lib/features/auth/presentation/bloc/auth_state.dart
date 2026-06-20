part of 'auth_bloc.dart';

/// Session status, used by the router redirect guard.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Overall session state.
  final AuthStatus status;

  /// The signed-in user (with role), when [status] is authenticated.
  final AppUser? user;

  /// True while a sign-in/up/out request is in flight (drives button spinners).
  final bool isSubmitting;

  /// Last auth error message, shown on the login/signup form.
  final String? errorMessage;

  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, isSubmitting, errorMessage];
}
