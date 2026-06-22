import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Updates the current user's editable profile fields.
class UpdateProfile implements UseCase<AppUser, UpdateProfileParams> {
  const UpdateProfile(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(UpdateProfileParams params) =>
      _repository.updateProfile(
        fullName: params.fullName,
        course: params.course,
        department: params.department,
        year: params.year,
      );
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({
    this.fullName,
    this.course,
    this.department,
    this.year,
  });

  final String? fullName;
  final String? course;
  final String? department;
  final String? year;

  @override
  List<Object?> get props => [fullName, course, department, year];
}
