import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/network_info.dart';
import 'core/services/cache_service.dart';
import 'core/services/storage_service.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up.dart';
import 'features/auth/domain/usecases/update_profile.dart';
import 'features/announcements/data/datasources/announcement_local_data_source.dart';
import 'features/announcements/data/datasources/announcement_remote_data_source.dart';
import 'features/announcements/data/repositories/announcement_repository_impl.dart';
import 'features/announcements/domain/repositories/announcement_repository.dart';
import 'features/announcements/domain/usecases/get_announcements.dart';
import 'features/announcements/domain/usecases/manage_announcements.dart';
import 'features/announcements/domain/usecases/toggle_interactions.dart';
import 'features/announcements/presentation/bloc/announcements_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/chat/data/datasources/chat_remote_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/domain/usecases/chat_usecases.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/complaints/data/datasources/complaint_remote_data_source.dart';
import 'features/complaints/data/repositories/complaint_repository_impl.dart';
import 'features/complaints/domain/repositories/complaint_repository.dart';
import 'features/complaints/domain/usecases/complaint_usecases.dart';
import 'features/complaints/presentation/bloc/complaints_bloc.dart';
import 'features/events/data/datasources/event_local_data_source.dart';
import 'features/events/data/datasources/event_remote_data_source.dart';
import 'features/events/data/repositories/event_repository_impl.dart';
import 'features/events/domain/repositories/event_repository.dart';
import 'features/events/domain/usecases/get_events.dart';
import 'features/events/domain/usecases/manage_events.dart';
import 'features/events/presentation/bloc/events_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/notices/data/datasources/notice_local_data_source.dart';
import 'features/notices/data/datasources/notice_remote_data_source.dart';
import 'features/notices/data/repositories/notice_repository_impl.dart';
import 'features/notices/domain/repositories/notice_repository.dart';
import 'features/notices/domain/usecases/notice_usecases.dart';
import 'features/notices/presentation/bloc/notices_bloc.dart';
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
  _registerChat();
  _registerNotices();
  _registerComplaints();
}

