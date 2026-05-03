import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Builds the StudyNest dashboard with focus goal, stats, and today's plan.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final todayEvents = state.eventsForDay(DateTime.now()).take(3).toList();
    final upcomingTasks = state.upcomingTasks();

    return CozyPage(
      title: 'StudyNest',
      subtitle: '${theme.emoji} ${theme.description}',
      action: CoinBadge(coins: state.coinBalance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CozyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Current focus goal',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    CozyTag(
                      label: '+${state.sessionGoal.reward}',
                      icon: Icons.savings,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.sessionGoal.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            state.sessionGoal.isCompleteOn(DateTime.now())
                            ? null
                            : () => _completeSessionGoal(context),
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          state.sessionGoal.isCompleteOn(DateTime.now())
                              ? 'Completed today'
                              : 'Complete goal',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Edit goal',
                      onPressed: () => _showSessionGoalDialog(context),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Open tasks',
                  value: state.openTaskCount.toString(),
                  icon: Icons.checklist,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Completed',
                  value: state.completedTaskCount.toString(),
                  icon: Icons.done_all,
                ),
              ),
            ],
          ),
          SectionHeader(
            title: "Today's schedule",
            trailing: Text(compactDate(DateTime.now())),
          ),
          if (todayEvents.isEmpty)
            const EmptyState(
              icon: '🗓️',
              title: 'No study blocks yet',
              body: 'Add a calendar block to make the day feel organized.',
            )
          else
            for (final event in todayEvents) ...[
              _EventPreview(
                eventTitle: event.title,
                eventTime: timeRange(event.startsAt, event.endsAt),
              ),
              const SizedBox(height: 10),
            ],
          const SectionHeader(title: 'Next tasks'),
          if (upcomingTasks.isEmpty)
            const EmptyState(
              icon: '✨',
              title: 'Everything is clear',
              body: 'Add a new task when you are ready for the next goal.',
            )
          else
            for (final task in upcomingTasks) ...[
              CozyCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Due ${compactDate(task.dueAt)}',
                            style: TextStyle(color: theme.muted),
                          ),
                        ],
                      ),
                    ),
                    CozyTag(label: '+${task.reward}', icon: Icons.savings),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  // Completes the session goal and shows the awarded coin result.
  Future<void> _completeSessionGoal(BuildContext context) async {
    final state = StudyNestScope.read(context);
    final awarded = await state.completeSessionGoal();
    if (!context.mounted) {
      return;
    }
    final message = awarded > 0
        ? 'Nice focus. You earned $awarded coins.'
        : 'That goal is already complete today.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Opens a dialog for changing the current session goal.
  Future<void> _showSessionGoalDialog(BuildContext context) async {
    final state = StudyNestScope.read(context);
    final titleController = TextEditingController(
      text: state.sessionGoal.title,
    );
    final rewardController = TextEditingController(
      text: state.sessionGoal.reward.toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set focus goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Goal'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rewardController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Coin reward'),
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
                final title = titleController.text.trim();
                final reward = int.tryParse(rewardController.text) ?? 25;
                if (title.isEmpty) {
                  return;
                }
                await state.setSessionGoal(title, reward.clamp(1, 500));
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  // Builds a compact dashboard stat card.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.accent),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, style: TextStyle(color: theme.muted)),
        ],
      ),
    );
  }
}

class _EventPreview extends StatelessWidget {
  const _EventPreview({required this.eventTitle, required this.eventTime});

  final String eventTitle;
  final String eventTime;

  // Builds a small preview row for a calendar event.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return CozyCard(
      child: Row(
        children: [
          Icon(Icons.schedule, color: theme.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(eventTime, style: TextStyle(color: theme.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
