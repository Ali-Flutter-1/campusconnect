import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Registers a new user. New accounts default to the `student` role
/// (enforced server-side); admins are promoted in the database.
class SignUp implements UseCase<AppUser, SignUpParams> {
  const SignUp(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(SignUpParams params) {
    return _repository.signUp(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
      adminCode: params.adminCode,
    );
  }
}

class SignUpParams extends Equatable {
  const SignUpParams({
    required this.email,
    required this.password,
    required this.fullName,
    this.adminCode,
  });

  final String email;
  final String password;
  final String fullName;

  /// Optional secret phrase; when correct the server promotes the new account
  /// to admin (see `redeem_admin_code`).
  final String? adminCode;

  @override
  List<Object?> get props => [email, password, fullName, adminCode];
}
