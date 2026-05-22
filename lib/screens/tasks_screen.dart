import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_station_banner.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  // Builds the task list and task creation controls.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final tasks = state.tasks;

    return CozyPage(
      title: 'Tasks',
      subtitle: 'Turn tiny wins into coins for your shop.',
      action: IconButton.filled(
        tooltip: 'Add task',
        onPressed: () => _showTaskDialog(context),
        icon: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          StudyStationBanner(
            title: 'Task desk',
            detail: 'Your checklist is the coin engine for the whole room.',
            metric: '${state.openTaskCount} open',
            icon: Icons.checklist,
            imagePath: screenBannerAsset('tasks', state.selectedTheme.id),
            imageAlignment: Alignment.center,
          ),
          const SizedBox(height: 14),
          const _TaskFilterBar(),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            const EmptyState(
              icon: '✅',
              title: 'No tasks yet',
              body: 'Create a goal, finish it, and collect coins.',
            )
          else
            Column(
              children: [
                for (final task in tasks) ...[
                  _TaskCard(task: task),
                  const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // Opens the task creation dialog and saves a new task when valid.
  Future<void> _showTaskDialog(BuildContext context) async {
    final state = StudyNestScope.read(context);
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final rewardController = TextEditingController(text: '20');
    var dueAt = DateTime.now().add(const Duration(hours: 2));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('New task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailsController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Details'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rewardController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Coin reward',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: Text('Due ${compactDate(dueAt)}'),
                      subtitle: Text(clockTime(dueAt)),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          initialDate: dueAt,
                        );
                        if (pickedDate == null || !dialogContext.mounted) {
                          return;
                        }
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(dueAt),
                        );
                        if (pickedTime == null) {
                          return;
                        }
                        setDialogState(() {
                          dueAt = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
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
                    final reward = int.tryParse(rewardController.text) ?? 20;
                    if (title.isEmpty) {
                      return;
                    }
                    final result = await state.addTask(
                      title: title,
                      details: detailsController.text,
                      dueAt: dueAt,
                      reward: reward.clamp(1, 500),
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

class _TaskFilterBar extends StatelessWidget {
  const _TaskFilterBar();

  static const _filters = ['All', 'Today', 'Upcoming', 'Completed'];

  // Builds the mockup-style filter pills for task views.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _filters) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: filter == 'All'
                    ? theme.accent.withValues(alpha: 0.16)
                    : theme.surface.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: filter == 'All'
                      ? theme.accent.withValues(alpha: 0.7)
                      : theme.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final StudyTask task;

  // Builds an individual task row with completion and deletion actions.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final isComplete = task.completedAt != null;

    return CozyCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isComplete,
            onChanged: (_) => _toggleTask(context, task.id),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    decoration: isComplete ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    task.details,
                    style: TextStyle(color: theme.muted, height: 1.3),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CozyTag(label: compactDate(task.dueAt), icon: Icons.event),
                    CozyTag(label: '+${task.reward}', icon: Icons.savings),
                    if (task.rewardCollected)
                      const CozyTag(label: 'Reward claimed', icon: Icons.lock),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete task',
            onPressed: () => state.deleteTask(task.id),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  // Toggles a task and reports any newly awarded coins.
  Future<void> _toggleTask(BuildContext context, String taskId) async {
    final state = StudyNestScope.read(context);
    final awarded = await state.toggleTask(taskId);
    if (!context.mounted || awarded == 0) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task complete. You earned $awarded coins.')),
    );
  }
}
