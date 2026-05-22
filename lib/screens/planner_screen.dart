import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_station_banner.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  // Creates the planner state that tracks the selected calendar day.
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _selectedDay = DateTime.now();

  // Builds the weekly planner with event creation controls.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final selectedEvents = state.eventsForDay(_selectedDay);

    return CozyPage(
      title: 'Planner',
      subtitle: 'Block your study time like a soft Google Calendar.',
      action: IconButton.filled(
        tooltip: 'Add schedule block',
        onPressed: () => _showEventDialog(context),
        icon: const Icon(Icons.add),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudyStationBanner(
            title: 'Planner wall',
            detail: 'Turn your day into study blocks, reviews, and breaks.',
            metric: '${selectedEvents.length} blocks',
            icon: Icons.calendar_month,
            imagePath: screenBannerAsset('planner', state.selectedTheme.id),
            imageAlignment: Alignment.center,
          ),
          const SizedBox(height: 14),
          _WeekStrip(
            selectedDay: _selectedDay,
            onSelected: (day) => setState(() => _selectedDay = day),
          ),
          SectionHeader(
            title: compactDate(_selectedDay),
            trailing: Text('${selectedEvents.length} blocks'),
          ),
          if (selectedEvents.isEmpty)
            const EmptyState(
              icon: '📅',
              title: 'No blocks here',
              body:
                  'Add a study block, review slot, or break to shape the day.',
            )
          else
            for (final event in selectedEvents) ...[
              _PlannerEventCard(event: event),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  // Opens the event creation dialog and saves a new planner block when valid.
  Future<void> _showEventDialog(BuildContext context) async {
    final state = StudyNestScope.read(context);
    final titleController = TextEditingController();
    var category = 'Study';
    var startsAt = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      DateTime.now().hour + 1,
    );
    var endsAt = startsAt.add(const Duration(hours: 1));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('New schedule block'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'Study', child: Text('Study')),
                        DropdownMenuItem(
                          value: 'Review',
                          child: Text('Review'),
                        ),
                        DropdownMenuItem(value: 'Break', child: Text('Break')),
                        DropdownMenuItem(value: 'Plan', child: Text('Plan')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text(timeRange(startsAt, endsAt)),
                      subtitle: Text(compactDate(startsAt)),
                      onTap: () async {
                        final pickedStart = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(startsAt),
                        );
                        if (pickedStart == null) {
                          return;
                        }
                        if (!dialogContext.mounted) {
                          return;
                        }
                        final pickedEnd = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(endsAt),
                        );
                        if (pickedEnd == null) {
                          return;
                        }
                        setDialogState(() {
                          startsAt = DateTime(
                            _selectedDay.year,
                            _selectedDay.month,
                            _selectedDay.day,
                            pickedStart.hour,
                            pickedStart.minute,
                          );
                          endsAt = DateTime(
                            _selectedDay.year,
                            _selectedDay.month,
                            _selectedDay.day,
                            pickedEnd.hour,
                            pickedEnd.minute,
                          );
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
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      return;
                    }
                    final result = await state.addPlannerEvent(
                      title: title,
                      startsAt: startsAt,
                      endsAt: endsAt,
                      category: category,
                    );
                    if (!dialogContext.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(result.message)));
                    if (!result.applied) {
                      return;
                    }
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selectedDay, required this.onSelected});

  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;

  // Builds the horizontally arranged seven-day calendar selector.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return Row(
      children: [
        for (var index = 0; index < 7; index++) ...[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 6 ? 0 : 8),
              child: _DayChip(
                day: startOfWeek.add(Duration(days: index)),
                selected: isSameCalendarDay(
                  selectedDay,
                  startOfWeek.add(Duration(days: index)),
                ),
                themeColor: theme.accent,
                onSelected: onSelected,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.themeColor,
    required this.onSelected,
  });

  final DateTime day;
  final bool selected;
  final Color themeColor;
  final ValueChanged<DateTime> onSelected;

  // Builds a single selectable day chip.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onSelected(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? themeColor.withValues(alpha: 0.22) : theme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? themeColor.withValues(alpha: 0.70)
                : theme.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Text(
              shortWeekday(day),
              style: TextStyle(
                color: selected ? theme.text : theme.muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dayNumber(day),
              style: TextStyle(
                color: selected ? theme.text : theme.muted,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerEventCard extends StatelessWidget {
  const _PlannerEventCard({required this.event});

  final PlannerEvent event;

  // Builds a calendar block card with a delete action.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;

    return CozyCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              clockTime(event.startsAt).replaceFirst(' ', '\n'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, height: 1.3),
            ),
          ),
          Container(
            width: 3,
            height: 82,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: theme.accent,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  timeRange(event.startsAt, event.endsAt),
                  style: TextStyle(color: theme.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CozyTag(label: event.category, icon: Icons.local_cafe),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PlannerThumbnail(category: event.category),
          IconButton(
            tooltip: 'Delete block',
            onPressed: () => state.deletePlannerEvent(event.id),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _PlannerThumbnail extends StatelessWidget {
  const _PlannerThumbnail({required this.category});

  final String category;

  // Builds the small illustrated thumbnail on a planner event card.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final icon = switch (category) {
      'Review' => Icons.menu_book,
      'Break' => Icons.local_cafe,
      'Plan' => Icons.edit_calendar,
      _ => Icons.energy_savings_leaf,
    };

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: theme.surfaceAlt.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 8,
            top: 7,
            child: Icon(
              Icons.wb_sunny,
              color: theme.accent.withValues(alpha: 0.28),
              size: 38,
            ),
          ),
          Icon(icon, color: theme.primary, size: 28),
        ],
      ),
    );
  }
}
