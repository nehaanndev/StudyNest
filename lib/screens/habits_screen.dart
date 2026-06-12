import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../models/study_models.dart';
import '../widgets/cozy_widgets.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  static const _emojiOptions = ['✅', '📚', '💧', '🏃', '🎨', '🎵', '📝', '🧘'];

  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final habits = state.habits;

    return CozyPage(
      title: 'Habits',
      subtitle: 'Build streaks, one day at a time.',
      action: IconButton.filled(
        tooltip: 'Add habit',
        onPressed: () => _showAddHabitDialog(context),
        icon: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          // Motivational banner
          CozyCard(
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keep your streak going!',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${habits.length} habits tracked',
                        style: TextStyle(
                          color: StudyNestScope.watch(
                            context,
                          ).selectedTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (habits.isEmpty)
            const EmptyState(
              icon: '🌱',
              title: 'No habits yet',
              body: 'Add your first habit and start building a daily routine.',
            )
          else
            Column(
              children: [
                for (final habit in habits) ...[
                  _HabitCard(habit: habit),
                  const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _showAddHabitDialog(BuildContext context) async {
    final state = StudyNestScope.read(context);
    final nameController = TextEditingController();
    var selectedEmoji = '✅';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('New Habit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Habit name'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pick an emoji',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final emoji in _emojiOptions)
                        GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedEmoji = emoji),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedEmoji == emoji
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 2,
                              ),
                              color: selectedEmoji == emoji
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    await state.addHabit(name: name, emoji: selectedEmoji);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit});

  final StudyHabit habit;

  List<DateTime> _weekDays() {
    final now = DateTime.now();
    // Start from Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final days = _weekDays();
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GestureDetector(
      onLongPress: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete "${habit.name}"?'),
            content: const Text('This will remove the habit and all its data.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await StudyNestScope.read(context).deleteHabit(habit.id);
        }
      },
      child: CozyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(habit.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    habit.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '🔥 ${habit.streak}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < 7; i++) ...[
                  _DayCircle(
                    label: dayLabels[i],
                    completed: habit.isCompletedOn(days[i]),
                    accentColor: theme.accent,
                    onTap: () => StudyNestScope.read(
                      context,
                    ).toggleHabitDay(habit.id, days[i]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.label,
    required this.completed,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool completed;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: completed ? accentColor : Colors.transparent,
          border: Border.all(
            color: completed ? accentColor : accentColor.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: completed ? Colors.white : accentColor,
            ),
          ),
        ),
      ),
    );
  }
}
