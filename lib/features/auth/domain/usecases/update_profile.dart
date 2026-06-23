import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Updates the current user's editable profile fields (and optional avatar).
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
        avatarBytes: params.avatarBytes,
        avatarExt: params.avatarExt,
      );
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({
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
