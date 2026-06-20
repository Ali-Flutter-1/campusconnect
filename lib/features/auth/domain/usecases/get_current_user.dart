import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Returns the current session's user, or `null` if signed out.
class GetCurrentUser implements UseCase<AppUser?, NoParams> {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser?>> call(NoParams params) =>
      _repository.getCurrentUser();
}
