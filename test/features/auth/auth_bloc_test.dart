import 'package:connect/core/error/failures.dart';
import 'package:connect/core/usecases/usecase.dart';
import 'package:connect/features/auth/domain/entities/app_user.dart';
import 'package:connect/features/auth/domain/entities/user_role.dart';
import 'package:connect/features/auth/domain/repositories/auth_repository.dart';
import 'package:connect/features/auth/domain/usecases/get_current_user.dart';
import 'package:connect/features/auth/domain/usecases/sign_in.dart';
import 'package:connect/features/auth/domain/usecases/sign_out.dart';
import 'package:connect/features/auth/domain/usecases/sign_up.dart';
import 'package:connect/features/auth/domain/usecases/update_profile.dart';
import 'package:connect/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetCurrentUser extends Mock implements GetCurrentUser {}

class _MockUpdateProfile extends Mock implements UpdateProfile {}

void main() {
  late _MockAuthRepository repository;
  late _MockSignIn signIn;
  late _MockSignUp signUp;
  late _MockSignOut signOut;
  late _MockGetCurrentUser getCurrentUser;
  late _MockUpdateProfile updateProfile;

  const admin = AppUser(id: 'a1', email: 'a@x.io', role: UserRole.admin);

  setUpAll(() {
    registerFallbackValue(const SignInParams(email: '', password: ''));
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    repository = _MockAuthRepository();
    signIn = _MockSignIn();
    signUp = _MockSignUp();
    signOut = _MockSignOut();
    getCurrentUser = _MockGetCurrentUser();
    updateProfile = _MockUpdateProfile();
    when(() => repository.authStateChanges)
        .thenAnswer((_) => const Stream<AppUser?>.empty());
  });

  AuthBloc build() => AuthBloc(
        repository: repository,
        signIn: signIn,
        signUp: signUp,
        signOut: signOut,
        getCurrentUser: getCurrentUser,
        updateProfile: updateProfile,
      );

  test('subscription with no session resolves to unauthenticated', () async {
    when(() => getCurrentUser(any()))
        .thenAnswer((_) async => const Right<Failure, AppUser?>(null));
    final bloc = build();

    expectLater(
      bloc.stream,
      emits(predicate<AuthState>(
          (s) => s.status == AuthStatus.unauthenticated)),
    );

    bloc.add(const AuthSubscriptionRequested());
  });

  test('successful sign-in emits submitting then authenticated admin',
      () async {
    when(() => getCurrentUser(any()))
        .thenAnswer((_) async => const Right<Failure, AppUser?>(null));
    when(() => signIn(any()))
        .thenAnswer((_) async => const Right<Failure, AppUser>(admin));
    final bloc = build();

    expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<AuthState>((s) => s.isSubmitting),
        predicate<AuthState>((s) =>
            !s.isSubmitting &&
            s.status == AuthStatus.authenticated &&
            s.isAdmin),
      ]),
    );

    bloc.add(const AuthSignInRequested(email: 'a@x.io', password: 'secret'));
  });

  test('failed sign-in emits submitting then an error message', () async {
    when(() => signIn(any()))
        .thenAnswer((_) async => const Left(AuthFailure('Bad credentials')));
    final bloc = build();

    expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<AuthState>((s) => s.isSubmitting),
        predicate<AuthState>(
            (s) => !s.isSubmitting && s.errorMessage == 'Bad credentials'),
      ]),
    );

    bloc.add(const AuthSignInRequested(email: 'a@x.io', password: 'nope'));
  });
}
