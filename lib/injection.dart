import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/network_info.dart';
import 'core/services/storage_service.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up.dart';
import 'features/announcements/data/datasources/announcement_remote_data_source.dart';
import 'features/announcements/data/repositories/announcement_repository_impl.dart';
import 'features/announcements/domain/repositories/announcement_repository.dart';
import 'features/announcements/domain/usecases/get_announcements.dart';
import 'features/announcements/domain/usecases/manage_announcements.dart';
import 'features/announcements/domain/usecases/toggle_interactions.dart';
import 'features/announcements/presentation/bloc/announcements_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/events/data/datasources/event_remote_data_source.dart';
import 'features/events/data/repositories/event_repository_impl.dart';
import 'features/events/domain/repositories/event_repository.dart';
import 'features/events/domain/usecases/get_events.dart';
import 'features/events/domain/usecases/manage_events.dart';
import 'features/events/presentation/bloc/events_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/polls/data/datasources/poll_remote_data_source.dart';
import 'features/polls/data/repositories/poll_repository_impl.dart';
import 'features/polls/domain/repositories/poll_repository.dart';
import 'features/polls/domain/usecases/poll_usecases.dart';
import 'features/polls/presentation/bloc/polls_bloc.dart';

/// Global service locator.
///
/// Dependencies are registered manually (no codegen) in [configureDependencies],
/// called once during app bootstrap. Each feature adds its own private
/// `_register<Feature>()` helper here as it is implemented, keeping wiring in a
/// single, readable place.
final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  _registerCore();
  _registerAuth();
  _registerAnnouncements();
  _registerEvents();
  _registerPolls();
  _registerHome();
}

/// Cross-cutting infrastructure shared by every feature.
void _registerCore() {
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  getIt.registerLazySingleton<InternetConnection>(() => InternetConnection());
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<InternetConnection>()),
  );
  getIt.registerLazySingleton(() => StorageService(getIt<SupabaseClient>()));
}

void _registerAuth() {
  // Data
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>(), getIt<NetworkInfo>()),
  );

  // Domain
  getIt.registerLazySingleton(() => SignIn(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignUp(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignOut(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetCurrentUser(getIt<AuthRepository>()));

  // Presentation — the AuthBloc is app-wide (drives the router guard), so it is
  // a singleton rather than a per-screen factory.
  getIt.registerLazySingleton(
    () => AuthBloc(
      repository: getIt<AuthRepository>(),
      signIn: getIt<SignIn>(),
      signUp: getIt<SignUp>(),
      signOut: getIt<SignOut>(),
      getCurrentUser: getIt<GetCurrentUser>(),
    ),
  );
}

void _registerAnnouncements() {
  // Data
  getIt.registerLazySingleton<AnnouncementRemoteDataSource>(
    () => AnnouncementRemoteDataSourceImpl(
      getIt<SupabaseClient>(),
      getIt<StorageService>(),
    ),
  );
  getIt.registerLazySingleton<AnnouncementRepository>(
    () => AnnouncementRepositoryImpl(
      getIt<AnnouncementRemoteDataSource>(),
      getIt<NetworkInfo>(),
    ),
  );

  // Domain
  getIt.registerLazySingleton(() => GetAnnouncements(getIt()));
  getIt.registerLazySingleton(() => GetInteractions(getIt()));
  getIt.registerLazySingleton(() => ToggleLike(getIt()));
  getIt.registerLazySingleton(() => ToggleBookmark(getIt()));
  getIt.registerLazySingleton(() => CreateAnnouncement(getIt()));
  getIt.registerLazySingleton(() => DeleteAnnouncement(getIt()));

  // Presentation — per-screen, so a factory (fresh bloc each visit).
  getIt.registerFactory(
    () => AnnouncementsBloc(
      getAnnouncements: getIt(),
      getInteractions: getIt(),
      toggleLike: getIt(),
      toggleBookmark: getIt(),
      createAnnouncement: getIt(),
      deleteAnnouncement: getIt(),
    ),
  );
}

void _registerEvents() {
  // Data
  getIt.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(
      getIt<SupabaseClient>(),
      getIt<StorageService>(),
    ),
  );
  getIt.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(getIt<EventRemoteDataSource>(), getIt<NetworkInfo>()),
  );

  // Domain
  getIt.registerLazySingleton(() => GetEvents(getIt()));
  getIt.registerLazySingleton(() => CreateEvent(getIt()));
  getIt.registerLazySingleton(() => DeleteEvent(getIt()));

  // Presentation
  getIt.registerFactory(
    () => EventsBloc(
      getEvents: getIt(),
      createEvent: getIt(),
      deleteEvent: getIt(),
    ),
  );
}

void _registerPolls() {
  getIt.registerLazySingleton<PollRemoteDataSource>(
    () => PollRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<PollRepository>(
    () => PollRepositoryImpl(getIt<PollRemoteDataSource>(), getIt<NetworkInfo>()),
  );

  getIt.registerLazySingleton(() => GetPolls(getIt()));
  getIt.registerLazySingleton(() => GetUserVotes(getIt()));
  getIt.registerLazySingleton(() => CastVote(getIt()));

  getIt.registerFactory(
    () => PollsBloc(
      getPolls: getIt(),
      getUserVotes: getIt(),
      castVote: getIt(),
    ),
  );
}

void _registerHome() {
  // Home reuses the announcements/events/polls read use cases already
  // registered above — it only needs its own bloc.
  getIt.registerFactory(
    () => HomeBloc(
      getAnnouncements: getIt(),
      getEvents: getIt(),
      getPolls: getIt(),
    ),
  );
}
