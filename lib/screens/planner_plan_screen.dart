import 'dart:async';

import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import 'planner_event_editor.dart';
import 'planner_plan_controls.dart';
import 'planner_plan_models.dart';
import 'planner_plan_timeline.dart';

/// Presents an immersive, responsive timeline for detailed calendar planning.
class PlannerPlanScreen extends StatefulWidget {
  const PlannerPlanScreen({
    super.key,
    required this.initialDate,
    this.onAnchorChanged,
  });

  final DateTime initialDate;
  final ValueChanged<DateTime>? onAnchorChanged;

  // Creates the state that retains the active range and focused date.
  @override
  State<PlannerPlanScreen> createState() => _PlannerPlanScreenState();
}

class _PlannerPlanScreenState extends State<PlannerPlanScreen> {
  static PlannerTimelineView? _rememberedView;

  late DateTime _anchorDate;
  late PlannerTimelineView _view;
  bool _didChooseInitialView = false;

  // Restores the overview date before responsive sizing chooses the first view.
  @override
  void initState() {
    super.initState();
    _anchorDate = plannerDateOnly(widget.initialDate);
    _view = _rememberedView ?? PlannerTimelineView.threeDay;
  }

  // Defaults first-time desktop visits to Week and phone visits to 3 days.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didChooseInitialView) return;
    _didChooseInitialView = true;
    if (_rememberedView == null && MediaQuery.sizeOf(context).width >= 900) {
      _view = PlannerTimelineView.week;
    }
  }

  // Builds a full-width planning canvas without the overview's 430px cap.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final visualTheme = state.selectedTheme;

    return Scaffold(
      backgroundColor: visualTheme.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              visualTheme.background,
              Color.alphaBlend(
                visualTheme.primary.withValues(alpha: 0.08),
                visualTheme.background,
              ),
              visualTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _PlanModeHeader(
                  subtitle: _rangeLabel(_anchorDate, _view),
                  onOverview: () => Navigator.pop(context, _anchorDate),
                  onAdd: () => _createAt(_suggestedStart(_anchorDate)),
                ),
                const SizedBox(height: 12),
                _PlanNavigationControls(
                  view: _view,
                  onViewChanged: _changeView,
                  onPrevious: () => _shiftRange(-1),
                  onToday: _goToToday,
                  onNext: () => _shiftRange(1),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 15,
                      color: visualTheme.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tap a time to add • Hold and drag blocks to reschedule',
                        style: TextStyle(
                          color: visualTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return PlannerTimeline(
                        anchorDate: _anchorDate,
                        view: _view,
                        events: state.events,
                        height: constraints.maxHeight,
                        onEventTap: _editEvent,
                        onCreateAt: _createAt,
                        onEventMoved: (event, startsAt, endsAt) {
                          unawaited(
                            _persistRange(
                              event,
                              startsAt,
                              endsAt,
                              confirmation: 'Block moved.',
                            ),
                          );
                        },
                        onEventResized: (event, startsAt, endsAt) {
                          unawaited(
                            _persistRange(
                              event,
                              startsAt,
                              endsAt,
                              confirmation: 'Block length updated.',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Switches timeline density while retaining the current anchor date.
  void _changeView(PlannerTimelineView view) {
    setState(() => _view = view);
    _rememberedView = view;
  }

  // Moves backward or forward by exactly one active timeline span.
  void _shiftRange(int direction) {
    _setAnchor(shiftPlannerAnchor(_anchorDate, _view, direction));
  }

  // Returns every Plan Mode range to the current date.
  void _goToToday() {
    _setAnchor(DateTime.now());
  }

  // Updates the focused date and keeps the underlying overview in sync.
  void _setAnchor(DateTime date) {
    final normalized = plannerDateOnly(date);
    setState(() => _anchorDate = normalized);
    widget.onAnchorChanged?.call(normalized);
  }

  // Opens the shared editor with the tapped timeline slot preselected.
  void _createAt(DateTime startsAt) {
    unawaited(
      showPlannerEventEditor(
        context,
        selectedDay: startsAt,
        suggestedStart: startsAt,
      ),
    );
  }

  // Opens the shared editor for an existing timeline block.
  void _editEvent(PlannerEvent event) {
    unawaited(
      showPlannerEventEditor(
        context,
        selectedDay: event.startsAt,
        event: event,
      ),
    );
  }

  // Persists a moved or resized block and offers a one-tap undo action.
  Future<void> _persistRange(
    PlannerEvent event,
    DateTime startsAt,
    DateTime endsAt, {
    required String confirmation,
  }) async {
    final state = StudyNestScope.read(context);
    await state.updatePlannerEvent(
      eventId: event.id,
      title: event.title,
      startsAt: startsAt,
      endsAt: endsAt,
      category: event.category,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(confirmation),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              unawaited(
                state.updatePlannerEvent(
                  eventId: event.id,
                  title: event.title,
                  startsAt: event.startsAt,
                  endsAt: event.endsAt,
                  category: event.category,
                ),
              );
            },
          ),
        ),
      );
  }
}

class _PlanModeHeader extends StatelessWidget {
  const _PlanModeHeader({
    required this.subtitle,
    required this.onOverview,
    required this.onAdd,
  });

  final String subtitle;
  final VoidCallback onOverview;
  final VoidCallback onAdd;

  // Builds a concise Plan Mode title row with clear escape and add actions.
  @override
  Widget build(BuildContext context) {
    final visualTheme = StudyNestScope.watch(context).selectedTheme;
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onOverview,
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: const Text('Overview'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan mode',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: visualTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton.filled(
          tooltip: 'Add block',
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _PlanNavigationControls extends StatelessWidget {
  const _PlanNavigationControls({
    required this.view,
    required this.onViewChanged,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  final PlannerTimelineView view;
  final ValueChanged<PlannerTimelineView> onViewChanged;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  // Arranges date navigation and range controls without phone-width overflow.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final navigation = _DateNavigation(
          onPrevious: onPrevious,
          onToday: onToday,
          onNext: onNext,
        );
        final switcher = PlannerViewSwitcher(
          value: view,
          onChanged: onViewChanged,
        );
        if (constraints.maxWidth < 700) {
          return Column(
            children: [navigation, const SizedBox(height: 8), switcher],
          );
        }
        return Row(
          children: [
            navigation,
            const Spacer(),
            SizedBox(width: 330, child: switcher),
          ],
        );
      },
    );
  }
}

class _DateNavigation extends StatelessWidget {
  const _DateNavigation({
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  // Builds 44px date navigation targets suitable for touch and mouse input.
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          tooltip: 'Previous date range',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(onPressed: onToday, child: const Text('Today')),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'Next date range',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

/// Formats the currently visible timeline span for the Plan Mode header.
String _rangeLabel(DateTime anchor, PlannerTimelineView view) {
  final days = plannerVisibleDays(anchor, view);
  if (days.length == 1) return compactDate(days.first);
  return '${compactDate(days.first)} – ${compactDate(days.last)}';
}

/// Suggests a convenient next block time while keeping it inside grid hours.
DateTime _suggestedStart(DateTime day) {
  final now = DateTime.now();
  final sameDay = isSameCalendarDay(day, now);
  final rawHour = sameDay ? now.hour + 1 : 9;
  final hour = rawHour.clamp(6, 22);
  return DateTime(day.year, day.month, day.day, hour);
}
