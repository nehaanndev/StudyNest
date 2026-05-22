import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_session.dart';
import '../app/study_nest_state.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_town_scene.dart';
import 'study_space_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Builds the StudyNest dashboard with focus goal, stats, and today's plan.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final todayEvents = state.eventsForDay(DateTime.now()).take(3).toList();
    final upcomingTasks = state.upcomingTasks();

    final sessionComplete = state.sessionGoal.isCompleteOn(DateTime.now());

    return CozyPage(
      title: 'StudyNest',
      subtitle: '${theme.emoji} ${theme.name} study room',
      action: CoinBadge(coins: state.coinBalance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const _AccountStatusCard(),
          const SectionHeader(title: 'Study stations'),
          StudyFeatureStrip(
            openTasks: state.openTaskCount,
            notes: state.notes.length,
            todayBlocks: todayEvents.length,
            coins: state.coinBalance,
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

  // Opens the full study-space viewer from the dashboard room scene.
  void _openStudySpace(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const StudySpaceScreen()));
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
                final result = await state.setSessionGoal(
                  title,
                  reward.clamp(1, 500),
                );
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(result.message)));
                }
                if (!result.applied) {
                  return;
                }
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

class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard();

  // Builds the auth and sync summary card shown below the main room.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final syncLabel = switch (state.syncStatus) {
      StudyNestSyncStatus.disabled => 'Local only',
      StudyNestSyncStatus.idle => 'Synced',
      StudyNestSyncStatus.syncing => 'Syncing',
      StudyNestSyncStatus.offline => 'Offline',
      StudyNestSyncStatus.error => 'Needs retry',
    };
    final accountLabel = !state.cloudSyncEnabled
        ? 'Firebase not connected'
        : state.isAnonymousUser
        ? 'Anonymous cloud account'
        : 'Google-linked cloud account';

    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  accountLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              CozyTag(label: syncLabel, icon: Icons.sync),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.sessionMessage ??
                'Local state is always available first, then cloud sync catches up.',
          ),
          if (state.lastSyncedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last synced ${compactDate(state.lastSyncedAt!)}',
              style: TextStyle(color: state.selectedTheme.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (state.cloudSyncEnabled && state.isAnonymousUser)
                FilledButton.tonal(
                  onPressed: () => _linkGoogle(context),
                  child: const Text('Link Google'),
                ),
              if (!state.cloudSyncEnabled)
                OutlinedButton(
                  onPressed: () => _showFirebaseSetup(context),
                  child: const Text('Connect Firebase'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Starts the Google-link flow and reports the result back to the user.
  Future<void> _linkGoogle(BuildContext context) async {
    final result = await StudyNestScope.read(
      context,
    ).linkAnonymousAccountWithGoogle();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  // Explains how to create or connect the Firebase project for this app.
  Future<void> _showFirebaseSetup(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Connect Firebase'),
          content: const SingleChildScrollView(
            child: Text(
              '1. Install FlutterFire CLI if needed: dart pub global activate flutterfire_cli\n\n'
              '2. Run flutterfire configure in the project root.\n\n'
              '3. Select an existing Firebase project or create a new one.\n\n'
              '4. Register Android with package name com.studynest.app.\n\n'
              '5. Enable Authentication, Anonymous sign-in, Google sign-in, and Cloud Firestore.\n\n'
              '6. Replace the placeholder values in lib/firebase_options.dart with the generated values.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
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
