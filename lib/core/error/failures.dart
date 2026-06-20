import 'package:equatable/equatable.dart';

/// Domain-level representation of something that went wrong.
///
/// Repositories return `Either<Failure, T>` (via dartz) so callers handle the
/// error path explicitly instead of relying on thrown exceptions.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// A remote/server-side error (Supabase request failed, RPC error, etc.).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong. Please try again.']);
}

/// No (or unusable) network connection.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// A local cache failure.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to read local data.']);
}

/// The action requires the user to be signed in.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Please sign in to continue.']);
}
