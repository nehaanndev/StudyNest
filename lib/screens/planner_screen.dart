import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_station_banner.dart';

// Category colours shared across the planner.
Color categoryColor(String category) => switch (category) {
      'Study' => const Color(0xFF5A9E6F),
      'Review' => const Color(0xFF5581C4),
      'Break' => const Color(0xFFD4836B),
      'Plan' => const Color(0xFF9B6EC4),
      _ => const Color(0xFF888888),
    };

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// ─────────────────────────────────────────────────────────────────────────────

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _selectedDay = DateTime.now();
  late DateTime _visibleMonth =
      DateTime(_selectedDay.year, _selectedDay.month);

  void _goToPreviousMonth() => setState(
      () => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1));

  void _goToNextMonth() => setState(
      () => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1));

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDay = today;
      _visibleMonth = DateTime(today.year, today.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final selectedEvents = state.eventsForDay(_selectedDay);

    return CozyPage(
      title: 'Planner',
      subtitle: '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
      action: IconButton.filled(
        tooltip: 'Add block',
        onPressed: () => _showEventDialog(context),
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
            onDayTapped: (day) => setState(() => _selectedDay = day),
            onAddForDay: (day) {
              setState(() => _selectedDay = day);
              _showEventDialog(context);
            },
          ),
          const SizedBox(height: 16),

          // ── Selected-day agenda ──────────────────────────────────────────
          _AgendaSection(
            day: _selectedDay,
            events: selectedEvents,
            onEdit: (event) => _showEventDialog(context, event: event),
            onAdd: () => _showEventDialog(context),
            onDelete: (id) => state.deletePlannerEvent(id),
          ),
        ],
      ),
    );
  }

  Future<void> _showEventDialog(BuildContext context,
      {PlannerEvent? event}) async {
    final state = StudyNestScope.read(context);
    final titleController = TextEditingController(text: event?.title ?? '');
    var category = event?.category ?? 'Study';
    var startsAt = event?.startsAt ??
        DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
          DateTime.now().hour + 1,
        );
    var endsAt = event?.endsAt ?? startsAt.add(const Duration(hours: 1));

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(event == null ? 'New block' : 'Edit block'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'Study', child: Text('Study')),
                    DropdownMenuItem(value: 'Review', child: Text('Review')),
                    DropdownMenuItem(value: 'Break', child: Text('Break')),
                    DropdownMenuItem(value: 'Plan', child: Text('Plan')),
                  ],
                  onChanged: (v) {
                    if (v != null) set(() => category = v);
                  },
                ),
                const SizedBox(height: 12),
                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, size: 20),
                  title: Text(compactDate(startsAt)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                      initialDate: startsAt,
                    );
                    if (d == null) return;
                    set(() {
                      startsAt = DateTime(d.year, d.month, d.day,
                          startsAt.hour, startsAt.minute);
                      endsAt = DateTime(d.year, d.month, d.day, endsAt.hour,
                          endsAt.minute);
                      if (!endsAt.isAfter(startsAt)) {
                        endsAt = startsAt.add(const Duration(hours: 1));
                      }
                    });
                  },
                ),
                // Time range
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule, size: 20),
                  title: Text(timeRange(startsAt, endsAt)),
                  onTap: () async {
                    if (!ctx.mounted) return;
                    final ps = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(startsAt),
                    );
                    if (ps == null || !ctx.mounted) return;
                    final pe = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(endsAt),
                    );
                    if (pe == null) return;
                    set(() {
                      startsAt = DateTime(startsAt.year, startsAt.month,
                          startsAt.day, ps.hour, ps.minute);
                      endsAt = DateTime(endsAt.year, endsAt.month, endsAt.day,
                          pe.hour, pe.minute);
                      if (!endsAt.isAfter(startsAt)) {
                        endsAt = startsAt.add(const Duration(hours: 1));
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final result = event == null
                    ? await state.addPlannerEvent(
                        title: title,
                        startsAt: startsAt,
                        endsAt: endsAt,
                        category: category)
                    : null;
                if (event != null) {
                  await state.updatePlannerEvent(
                      eventId: event.id,
                      title: title,
                      startsAt: startsAt,
                      endsAt: endsAt,
                      category: category);
                }
                if (!ctx.mounted) return;
                final msg = result?.message ?? 'Block updated.';
                ScaffoldMessenger.of(ctx)
                    .showSnackBar(SnackBar(content: Text(msg)));
                if (result != null && !result.applied) return;
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(event == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
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
        TextButton(
          onPressed: onToday,
          child: const Text('Today'),
        ),
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

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final today = DateTime.now();

    // First Monday on or before the 1st of the month
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month);
    final gridStart =
        firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));

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
                      events: events
                          .where((e) => isSameCalendarDay(
                              e.startsAt,
                              gridStart.add(Duration(days: week * 7 + d))))
                          .toList()
                        ..sort((a, b) =>
                            a.startsAt.compareTo(b.startsAt)),
                      theme: theme,
                      onTap: onDayTapped,
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
  });

  final DateTime day;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final DateTime today;
  final List<PlannerEvent> events;
  final dynamic theme;
  final ValueChanged<DateTime> onTap;

  bool get _inMonth => day.month == visibleMonth.month;
  bool get _isSelected => isSameCalendarDay(day, selectedDay);
  bool get _isToday => isSameCalendarDay(day, today);

  @override
  Widget build(BuildContext context) {
    // Show max 2 event chips; the rest become "+ N more"
    const maxVisible = 2;
    final overflow = (events.length - maxVisible).clamp(0, 99);
    final visible = events.take(maxVisible).toList();

    return GestureDetector(
      onTap: () => onTap(day),
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
            for (final event in visible)
              _EventChip(event: event),
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
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({required this.event});

  final PlannerEvent event;

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

// ─────────────────────────────────────────────────────────────────────────────
// Selected-day agenda
// ─────────────────────────────────────────────────────────────────────────────

class _AgendaSection extends StatelessWidget {
  const _AgendaSection({
    required this.day,
    required this.events,
    required this.onEdit,
    required this.onAdd,
    required this.onDelete,
  });

  final DateTime day;
  final List<PlannerEvent> events;
  final ValueChanged<PlannerEvent> onEdit;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Expanded(
              child: Text(
                compactDate(day),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${events.length} ${events.length == 1 ? 'block' : 'blocks'}',
              style: TextStyle(color: theme.muted, fontSize: 13),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Add block on this day',
              visualDensity: VisualDensity.compact,
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          EmptyState(
            icon: '📅',
            title: 'Nothing scheduled',
            body: 'Tap + to add a study block, review, or break.',
          )
        else
          for (final event in events) ...[
            _AgendaRow(
              event: event,
              onEdit: () => onEdit(event),
              onDelete: () => onDelete(event.id),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final PlannerEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final color = categoryColor(event.category);

    return CozyCard(
      padding: EdgeInsets.zero,
      onTap: onEdit,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left colour bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            // Time
            SizedBox(
              width: 58,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  clockTime(event.startsAt).replaceAll(' ', '\n'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: theme.text,
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 0, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: theme.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeRange(event.startsAt, event.endsAt),
                      style: TextStyle(color: theme.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 7),
                    _CategoryChip(category: event.category, color: color),
                  ],
                ),
              ),
            ),
            // Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined,
                      size: 18, color: theme.muted),
                ),
                IconButton(
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: theme.muted),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.color});

  final String category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