/// Cross-cutting infrastructure shared by every feature.
void _registerCore() {
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  getIt.registerLazySingleton<InternetConnection>(() => InternetConnection());
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<InternetConnection>()),
  );
  getIt.registerLazySingleton(() => StorageService(getIt<SupabaseClient>()));
  getIt.registerLazySingleton(
    () => CacheService(Hive.box(CacheService.boxName)),
  );
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
  getIt.registerLazySingleton(() => UpdateProfile(getIt<AuthRepository>()));

  // Presentation — the AuthBloc is app-wide (drives the router guard), so it is
  // a singleton rather than a per-screen factory.
  getIt.registerLazySingleton(
    () => AuthBloc(
      repository: getIt<AuthRepository>(),
      signIn: getIt<SignIn>(),
      signUp: getIt<SignUp>(),
      signOut: getIt<SignOut>(),
      getCurrentUser: getIt<GetCurrentUser>(),
      updateProfile: getIt<UpdateProfile>(),
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
  getIt.registerLazySingleton<AnnouncementLocalDataSource>(
    () => AnnouncementLocalDataSourceImpl(getIt<CacheService>()),
  );
  getIt.registerLazySingleton<AnnouncementRepository>(
    () => AnnouncementRepositoryImpl(
      getIt<AnnouncementRemoteDataSource>(),
      getIt<AnnouncementLocalDataSource>(),
      getIt<NetworkInfo>(),
    ),
  );

  // Domain
  getIt.registerLazySingleton(() => GetAnnouncements(getIt()));
  getIt.registerLazySingleton(() => GetCachedAnnouncements(getIt()));
  getIt.registerLazySingleton(() => GetInteractions(getIt()));
  getIt.registerLazySingleton(() => ToggleLike(getIt()));
  getIt.registerLazySingleton(() => ToggleBookmark(getIt()));
  getIt.registerLazySingleton(() => CreateAnnouncement(getIt()));
  getIt.registerLazySingleton(() => UpdateAnnouncement(getIt()));
  getIt.registerLazySingleton(() => DeleteAnnouncement(getIt()));

  // Presentation — per-screen, so a factory (fresh bloc each visit).
  getIt.registerFactory(
    () => AnnouncementsBloc(
      getAnnouncements: getIt(),
      getCachedAnnouncements: getIt(),
      getInteractions: getIt(),
      toggleLike: getIt(),
      toggleBookmark: getIt(),
      createAnnouncement: getIt(),
      updateAnnouncement: getIt(),
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
  getIt.registerLazySingleton<EventLocalDataSource>(
    () => EventLocalDataSourceImpl(getIt<CacheService>()),
  );
  getIt.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(
      getIt<EventRemoteDataSource>(),
      getIt<EventLocalDataSource>(),
      getIt<NetworkInfo>(),
    ),
  );

  // Domain
  getIt.registerLazySingleton(() => GetEvents(getIt()));
  getIt.registerLazySingleton(() => GetCachedEvents(getIt()));
  getIt.registerLazySingleton(() => CreateEvent(getIt()));
  getIt.registerLazySingleton(() => UpdateEvent(getIt()));
  getIt.registerLazySingleton(() => DeleteEvent(getIt()));

  // Presentation
  getIt.registerFactory(
    () => EventsBloc(
      getEvents: getIt(),
      getCachedEvents: getIt(),
      createEvent: getIt(),
      updateEvent: getIt(),
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
  getIt.registerLazySingleton(() => CreatePoll(getIt()));

  getIt.registerFactory(
    () => PollsBloc(
      getPolls: getIt(),
      getUserVotes: getIt(),
      castVote: getIt(),
      createPoll: getIt(),
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

void _registerChat() {
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(getIt<ChatRemoteDataSource>(), getIt<NetworkInfo>()),
  );

  getIt.registerLazySingleton(() => GetMessages(getIt()));
  getIt.registerLazySingleton(() => SendMessage(getIt()));
  getIt.registerLazySingleton(() => WatchMessages(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUserId(getIt()));

  getIt.registerFactory(
    () => ChatBloc(
      getMessages: getIt(),
      sendMessage: getIt(),
      watchMessages: getIt(),
      getCurrentUserId: getIt(),
    ),
  );
}

void _registerNotices() {
  getIt.registerLazySingleton<NoticeRemoteDataSource>(
    () => NoticeRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<NoticeLocalDataSource>(
    () => NoticeLocalDataSourceImpl(getIt<CacheService>()),
  );
  getIt.registerLazySingleton<NoticeRepository>(
    () => NoticeRepositoryImpl(
      getIt<NoticeRemoteDataSource>(),
      getIt<NoticeLocalDataSource>(),
      getIt<NetworkInfo>(),
    ),
  );

  getIt.registerLazySingleton(() => GetNotices(getIt()));
  getIt.registerLazySingleton(() => GetCachedNotices(getIt()));
  getIt.registerLazySingleton(() => CreateNotice(getIt()));
  getIt.registerLazySingleton(() => UpdateNotice(getIt()));
  getIt.registerLazySingleton(() => DeleteNotice(getIt()));

  getIt.registerFactory(
    () => NoticesBloc(
      getNotices: getIt(),
      getCachedNotices: getIt(),
      createNotice: getIt(),
      updateNotice: getIt(),
      deleteNotice: getIt(),
    ),
  );
}

void _registerComplaints() {
  getIt.registerLazySingleton<ComplaintRemoteDataSource>(
    () => ComplaintRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<ComplaintRepository>(
    () => ComplaintRepositoryImpl(
      getIt<ComplaintRemoteDataSource>(),
      getIt<NetworkInfo>(),
    ),
  );

  getIt.registerLazySingleton(() => GetMyComplaints(getIt()));
  getIt.registerLazySingleton(() => CreateComplaint(getIt()));

  getIt.registerFactory(
    () => ComplaintsBloc(
      getMyComplaints: getIt(),
      createComplaint: getIt(),
    ),
  );
}
