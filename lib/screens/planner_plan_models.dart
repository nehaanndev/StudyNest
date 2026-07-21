import '../models/study_models.dart';

/// Calendar ranges available while the planner is in focused Plan Mode.
enum PlannerTimelineView {
  week,
  threeDay,
  day;

  /// Returns the number of calendar days displayed by this view.
  int get dayCount => switch (this) {
    PlannerTimelineView.week => 7,
    PlannerTimelineView.threeDay => 3,
    PlannerTimelineView.day => 1,
  };

  /// Returns the concise label used by Plan Mode controls.
  String get label => switch (this) {
    PlannerTimelineView.week => 'Week',
    PlannerTimelineView.threeDay => '3 days',
    PlannerTimelineView.day => 'Day',
  };
}

/// A day-clipped portion of a planner event used by a timeline column.
class PlannerEventSegment {
  const PlannerEventSegment({
    required this.event,
    required this.startsAt,
    required this.endsAt,
    required this.includesEventStart,
    required this.includesEventEnd,
  });

  final PlannerEvent event;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool includesEventStart;
  final bool includesEventEnd;
}

/// A positioned event segment with a lane for overlapping calendar blocks.
class PlannerEventLayout {
  const PlannerEventLayout({
    required this.segment,
    required this.lane,
    required this.laneCount,
  });

  final PlannerEventSegment segment;
  final int lane;
  final int laneCount;
}

/// Removes the clock component while retaining the date's local time zone.
DateTime plannerDateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Finds the Monday that begins the calendar week containing [date].
DateTime plannerStartOfWeek(DateTime date) {
  final day = plannerDateOnly(date);
  return DateTime(day.year, day.month, day.day - (day.weekday - 1));
}

/// Builds the ordered dates visible for a timeline view and anchor date.
List<DateTime> plannerVisibleDays(DateTime anchor, PlannerTimelineView view) {
  final start = view == PlannerTimelineView.week
      ? plannerStartOfWeek(anchor)
      : plannerDateOnly(anchor);
  return List.unmodifiable(
    List.generate(
      view.dayCount,
      (index) => DateTime(start.year, start.month, start.day + index),
    ),
  );
}

/// Moves an anchor by one visible range while preserving calendar dates.
DateTime shiftPlannerAnchor(
  DateTime anchor,
  PlannerTimelineView view,
  int direction,
) {
  final normalizedDirection = direction.sign;
  final distance = view.dayCount * normalizedDirection;
  return DateTime(anchor.year, anchor.month, anchor.day + distance);
}

/// Snaps a time to the nearest planning interval on the same calendar day.
DateTime snapPlannerTime(DateTime time, {int intervalMinutes = 15}) {
  assert(intervalMinutes > 0 && intervalMinutes <= 60);
  final minutes = time.hour * 60 + time.minute;
  final snappedMinutes = (minutes / intervalMinutes).round() * intervalMinutes;
  return DateTime(
    time.year,
    time.month,
    time.day,
  ).add(Duration(minutes: snappedMinutes));
}

/// Returns a copy of [event] moved to [newStart] with its duration preserved.
PlannerEvent movePlannerEvent(PlannerEvent event, DateTime newStart) {
  final duration = event.endsAt.difference(event.startsAt);
  final safeDuration = duration > Duration.zero
      ? duration
      : const Duration(minutes: 30);
  return event.copyWith(startsAt: newStart, endsAt: newStart.add(safeDuration));
}

/// Returns a resized event while enforcing the supplied minimum duration.
PlannerEvent resizePlannerEvent(
  PlannerEvent event,
  DateTime newEnd, {
  Duration minimumDuration = const Duration(minutes: 15),
}) {
  final earliestEnd = event.startsAt.add(minimumDuration);
  return event.copyWith(
    endsAt: newEnd.isBefore(earliestEnd) ? earliestEnd : newEnd,
  );
}

/// Clips all events intersecting [day] into segments that fit that day.
List<PlannerEventSegment> plannerEventSegmentsForDay(
  Iterable<PlannerEvent> events,
  DateTime day,
) {
  final dayStart = plannerDateOnly(day);
  final dayEnd = DateTime(dayStart.year, dayStart.month, dayStart.day + 1);
  final segments = <PlannerEventSegment>[];

  for (final event in events) {
    if (!event.endsAt.isAfter(event.startsAt) ||
        !event.startsAt.isBefore(dayEnd) ||
        !event.endsAt.isAfter(dayStart)) {
      continue;
    }
    segments.add(
      PlannerEventSegment(
        event: event,
        startsAt: event.startsAt.isBefore(dayStart) ? dayStart : event.startsAt,
        endsAt: event.endsAt.isAfter(dayEnd) ? dayEnd : event.endsAt,
        includesEventStart: !event.startsAt.isBefore(dayStart),
        includesEventEnd: !event.endsAt.isAfter(dayEnd),
      ),
    );
  }

  segments.sort((first, second) {
    final timeOrder = first.startsAt.compareTo(second.startsAt);
    return timeOrder != 0 ? timeOrder : first.endsAt.compareTo(second.endsAt);
  });
  return List.unmodifiable(segments);
}

/// Assigns stable horizontal lanes to events that overlap within [day].
List<PlannerEventLayout> layoutPlannerEventsForDay(
  Iterable<PlannerEvent> events,
  DateTime day,
) {
  final segments = plannerEventSegmentsForDay(events, day);
  final layouts = <PlannerEventLayout>[];
  var groupStart = 0;

  while (groupStart < segments.length) {
    var groupEnd = groupStart + 1;
    var latestEnd = segments[groupStart].endsAt;
    while (groupEnd < segments.length &&
        segments[groupEnd].startsAt.isBefore(latestEnd)) {
      if (segments[groupEnd].endsAt.isAfter(latestEnd)) {
        latestEnd = segments[groupEnd].endsAt;
      }
      groupEnd++;
    }

    final laneEnds = <DateTime>[];
    final assignments = <int>[];
    for (var index = groupStart; index < groupEnd; index++) {
      final segment = segments[index];
      final openLane = laneEnds.indexWhere(
        (laneEnd) => !laneEnd.isAfter(segment.startsAt),
      );
      final lane = openLane == -1 ? laneEnds.length : openLane;
      if (openLane == -1) {
        laneEnds.add(segment.endsAt);
      } else {
        laneEnds[lane] = segment.endsAt;
      }
      assignments.add(lane);
    }

    for (var index = groupStart; index < groupEnd; index++) {
      layouts.add(
        PlannerEventLayout(
          segment: segments[index],
          lane: assignments[index - groupStart],
          laneCount: laneEnds.length,
        ),
      );
    }
    groupStart = groupEnd;
  }

  return List.unmodifiable(layouts);
}
