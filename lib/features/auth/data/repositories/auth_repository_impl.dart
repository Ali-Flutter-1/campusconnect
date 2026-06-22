import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._networkInfo);

  final AuthRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Stream<AppUser?> get authStateChanges => _remote.authStateChanges();

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      return Right(await _remote.getCurrentUser());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) =>
      _guarded(() => _remote.signIn(email: email, password: password));

  @override
  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? adminCode,
  }) =>
      _guarded(
        () => _remote.signUp(
          email: email,
          password: password,
          fullName: fullName,
          adminCode: adminCode,
        ),
      );

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remote.signOut();
      return const Right(unit);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> updateProfile({
    String? fullName,
    String? course,
    String? department,
    String? year,
  }) =>
      _guarded(() => _remote.updateProfile(
            fullName: fullName,
            course: course,
            department: department,
            year: year,
          ));

  /// Shared online-check + exception→failure mapping for auth actions.
  Future<Either<Failure, AppUser>> _guarded(
    Future<AppUser> Function() action,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
