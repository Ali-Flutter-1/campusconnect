import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

/// Contract for authentication + current-user access. Implemented in the data
/// layer by `AuthRepositoryImpl`.
abstract interface class AuthRepository {
  /// Emits the current [AppUser] on sign-in and `null` on sign-out, so the
  /// router/UI can react to session changes.
  Stream<AppUser?> get authStateChanges;

  /// The currently signed-in user, or `null` if there is no session.
  Future<Either<Failure, AppUser?>> getCurrentUser();

  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? adminCode,
  });

  Future<Either<Failure, Unit>> signOut();

  /// Updates the signed-in user's profile fields (and optionally uploads a new
  /// avatar) and returns the fresh user.
  Future<Either<Failure, AppUser>> updateProfile({
    String? fullName,
    String? course,
    String? department,
    String? year,
    Uint8List? avatarBytes,
    String? avatarExt,
  });
}
