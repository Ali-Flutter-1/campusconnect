part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.announcements = const [],
    this.events = const [],
    this.polls = const [],
    this.errorMessage,
  });

  final HomeStatus status;
  final List<Announcement> announcements;
  final List<Event> events;
  final List<Poll> polls;
  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    List<Announcement>? announcements,
    List<Event>? events,
    List<Poll>? polls,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      announcements: announcements ?? this.announcements,
      events: events ?? this.events,
      polls: polls ?? this.polls,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, announcements, events, polls, errorMessage];
}
