import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../models/study_models.dart';
import '../theme/study_theme.dart';
import '../utils/date_labels.dart';
import 'planner_plan_models.dart';

part 'planner_plan_event_card.dart';

/// Reports a planner event move while leaving persistence to the parent screen.
typedef PlannerEventMoveCallback =
    void Function(PlannerEvent event, DateTime startsAt, DateTime endsAt);

/// Reports a planner event resize while leaving persistence to the parent screen.
typedef PlannerEventResizeCallback =
    void Function(PlannerEvent event, DateTime startsAt, DateTime endsAt);

/// Returns the stable category color used throughout Plan Mode.
Color plannerCategoryColor(String category) {
  return switch (category) {
    'Study' => const Color(0xFF5A9E6F),
    'Review' => const Color(0xFF5581C4),
    'Break' => const Color(0xFFD4836B),
    'Plan' => const Color(0xFF9B6EC4),
    _ => const Color(0xFF888888),
  };
}

/// An interactive, scrollable time grid for day, three-day, and week planning.
class PlannerTimeline extends StatelessWidget {
  const PlannerTimeline({
    super.key,
    required this.anchorDate,
    required this.view,
    required this.events,
    required this.onEventTap,
    required this.onEventMoved,
    required this.onCreateAt,
    this.onEventResized,
    this.height = 620,
    this.startHour = 6,
    this.endHour = 23,
    this.minuteHeight = 1,
    this.snapMinutes = 15,
  }) : assert(startHour >= 0 && startHour < 24),
       assert(endHour > startHour && endHour <= 24),
       assert(minuteHeight > 0),
       assert(snapMinutes > 0 && snapMinutes <= 60);

  final DateTime anchorDate;
  final PlannerTimelineView view;
  final List<PlannerEvent> events;
  final ValueChanged<PlannerEvent> onEventTap;
  final PlannerEventMoveCallback onEventMoved;
  final PlannerEventResizeCallback? onEventResized;
  final ValueChanged<DateTime> onCreateAt;
  final double height;
  final int startHour;
  final int endHour;
  final double minuteHeight;
  final int snapMinutes;

