import 'package:connect/core/usecases/usecase.dart';
import 'package:connect/features/announcements/domain/entities/announcement.dart';
import 'package:connect/features/announcements/domain/usecases/get_announcements.dart';
import 'package:connect/features/announcements/domain/usecases/manage_announcements.dart';
import 'package:connect/features/announcements/domain/usecases/toggle_interactions.dart';
import 'package:connect/features/announcements/presentation/bloc/announcements_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetAnnouncements extends Mock implements GetAnnouncements {}

class _MockGetCachedAnnouncements extends Mock
    implements GetCachedAnnouncements {}

class _MockGetInteractions extends Mock implements GetInteractions {}

class _MockToggleLike extends Mock implements ToggleLike {}

class _MockToggleBookmark extends Mock implements ToggleBookmark {}

class _MockCreateAnnouncement extends Mock implements CreateAnnouncement {}

class _MockUpdateAnnouncement extends Mock implements UpdateAnnouncement {}

class _MockDeleteAnnouncement extends Mock implements DeleteAnnouncement {}

void main() {
  late _MockGetAnnouncements getAnnouncements;
  late _MockGetCachedAnnouncements getCachedAnnouncements;
  late _MockGetInteractions getInteractions;
  late _MockToggleLike toggleLike;
  late _MockToggleBookmark toggleBookmark;
  late _MockCreateAnnouncement createAnnouncement;
  late _MockUpdateAnnouncement updateAnnouncement;
  late _MockDeleteAnnouncement deleteAnnouncement;

  final announcement = Announcement(
    id: 'x1',
    title: 'Hi',
    content: 'Body',
    author: 'Admin',
    category: 'general',
    createdAt: DateTime(2026, 1, 1),
    likes: 5,
    bookmarks: 0,
  );

  setUpAll(() {
    registerFallbackValue(
      const ToggleInteractionParams(announcementId: '', active: false),
    );
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetAnnouncementsParams());
  });

  setUp(() {
    getAnnouncements = _MockGetAnnouncements();
    getCachedAnnouncements = _MockGetCachedAnnouncements();
    getInteractions = _MockGetInteractions();
    toggleLike = _MockToggleLike();
    toggleBookmark = _MockToggleBookmark();
    createAnnouncement = _MockCreateAnnouncement();
    updateAnnouncement = _MockUpdateAnnouncement();
    deleteAnnouncement = _MockDeleteAnnouncement();
    when(() => getCachedAnnouncements()).thenReturn(const []);
  });

  AnnouncementsBloc build() => AnnouncementsBloc(
        getAnnouncements: getAnnouncements,
        getCachedAnnouncements: getCachedAnnouncements,
        getInteractions: getInteractions,
        toggleLike: toggleLike,
        toggleBookmark: toggleBookmark,
        createAnnouncement: createAnnouncement,
        updateAnnouncement: updateAnnouncement,
        deleteAnnouncement: deleteAnnouncement,
      );

  test('load emits loading then success with data', () async {
    when(() => getAnnouncements(any()))
        .thenAnswer((_) async => Right([announcement]));
    when(() => getInteractions(any())).thenAnswer(
      (_) async => const Right(AnnouncementInteractions()),
    );
    final bloc = build();

    expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<AnnouncementsState>(
            (s) => s.status == AnnouncementsStatus.loading),
        predicate<AnnouncementsState>((s) =>
            s.status == AnnouncementsStatus.success &&
            s.announcements.length == 1),
      ]),
    );

    bloc.add(const AnnouncementsLoadRequested());
  });

  test('like toggle optimistically increments count and marks liked', () async {
    when(() => getAnnouncements(any()))
        .thenAnswer((_) async => Right([announcement]));
    when(() => getInteractions(any())).thenAnswer(
      (_) async => const Right(AnnouncementInteractions()),
    );
    when(() => toggleLike(any())).thenAnswer((_) async => const Right(unit));
    final bloc = build();

    bloc.add(const AnnouncementsLoadRequested());
    await bloc.stream.firstWhere(
      (s) => s.status == AnnouncementsStatus.success,
    );

    bloc.add(const AnnouncementLikeToggled('x1'));

    final next = await bloc.stream.firstWhere((s) => s.isLiked('x1'));
    expect(next.announcements.single.likes, 6);
    verify(() => toggleLike(any())).called(1);
  });
}
