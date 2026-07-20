import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/study_nest_rewards.dart';
import '../app/study_nest_scope.dart';
import '../app/study_nest_state.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/managed_dialog.dart';
import '../widgets/study_station_banner.dart';

part 'tasks_coin_widgets.dart';
part 'tasks_filter_widgets.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  // Creates filter and dialog state for the task list.
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'All';
  String _priorityFilter = 'All'; // 'All', 'High', 'Medium', 'Low'

  static const _priorityOrder = ['High', 'Medium', 'Low'];
  static const _priorityColors = {
    'High': Colors.red,
    'Medium': Colors.orange,
    'Low': Colors.green,
  };

  // Builds task progress, coin-mode guidance, filters, and grouped task cards.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final tasks = _filteredTasks(state.tasks);

    // Group tasks by priority
    final grouped = <String, List<StudyTask>>{};
    for (final p in _priorityOrder) {
      final list = tasks.where((t) => t.priority == p).toList();
      if (list.isNotEmpty) grouped[p] = list;
    }
    // Tasks with other/missing priority go to Medium bucket display
    final ungrouped = tasks
        .where((t) => !_priorityOrder.contains(t.priority))
        .toList();
    if (ungrouped.isNotEmpty) {
      grouped['Medium'] = [...(grouped['Medium'] ?? []), ...ungrouped];
    }

    return Scaffold(
      body: CozyPage(
        title: 'Tasks',
        subtitle: state.taskCoinRewardsEnabled
            ? 'Finish tasks for up to $maximumTaskCoinReward coins each.'
            : 'Plan your wins. Pomodoro cycles earn coins.',
        action: IconButton.filled(
          tooltip: 'Add task',
          onPressed: () => _showTaskDialog(context),
          icon: const Icon(Icons.add),
        ),
        child: Column(
          children: [
            StudyStationBanner(
              title: 'My Tasks',
              detail: state.taskCoinRewardsEnabled
                  ? 'Complete tasks to earn their listed coin reward.'
                  : 'Task completion counts even while task coins are off.',
              metric: '${state.openTaskCount} open',
              icon: Icons.checklist,
              imagePath: screenBannerAsset('tasks', state.selectedTheme.id),
              imageAlignment: Alignment.center,
            ),
            const SizedBox(height: 12),
            const _TaskCoinStatusCard(),
            const SizedBox(height: 14),
            _TaskFilterBar(
              selectedFilter: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 8),
            _PriorityFilterBar(
              selectedPriority: _priorityFilter,
              onSelected: (p) => setState(() => _priorityFilter = p),
            ),
            const SizedBox(height: 14),
            if (tasks.isEmpty)
              EmptyState(
                icon: '✅',
                title: 'No tasks yet',
                body: state.taskCoinRewardsEnabled
                    ? 'Create a goal, finish it, and collect coins.'
                    : 'Create a goal, finish it, and build momentum.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final priority in _priorityOrder)
                    if (grouped.containsKey(priority)) ...[
                      _PriorityHeader(
                        priority: priority,
                        count: grouped[priority]!.length,
                        color: _priorityColors[priority] ?? Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      for (final task in grouped[priority]!) ...[
                        _TaskCard(task: task),
                        const SizedBox(height: 12),
                      ],
                    ],
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: FilledButton.icon(
            onPressed: () => _showTaskDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add New Task'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ),
    );
  }

  // Applies the selected date and priority filters to the task list.
  List<StudyTask> _filteredTasks(List<StudyTask> tasks) {
    final now = DateTime.now();
    return tasks.where((task) {
      final passesDate = switch (_filter) {
        'Today' => isSameCalendarDay(task.dueAt, now),
        'Upcoming' => task.completedAt == null && task.dueAt.isAfter(now),
        'Completed' => task.completedAt != null,
        _ => true,
      };
      final passesPriority =
          _priorityFilter == 'All' || task.priority == _priorityFilter;
      return passesDate && passesPriority;
    }).toList();
  }

  // Opens the create/edit form and validates the 1–50 coin task limit.
  Future<void> _showTaskDialog(BuildContext context, {StudyTask? task}) async {
    final state = StudyNestScope.read(context);
    final titleController = TextEditingController(text: task?.title ?? '');
    final detailsController = TextEditingController(text: task?.details ?? '');
    final rewardController = TextEditingController(
      text: (task?.reward ?? 20).toString(),
    );
    var dueAt = task?.dueAt ?? DateTime.now().add(const Duration(hours: 2));
    var priority = task?.priority ?? 'Medium';
    String? rewardError;

    await showManagedDialog<void>(
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
                      enabled: state.taskCoinRewardsEnabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        final reward = int.tryParse(value);
                        setDialogState(() {
                          rewardError =
                              reward == null ||
                                  reward < 1 ||
                                  reward > maximumTaskCoinReward
                              ? 'Enter 1–$maximumTaskCoinReward coins.'
                              : null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Coin reward',
                        helperText: state.taskCoinRewardsEnabled
                            ? 'Maximum $maximumTaskCoinReward coins per task.'
                            : 'Turn on task coins in the Shop to set a reward.',
                        errorText: rewardError,
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const [
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(
                          value: 'Medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => priority = v);
                      },
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
                        if (pickedTime == null) return;
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
                    final reward = int.tryParse(rewardController.text);
                    if (title.isEmpty) return;
                    if (reward == null ||
                        reward < 1 ||
                        reward > maximumTaskCoinReward) {
                      setDialogState(
                        () => rewardError =
                            'Enter 1–$maximumTaskCoinReward coins.',
                      );
                      return;
                    }
                    final result = task == null
                        ? await state.addTask(
                            title: title,
                            details: detailsController.text,
                            dueAt: dueAt,
                            reward: reward,
                            priority: priority,
                          )
                        : null;
                    if (task != null) {
                      await state.updateTask(
                        taskId: task.id,
                        title: title,
                        details: detailsController.text,
                        dueAt: dueAt,
                        reward: reward,
                        priority: priority,
                      );
                    }
                    if (!dialogContext.mounted) return;
                    final message = result?.message ?? 'Task updated.';
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(message)));
                    if (result != null && !result.applied) return;
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
    titleController.dispose();
    detailsController.dispose();
    rewardController.dispose();
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final StudyTask task;

  // Builds one task with completion, reward-state, edit, and delete controls.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final isComplete = task.completedAt != null;
    final rewardWasPaid = state.taskCoinRewardWasPaid(task.id);

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
                      color: theme.muted,
                      height: 1.3,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    CozyTag(label: compactDate(task.dueAt), icon: Icons.event),
                    if (task.rewardCollected && !rewardWasPaid)
                      const CozyTag(
                        label: 'No reward earned',
                        icon: Icons.money_off,
                      )
                    else
                      CozyTag(
                        label: state.taskCoinRewardsEnabled
                            ? '+${task.reward}'
                            : state.taskCoinRewardsUnlocked
                            ? '${task.reward} paused'
                            : 'No task coins',
                        icon: state.taskCoinRewardsEnabled
                            ? Icons.savings
                            : Icons.pause_circle_outline,
                      ),
                    if (rewardWasPaid)
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

  // Toggles a task and announces a payout only when coins were actually earned.
  Future<void> _toggleTask(BuildContext context, String taskId) async {
    final state = StudyNestScope.read(context);
    final awarded = await state.toggleTask(taskId);
    if (!context.mounted || awarded == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task complete. You earned $awarded coins.')),
    );
  }
}
