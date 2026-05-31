import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_station_banner.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  // Creates task screen state for active filters.
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'All';

  // Builds the task list and task creation controls.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final tasks = _filteredTasks(state.tasks);

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
          _TaskFilterBar(
            selectedFilter: _filter,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
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

  // Returns tasks matching the selected task filter.
  List<StudyTask> _filteredTasks(List<StudyTask> tasks) {
    final now = DateTime.now();
    return tasks.where((task) {
      return switch (_filter) {
        'Today' => isSameCalendarDay(task.dueAt, now),
        'Upcoming' => task.completedAt == null && task.dueAt.isAfter(now),
        'Completed' => task.completedAt != null,
        _ => true,
      };
    }).toList();
  }

  // Opens the task creation or edit dialog and saves valid changes.
  Future<void> _showTaskDialog(BuildContext context, {StudyTask? task}) async {
    final state = StudyNestScope.read(context);
    final titleController = TextEditingController(text: task?.title ?? '');
    final detailsController = TextEditingController(text: task?.details ?? '');
    final rewardController = TextEditingController(
      text: (task?.reward ?? 20).toString(),
    );
    var dueAt = task?.dueAt ?? DateTime.now().add(const Duration(hours: 2));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(task == null ? 'New task' : 'Edit task'),
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
                    final clampedReward = reward.clamp(1, 500);
                    final result = task == null
                        ? await state.addTask(
                            title: title,
                            details: detailsController.text,
                            dueAt: dueAt,
                            reward: clampedReward,
                          )
                        : null;
                    if (task != null) {
                      await state.updateTask(
                        taskId: task.id,
                        title: title,
                        details: detailsController.text,
                        dueAt: dueAt,
                        reward: clampedReward,
                      );
                    }
                    if (!dialogContext.mounted) {
                      return;
                    }
                    final message = result?.message ?? 'Task updated.';
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(message)));
                    if (result != null && !result.applied) {
                      return;
                    }
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(task == null ? 'Create' : 'Save'),
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
  const _TaskFilterBar({
    required this.selectedFilter,
    required this.onSelected,
  });

  final String selectedFilter;
  final ValueChanged<String> onSelected;

  static const _filters = ['All', 'Today', 'Upcoming', 'Completed'];

  // Builds selectable filter pills for task views.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _filters) ...[
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelected(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: filter == selectedFilter
                      ? theme.accent.withValues(alpha: 0.16)
                      : theme.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: filter == selectedFilter
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

  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final isComplete = task.completedAt != null;

    return CozyCard(
      onTap: () => context
          .findAncestorStateOfType<_TasksScreenState>()
          ?._showTaskDialog(context, task: task),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isComplete,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => _toggleTask(context, task.id),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    decoration: isComplete ? TextDecoration.lineThrough : null,
                    color: isComplete ? theme.muted : theme.text,
                  ),
                ),
                if (task.details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.details,
                    style: TextStyle(
                        color: theme.muted, height: 1.3, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    CozyTag(label: compactDate(task.dueAt), icon: Icons.event),
                    CozyTag(label: '+${task.reward}', icon: Icons.savings),
                    if (task.rewardCollected)
                      const CozyTag(label: 'Claimed', icon: Icons.lock),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete task',
            visualDensity: VisualDensity.compact,
            onPressed: () => state.deleteTask(task.id),
            icon: Icon(Icons.delete_outline, size: 18, color: theme.muted),
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