  /// Builds a horizontally adaptive timeline with a vertically scrollable day.
  @override
  Widget build(BuildContext context) {
    final visualTheme = StudyNestScope.watch(context).selectedTheme;
    final days = plannerVisibleDays(anchorDate, view);
    final timelineHeight = (endHour - startHour) * 60 * minuteHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        const hourGutterWidth = 48.0;
        final availableDaysWidth = math.max(
          0.0,
          constraints.maxWidth - hourGutterWidth,
        );
        final minimumDayWidth = switch (view) {
          PlannerTimelineView.week => 112.0,
          PlannerTimelineView.threeDay => 104.0,
          PlannerTimelineView.day => availableDaysWidth,
        };
        final dayWidth = math.max(
          minimumDayWidth,
          availableDaysWidth / days.length,
        );
        final contentWidth = hourGutterWidth + dayWidth * days.length;

        return Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: visualTheme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: visualTheme.accent.withValues(alpha: 0.22),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              child: Column(
                children: [
                  _TimelineDayHeaders(
                    days: days,
                    dayWidth: dayWidth,
                    hourGutterWidth: hourGutterWidth,
                    visualTheme: visualTheme,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: timelineHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TimelineHourGutter(
                              width: hourGutterWidth,
                              startHour: startHour,
                              endHour: endHour,
                              minuteHeight: minuteHeight,
                              visualTheme: visualTheme,
                            ),
                            for (final day in days)
                              _TimelineDayColumn(
                                day: day,
                                width: dayWidth,
                                height: timelineHeight,
                                events: events,
                                startHour: startHour,
                                endHour: endHour,
                                minuteHeight: minuteHeight,
                                snapMinutes: snapMinutes,
                                visualTheme: visualTheme,
                                onEventTap: onEventTap,
                                onEventMoved: onEventMoved,
                                onEventResized: onEventResized,
                                onCreateAt: onCreateAt,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Renders the fixed day labels above the scrolling timeline body.
class _TimelineDayHeaders extends StatelessWidget {
  const _TimelineDayHeaders({
    required this.days,
    required this.dayWidth,
    required this.hourGutterWidth,
    required this.visualTheme,
  });

  final List<DateTime> days;
  final double dayWidth;
  final double hourGutterWidth;
  final StudyVisualTheme visualTheme;

  /// Builds one concise, tappable-looking header for each visible day.
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: visualTheme.surfaceAlt.withValues(alpha: 0.66),
        border: Border(
          bottom: BorderSide(color: visualTheme.accent.withValues(alpha: 0.16)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: hourGutterWidth),
          for (final day in days)
            SizedBox(
              width: dayWidth,
              child: _TimelineDayHeader(
                day: day,
                isToday: isSameCalendarDay(day, today),
                visualTheme: visualTheme,
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders one weekday and date with an unobtrusive today marker.
class _TimelineDayHeader extends StatelessWidget {
  const _TimelineDayHeader({
    required this.day,
    required this.isToday,
    required this.visualTheme,
  });

  final DateTime day;
  final bool isToday;
  final StudyVisualTheme visualTheme;

  /// Builds the weekday label and circular day number.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: compactDate(day),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            shortWeekday(day).toUpperCase(),
            style: TextStyle(
              color: isToday ? visualTheme.accent : visualTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? visualTheme.accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isToday ? Colors.white : visualTheme.text,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Labels full hours along the left edge of the timeline.
class _TimelineHourGutter extends StatelessWidget {
  const _TimelineHourGutter({
    required this.width,
    required this.startHour,
    required this.endHour,
    required this.minuteHeight,
    required this.visualTheme,
  });

  final double width;
  final int startHour;
  final int endHour;
  final double minuteHeight;
  final StudyVisualTheme visualTheme;

  /// Builds aligned labels that match the hourly grid rules.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var hour = startHour; hour <= endHour; hour++)
            Positioned(
              top: (hour - startHour) * 60 * minuteHeight - 7,
              right: 8,
              child: Text(
                _formatHour(hour),
                style: TextStyle(
                  color: visualTheme.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Formats a 24-hour integer as a compact 12-hour label.
  String _formatHour(int hour) {
    final normalized = hour % 24;
    final displayed = normalized % 12 == 0 ? 12 : normalized % 12;
    return '$displayed${normalized >= 12 ? 'p' : 'a'}';
  }
}

/// Owns pointer-to-time conversion and drag feedback for a single day.
class _TimelineDayColumn extends StatefulWidget {
  const _TimelineDayColumn({
    required this.day,
    required this.width,
    required this.height,
    required this.events,
    required this.startHour,
    required this.endHour,
    required this.minuteHeight,
    required this.snapMinutes,
    required this.visualTheme,
    required this.onEventTap,
    required this.onEventMoved,
    required this.onEventResized,
    required this.onCreateAt,
  });

  final DateTime day;
  final double width;
  final double height;
  final List<PlannerEvent> events;
  final int startHour;
  final int endHour;
  final double minuteHeight;
  final int snapMinutes;
  final StudyVisualTheme visualTheme;
  final ValueChanged<PlannerEvent> onEventTap;
  final PlannerEventMoveCallback onEventMoved;
  final PlannerEventResizeCallback? onEventResized;
  final ValueChanged<DateTime> onCreateAt;

  /// Creates the state that tracks the temporary drag destination.
  @override
  State<_TimelineDayColumn> createState() => _TimelineDayColumnState();
}

class _TimelineDayColumnState extends State<_TimelineDayColumn> {
  final GlobalKey _columnKey = GlobalKey();
  DateTime? _dragPreview;

  /// Converts a local vertical coordinate into a snapped timeline time.
  DateTime _timeAt(double localY) {
    final rawMinutes = (localY / widget.minuteHeight).clamp(
      0,
      (widget.endHour - widget.startHour) * 60 - widget.snapMinutes,
    );
    final rawTime = DateTime(
      widget.day.year,
      widget.day.month,
      widget.day.day,
      widget.startHour,
    ).add(Duration(minutes: rawMinutes.round()));
    return snapPlannerTime(rawTime, intervalMinutes: widget.snapMinutes);
  }

  /// Converts the global drag location to a local snapped time.
  DateTime? _timeAtGlobal(Offset globalOffset) {
    final box = _columnKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return _timeAt(box.globalToLocal(globalOffset).dy);
  }

  /// Updates the drop preview as a dragged block crosses the column.
  void _handleDragMove(DragTargetDetails<PlannerEvent> details) {
    final preview = _timeAtGlobal(details.offset);
    if (preview != _dragPreview) setState(() => _dragPreview = preview);
  }

  /// Clears the drop preview when a dragged block leaves the column.
  void _clearDragPreview(PlannerEvent? _) {
    if (_dragPreview != null) setState(() => _dragPreview = null);
  }

  /// Emits a duration-preserving event move after a successful drop.
  void _acceptDrag(DragTargetDetails<PlannerEvent> details) {
    final newStart = _timeAtGlobal(details.offset);
    setState(() => _dragPreview = null);
    if (newStart == null) return;
    final moved = movePlannerEvent(details.data, newStart);
    widget.onEventMoved(details.data, moved.startsAt, moved.endsAt);
  }

  /// Creates a new block at the empty slot tapped by the user.
  void _handleSlotTap(TapUpDetails details) {
    widget.onCreateAt(_timeAt(details.localPosition.dy));
  }

  /// Builds grid rules, positioned blocks, and drag/drop affordances.
  @override
  Widget build(BuildContext context) {
    final layouts = layoutPlannerEventsForDay(widget.events, widget.day);
    final preview = _dragPreview;

    return DragTarget<PlannerEvent>(
      onMove: _handleDragMove,
      onLeave: _clearDragPreview,
      onAcceptWithDetails: _acceptDrag,
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          key: _columnKey,
          behavior: HitTestBehavior.opaque,
          onTapUp: _handleSlotTap,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.visualTheme.accent.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                ..._buildGridRules(),
                ..._buildSlotSemantics(),
                if (preview != null) _buildDropPreview(preview),
                ...layouts.expand(_buildEvent),
                ..._buildCurrentTimeMarker(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds subtle half-hour rules with stronger rules at each full hour.
  List<Widget> _buildGridRules() {
    final slotCount = (widget.endHour - widget.startHour) * 2;
    return [
      for (var slot = 0; slot <= slotCount; slot++)
        Positioned(
          top: slot * 30 * widget.minuteHeight,
          left: 0,
          right: 0,
          child: Divider(
            height: 1,
            thickness: slot.isEven ? 0.8 : 0.4,
            color: widget.visualTheme.muted.withValues(
              alpha: slot.isEven ? 0.18 : 0.08,
            ),
          ),
        ),
    ];
  }

  /// Exposes half-hour creation targets with full date and time context.
  List<Widget> _buildSlotSemantics() {
    const slotMinutes = 30;
    final slotCount = (widget.endHour - widget.startHour) * 2;
    return [
      for (var slot = 0; slot < slotCount; slot++)
        Positioned(
          top: slot * slotMinutes * widget.minuteHeight,
          left: 0,
          right: 0,
          height: slotMinutes * widget.minuteHeight,
          child: Semantics(
            container: true,
            button: true,
            label:
                'Add block on ${compactDate(widget.day)}, ${widget.day.year} '
                'at ${clockTime(_slotTime(slot, slotMinutes))}',
            hint: 'Activate to open the study block editor.',
            onTap: () => widget.onCreateAt(_slotTime(slot, slotMinutes)),
            child: const SizedBox.expand(),
          ),
        ),
    ];
  }

  /// Converts an accessible slot index into its timeline date and time.
  DateTime _slotTime(int slot, int slotMinutes) {
    return DateTime(
      widget.day.year,
      widget.day.month,
      widget.day.day,
      widget.startHour,
    ).add(Duration(minutes: slot * slotMinutes));
  }

  /// Builds a highlighted target slot while an event is being dragged.
  Widget _buildDropPreview(DateTime preview) {
    final top = _minutesFromStart(preview) * widget.minuteHeight;
    return Positioned(
      top: top,
      left: 3,
      right: 3,
      height: widget.snapMinutes * widget.minuteHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.visualTheme.accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: widget.visualTheme.accent),
        ),
      ),
    );
  }

  /// Builds a positioned, collision-aware block for one event layout.
  Iterable<Widget> _buildEvent(PlannerEventLayout layout) sync* {
    final segment = layout.segment;
    final visibleStart = math.max(0, _minutesFromStart(segment.startsAt));
    final visibleEnd = math.min(
      (widget.endHour - widget.startHour) * 60,
      _minutesFromStart(segment.endsAt),
    );
    if (visibleEnd <= visibleStart) return;

    const gap = 3.0;
    final laneWidth = (widget.width - gap * 2) / layout.laneCount;
    yield Positioned(
      top: visibleStart * widget.minuteHeight,
      left: gap + laneWidth * layout.lane,
      width: laneWidth - 2,
      child: _TimelineEventCard(
        event: segment.event,
        height: math.max(
          28,
          (visibleEnd - visibleStart) * widget.minuteHeight - 2,
        ),
        minuteHeight: widget.minuteHeight,
        snapMinutes: widget.snapMinutes,
        visualTheme: widget.visualTheme,
        canResize: segment.includesEventEnd && widget.onEventResized != null,
        onTap: () => widget.onEventTap(segment.event),
        onResize: (newEnd) {
          final resized = resizePlannerEvent(segment.event, newEnd);
          widget.onEventResized?.call(
            segment.event,
            resized.startsAt,
            resized.endsAt,
          );
        },
      ),
    );
  }

  /// Builds today's live-time marker when it falls within visible hours.
  List<Widget> _buildCurrentTimeMarker() {
    final now = DateTime.now();
    if (!isSameCalendarDay(now, widget.day)) return const [];
    final minutes = _minutesFromStart(now);
    final totalMinutes = (widget.endHour - widget.startHour) * 60;
    if (minutes < 0 || minutes > totalMinutes) return const [];
    return [
      Positioned(
        top: minutes * widget.minuteHeight,
        left: 0,
        right: 0,
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFE05C5C),
                shape: BoxShape.circle,
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE05C5C), height: 1)),
          ],
        ),
      ),
    ];
  }

  /// Converts a time on this day to minutes after the visible start hour.
  int _minutesFromStart(DateTime time) {
    final visibleStart = DateTime(
      widget.day.year,
      widget.day.month,
      widget.day.day,
      widget.startHour,
    );
    return time.difference(visibleStart).inMinutes;
  }
}
