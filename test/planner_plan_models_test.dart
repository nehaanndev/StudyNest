import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studynest/app/study_nest_scope.dart';
import 'package:studynest/app/study_nest_state.dart';
import 'package:studynest/models/study_models.dart';
import 'package:studynest/screens/planner_plan_controls.dart';
import 'package:studynest/screens/planner_plan_models.dart';
import 'package:studynest/screens/planner_plan_timeline.dart';

// Verifies Plan Mode date math, event layout, and compact range controls.
void main() {
  group('planner date ranges', () {
    test('week view starts on Monday and contains seven dates', () {
      final days = plannerVisibleDays(
        DateTime(2026, 7, 23, 14),
        PlannerTimelineView.week,
      );

      expect(days.first, DateTime(2026, 7, 20));
      expect(days.last, DateTime(2026, 7, 26));
      expect(days, hasLength(7));
    });

    test('day and three-day views start from the anchor date', () {
      final anchor = DateTime(2026, 7, 23, 14, 45);

      expect(plannerVisibleDays(anchor, PlannerTimelineView.day), [
        DateTime(2026, 7, 23),
      ]);
      expect(plannerVisibleDays(anchor, PlannerTimelineView.threeDay), [
        DateTime(2026, 7, 23),
        DateTime(2026, 7, 24),
        DateTime(2026, 7, 25),
      ]);
    });

    test('range navigation advances by the active view size', () {
      final anchor = DateTime(2026, 7, 23);

      expect(
        shiftPlannerAnchor(anchor, PlannerTimelineView.week, 1),
        DateTime(2026, 7, 30),
      );
      expect(
        shiftPlannerAnchor(anchor, PlannerTimelineView.threeDay, -1),
        DateTime(2026, 7, 20),
      );
    });
  });

  group('planner event transformations', () {
    test('snaps times to the nearest fifteen minute interval', () {
      expect(
        snapPlannerTime(DateTime(2026, 7, 23, 9, 7)),
        DateTime(2026, 7, 23, 9),
      );
      expect(
        snapPlannerTime(DateTime(2026, 7, 23, 9, 8)),
        DateTime(2026, 7, 23, 9, 15),
      );
    });

    test('moving an event preserves its original duration', () {
      final event = _event('move', 9, 0, 10, 30);
      final moved = movePlannerEvent(event, DateTime(2026, 7, 24, 13, 15));

      expect(moved.startsAt, DateTime(2026, 7, 24, 13, 15));
      expect(moved.endsAt, DateTime(2026, 7, 24, 14, 45));
    });

    test('resizing enforces the minimum planning interval', () {
      final event = _event('resize', 9, 0, 10, 0);
      final resized = resizePlannerEvent(event, DateTime(2026, 7, 23, 8));

      expect(resized.endsAt, DateTime(2026, 7, 23, 9, 15));
    });
  });

  group('planner collision layout', () {
    test('places connected overlaps into two reusable lanes', () {
      final events = [
        _event('first', 9, 0, 10, 0),
        _event('second', 9, 30, 10, 30),
        _event('third', 10, 0, 11, 0),
      ];
      final layouts = layoutPlannerEventsForDay(events, DateTime(2026, 7, 23));

      expect(layouts.map((layout) => layout.lane), [0, 1, 0]);
      expect(layouts.map((layout) => layout.laneCount), [2, 2, 2]);
    });

    test('clips overnight events to the requested day', () {
      final overnight = PlannerEvent(
        id: 'overnight',
        title: 'Late review',
        startsAt: DateTime(2026, 7, 22, 23, 30),
        endsAt: DateTime(2026, 7, 23, 1),
        category: 'Review',
      );
      final segments = plannerEventSegmentsForDay([
        overnight,
      ], DateTime(2026, 7, 23));

      expect(segments, hasLength(1));
      expect(segments.single.startsAt, DateTime(2026, 7, 23));
      expect(segments.single.endsAt, DateTime(2026, 7, 23, 1));
      expect(segments.single.includesEventStart, isFalse);
      expect(segments.single.includesEventEnd, isTrue);
    });
  });

  testWidgets('view switcher exposes and selects all three ranges', (
    tester,
  ) async {
    var selected = PlannerTimelineView.week;
    await tester.pumpWidget(
      StudyNestScope(
        state: StudyNestState.preview(),
        child: MaterialApp(
          home: Scaffold(
            body: PlannerViewSwitcher(
              value: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Week'), findsOneWidget);
    expect(find.text('3 days'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
    await tester.tap(find.text('3 days'));

    expect(selected, PlannerTimelineView.threeDay);
  });

  testWidgets('timeline fits a narrow phone and maps empty taps to slots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    DateTime? createdAt;
    final anchor = DateTime(2026, 7, 23);

    await tester.pumpWidget(
      StudyNestScope(
        state: StudyNestState.preview(),
        child: MaterialApp(
          home: Scaffold(
            body: PlannerTimeline(
              anchorDate: anchor,
              view: PlannerTimelineView.day,
              events: [_event('Deep work', 10, 0, 11, 0)],
              height: 620,
              onEventTap: (_) {},
              onEventMoved: (_, _, _) {},
              onCreateAt: (value) => createdAt = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Deep work'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final topLeft = tester.getTopLeft(find.byType(PlannerTimeline));
    await tester.tapAt(topLeft + const Offset(80, 62 + 120));

    expect(createdAt, DateTime(2026, 7, 23, 8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long press dragging reschedules and preserves duration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final event = _event('Drag block', 10, 0, 11, 0);
    DateTime? movedStart;
    DateTime? movedEnd;

    await tester.pumpWidget(
      StudyNestScope(
        state: StudyNestState.preview(),
        child: MaterialApp(
          home: Scaffold(
            body: PlannerTimeline(
              anchorDate: DateTime(2026, 7, 23),
              view: PlannerTimelineView.day,
              events: [event],
              height: 700,
              onEventTap: (_) {},
              onEventMoved: (_, startsAt, endsAt) {
                movedStart = startsAt;
                movedEnd = endsAt;
              },
              onCreateAt: (_) {},
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Drag block')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 75));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(movedStart, isNotNull);
    expect(movedStart!.isAfter(event.startsAt), isTrue);
    expect(movedStart!.minute % 15, 0);
    expect(movedEnd!.difference(movedStart!), const Duration(hours: 1));
  });
}

// Creates a same-day planner event with concise hour and minute inputs.
PlannerEvent _event(
  String id,
  int startHour,
  int startMinute,
  int endHour,
  int endMinute,
) {
  return PlannerEvent(
    id: id,
    title: id,
    startsAt: DateTime(2026, 7, 23, startHour, startMinute),
    endsAt: DateTime(2026, 7, 23, endHour, endMinute),
    category: 'Study',
  );
}
