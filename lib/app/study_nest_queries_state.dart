part of 'study_nest_state.dart';

extension StudyNestQueriesState on StudyNestState {
  // Returns only the events that happen on a specific calendar day.
  List<PlannerEvent> eventsForDay(DateTime day) {
    final matches = _events.where((event) {
      return event.startsAt.year == day.year &&
          event.startsAt.month == day.month &&
          event.startsAt.day == day.day;
    }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return List.unmodifiable(matches);
  }

  // Returns the next few open tasks for the dashboard.
  List<StudyTask> upcomingTasks({int limit = 3}) {
    final openTasks = _tasks.where((task) => task.completedAt == null).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return List.unmodifiable(openTasks.take(limit));
  }
}
