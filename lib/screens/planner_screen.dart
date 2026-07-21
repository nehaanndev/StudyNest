import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_state.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_station_banner.dart';
import 'planner_event_editor.dart';
import 'planner_plan_screen.dart';

part 'planner_agenda_widgets.dart';

// Category colours shared across the planner.
Color categoryColor(String category) => switch (category) {
  'Study' => const Color(0xFF5A9E6F),
  'Review' => const Color(0xFF5581C4),
  'Break' => const Color(0xFFD4836B),
  'Plan' => const Color(0xFF9B6EC4),
  _ => const Color(0xFF888888),
};

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// ─────────────────────────────────────────────────────────────────────────────

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  // Creates the state that preserves the user's selected calendar date.
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _selectedDay = DateTime.now();
  late DateTime _visibleMonth = DateTime(_selectedDay.year, _selectedDay.month);

  // Moves the overview backward by one calendar month.
  void _goToPreviousMonth() => setState(
    () => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1),
  );

  // Moves the overview forward by one calendar month.
  void _goToNextMonth() => setState(
    () => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1),
  );

  // Returns the overview and selected agenda to today's date.
  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDay = today;
      _visibleMonth = DateTime(today.year, today.month);
    });
  }

  // Opens the immersive timeline while keeping the selected overview date.
  Future<void> _openPlanMode() async {
    final lastDate = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute<DateTime>(
        builder: (_) => PlannerPlanScreen(
          initialDate: _selectedDay,
          onAnchorChanged: _syncPlanDate,
        ),
      ),
    );
    if (lastDate == null || !mounted) return;
    setState(() {
      _selectedDay = lastDate;
      _visibleMonth = DateTime(lastDate.year, lastDate.month);
    });
  }

  // Mirrors Plan Mode navigation so returning to Overview keeps its context.
  void _syncPlanDate(DateTime date) {
    if (!mounted) return;
    setState(() {
      _selectedDay = date;
      _visibleMonth = DateTime(date.year, date.month);
    });
  }

  // Confirms overview deletions before removing the selected agenda block.
  Future<void> _confirmDelete(String eventId) async {
    final state = StudyNestScope.read(context);
    final event = state.events.where((item) => item.id == eventId).firstOrNull;
    if (event == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this block?'),
        content: Text('“${event.title}” will be removed from your plan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    await state.deletePlannerEvent(eventId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Block deleted.')));
  }

  // Builds the month overview and the agenda for its selected date.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final selectedEvents = state.eventsForDay(_selectedDay);

    return CozyPage(
      title: 'Planner',
      subtitle: '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
      action: IconButton.filled(
        tooltip: 'Add block',
        onPressed: () =>
            showPlannerEventEditor(context, selectedDay: _selectedDay),
        icon: const Icon(Icons.add),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudyStationBanner(
            title: 'Calendar',
            detail: 'Tap any day to view or schedule study blocks.',
            metric: '${state.events.length} total blocks',
            icon: Icons.calendar_month,
            imagePath: screenBannerAsset('planner', state.selectedTheme.id),
            imageAlignment: Alignment.center,
          ),
          const SizedBox(height: 14),

          _PlannerModeSwitcher(onPlanSelected: _openPlanMode),
          const SizedBox(height: 14),

          // ── Month navigation header ──────────────────────────────────────
          _MonthHeader(
            visibleMonth: _visibleMonth,
            onPrev: _goToPreviousMonth,
            onNext: _goToNextMonth,
            onToday: _goToToday,
          ),
          const SizedBox(height: 8),

          // ── Full month grid ──────────────────────────────────────────────
          _MonthGrid(
            visibleMonth: _visibleMonth,
            selectedDay: _selectedDay,
            events: state.events,
            onDayTapped: (day) => setState(() {
              _selectedDay = day;
              _visibleMonth = DateTime(day.year, day.month);
            }),
            onAddForDay: (day) {
              setState(() => _selectedDay = day);
              showPlannerEventEditor(context, selectedDay: day);
            },
          ),
          const SizedBox(height: 16),

          // ── Selected-day agenda ──────────────────────────────────────────
          _AgendaSection(
            day: _selectedDay,
            events: selectedEvents,
            onEdit: (event) => showPlannerEventEditor(
              context,
              selectedDay: _selectedDay,
              event: event,
            ),
            onAdd: () =>
                showPlannerEventEditor(context, selectedDay: _selectedDay),
            onDelete: _confirmDelete,
          ),
        ],
      ),
    );
  }
}

class _PlannerModeSwitcher extends StatelessWidget {
  const _PlannerModeSwitcher({required this.onPlanSelected});

  final VoidCallback onPlanSelected;

