import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_state.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_town_scene.dart';
import 'study_space_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final now = DateTime.now();

    final allTasks = state.tasks;
    final todayTasks = allTasks
        .where((t) => isSameCalendarDay(t.dueAt, now))
        .toList();
    final completedToday = todayTasks.where((t) => t.completedAt != null).length;
    final totalToday = todayTasks.length;

    final completedTotal = state.completedTaskCount;
    final level = completedTotal ~/ 5 + 1;
    final upcomingTasks = state.upcomingTasks();
    final sessionComplete = state.sessionGoal.isCompleteOn(now);

    return CozyPage(
      title: 'StudyNest',
      subtitle: '${theme.emoji} ${theme.name}',
      action: CoinBadge(coins: state.coinBalance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats pills row
          Row(
            children: [
              _StatPill(label: '🪙 ${state.coinBalance}', accentColor: theme.accent),
              const SizedBox(width: 8),
              _StatPill(label: '✅ $completedTotal done', accentColor: theme.accent),
              const SizedBox(width: 8),
              _StatPill(label: '⭐ Lv.$level', accentColor: theme.accent),
            ],
          ),
          const SizedBox(height: 14),

          // Room scene
          StudyTownScene(
            environmentName: theme.name,
            focusTitle: state.sessionGoal.title,
            reward: state.sessionGoal.reward,
            isComplete: sessionComplete,
            onComplete: () => _completeSessionGoal(context),
            onEdit: () => _showSessionGoalDialog(context),
            decorItems: state.appliedDecorItems,
            decorPositions: state.decorPositions,
            styleId: state.studySpaceStyleId,
            onExplore: () => _openStudySpace(context),
          ),
          const SizedBox(height: 14),

          // Daily Progress card
          CozyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Daily Progress',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: theme.text,
                        ),
                      ),
                    ),
                    Text(
                      completedToday >= totalToday && totalToday > 0
                          ? 'Great job! 🎉'
                          : 'Keep going!',
                      style: TextStyle(color: theme.muted, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalToday == 0
                        ? 0
                        : completedToday / totalToday,
                    minHeight: 10,
                    color: theme.accent,
                    backgroundColor: theme.accent.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedToday / $totalToday tasks completed today',
                  style: TextStyle(color: theme.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick nav 2x2 grid
          const SectionHeader(title: 'Quick access'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: [
              _QuickNavTile(
                icon: Icons.checklist,
                label: 'Tasks',
                onTap: () => onNavigate?.call(1),
              ),
              _QuickNavTile(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Focus',
                onTap: () => onNavigate?.call(2),
              ),
              _QuickNavTile(
                icon: Icons.calendar_month,
                label: 'Calendar',
                onTap: () => onNavigate?.call(3),
              ),
              _QuickNavTile(
                icon: Icons.note_alt,
                label: 'Notes',
                onTap: () => onNavigate?.call(4),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Focus Time card
          CozyCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Focus Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '25:00',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.accent,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => onNavigate?.call(2),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.black87,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Next tasks
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
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: theme.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Due ${compactDate(task.dueAt)}',
                            style: TextStyle(color: theme.muted, fontSize: 12),
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

  void _openStudySpace(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const StudySpaceScreen()),
    );
  }

  Future<void> _completeSessionGoal(BuildContext context) async {
    final state = StudyNestScope.read(context);
    final awarded = await state.completeSessionGoal();
    if (!context.mounted) return;
    final message = awarded > 0
        ? 'Nice focus. You earned $awarded coins.'
        : 'That goal is already complete today.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showSessionGoalDialog(BuildContext context) async {
    final state = StudyNestScope.read(context);
    final titleController =
        TextEditingController(text: state.sessionGoal.title);
    final rewardController =
        TextEditingController(text: state.sessionGoal.reward.toString());

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
                if (title.isEmpty) return;
                final result =
                    await state.setSessionGoal(title, reward.clamp(1, 500));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(SnackBar(content: Text(result.message)));
                }
                if (!result.applied) return;
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.accentColor});

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: accentColor,
        ),
      ),
    );
  }
}

class _QuickNavTile extends StatelessWidget {
  const _QuickNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: theme.surface.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.accent.withValues(alpha: 0.25),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: theme.accent, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: theme.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
