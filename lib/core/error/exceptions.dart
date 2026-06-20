/// Low-level exceptions thrown by the data layer (data sources).
///
/// These are caught inside repository implementations and converted into
/// [Failure]s so the domain/presentation layers never deal with raw exceptions.
library;

/// Thrown when a remote (Supabase) call fails or returns an error.
class ServerException implements Exception {
  const ServerException([this.message = 'An unexpected server error occurred.']);

  final String message;

  @override
  String toString() => 'ServerException: $message';
}

/// Thrown when a local cache read/write fails.
class CacheException implements Exception {
  const CacheException([this.message = 'A cache error occurred.']);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

/// Thrown when an action requires an authenticated user but none is present.
class AuthException implements Exception {
  const AuthException([this.message = 'Authentication required.']);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