  // Builds the explicit overview/plan zoom control above the calendar.
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment<String>(
          value: 'overview',
          icon: Icon(Icons.calendar_month_outlined, size: 18),
          label: Text('Overview'),
        ),
        ButtonSegment<String>(
          value: 'plan',
          icon: Icon(Icons.calendar_view_week_outlined, size: 18),
          label: Text('Plan mode'),
          tooltip: 'Open the detailed planning timeline',
        ),
      ],
      selected: const {'overview'},
      onSelectionChanged: (selection) {
        if (selection.contains('plan')) onPlanSelected();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month navigation header
// ─────────────────────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.visibleMonth,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime visibleMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  // Builds compact month navigation above the overview grid.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            '${_months[visibleMonth.month - 1]} ${visibleMonth.year}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: theme.text,
            ),
          ),
        ),
        TextButton(onPressed: onToday, child: const Text('Today')),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full month grid — Google Calendar style
// ─────────────────────────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDay,
    required this.events,
    required this.onDayTapped,
    required this.onAddForDay,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final List<PlannerEvent> events;
  final ValueChanged<DateTime> onDayTapped;
  final ValueChanged<DateTime> onAddForDay;

  // Builds a six-row month overview with compact event previews.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final today = DateTime.now();

    // First Monday on or before the 1st of the month
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month);
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - 1),
    );

    return CozyCard(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      child: Column(
        children: [
          // Day-of-week header row
          Row(
            children: [
              for (final h in _dayHeaders)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      h,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // 6-week grid
          for (var week = 0; week < 6; week++) ...[
            if (week > 0) const Divider(height: 1, thickness: 0.5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: _DayCell(
                      day: gridStart.add(Duration(days: week * 7 + d)),
                      visibleMonth: visibleMonth,
                      selectedDay: selectedDay,
                      today: today,
                      events:
                          events
                              .where(
                                (e) => isSameCalendarDay(
                                  e.startsAt,
                                  gridStart.add(Duration(days: week * 7 + d)),
                                ),
                              )
                              .toList()
                            ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
                      theme: theme,
                      onTap: onDayTapped,
                      onLongPress: onAddForDay,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.visibleMonth,
    required this.selectedDay,
    required this.today,
    required this.events,
    required this.theme,
    required this.onTap,
    required this.onLongPress,
  });

  final DateTime day;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final DateTime today;
  final List<PlannerEvent> events;
  final dynamic theme;
  final ValueChanged<DateTime> onTap;
  final ValueChanged<DateTime> onLongPress;

  // Reports whether this cell belongs to the actively displayed month.
  bool get _inMonth => day.month == visibleMonth.month;

  // Reports whether this cell owns the visible agenda selection.
  bool get _isSelected => isSameCalendarDay(day, selectedDay);

  // Reports whether this cell represents the current local date.
  bool get _isToday => isSameCalendarDay(day, today);

  // Builds one tappable day with at most two event previews.
  @override
  Widget build(BuildContext context) {
    // Show max 2 event chips; the rest become "+ N more"
    const maxVisible = 2;
    final overflow = (events.length - maxVisible).clamp(0, 99);
    final visible = events.take(maxVisible).toList();
    final dateState = [
      if (_isToday) 'today',
      if (_isSelected) 'selected',
    ].join(', ');
    final blockSummary = events.isEmpty
        ? 'No study blocks'
        : '${events.length} ${events.length == 1 ? 'study block' : 'study blocks'}: '
              '${events.map((event) => event.title).join(', ')}';

    return Semantics(
      button: true,
      selected: _isSelected,
      excludeSemantics: true,
      label:
          '${compactDate(day)}, ${day.year}${dateState.isEmpty ? '' : ', $dateState'}. '
          '$blockSummary.',
      hint: 'Activate to view this day. Long press to add a study block.',
      onTap: () => onTap(day),
      onLongPress: () => onLongPress(day),
      child: GestureDetector(
        onTap: () => onTap(day),
        onLongPress: () => onLongPress(day),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
          decoration: BoxDecoration(
            color: _isSelected
                ? theme.accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day number
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _isSelected
                        ? theme.accent
                        : _isToday
                        ? theme.accent.withValues(alpha: 0.20)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isSelected
                            ? Colors.white
                            : _inMonth
                            ? theme.text
                            : theme.muted.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Event chips
              for (final event in visible) _EventChip(event: event),
              if (overflow > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 1, left: 2),
                  child: Text(
                    '+ $overflow more',
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({required this.event});

  final PlannerEvent event;

  // Builds a single-line category-colored month event preview.
  @override
  Widget build(BuildContext context) {
    final color = categoryColor(event.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
