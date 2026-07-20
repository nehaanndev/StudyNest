part of 'tasks_screen.dart';

class _TaskCoinStatusCard extends StatelessWidget {
  const _TaskCoinStatusCard();

  // Explains whether task completions currently mint coins and how to unlock them.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final unlocked = state.taskCoinRewardsUnlocked;
    final enabled = state.taskCoinRewardsEnabled;
    final title = enabled
        ? 'Task coins are on'
        : unlocked
        ? 'Task coins are paused'
        : 'Pomodoro-only coins';
    final detail = enabled
        ? 'Completed tasks earn their listed reward, up to $maximumTaskCoinReward coins.'
        : unlocked
        ? 'Tasks still complete normally. Switch rewards back on anytime in Shop.'
        : 'Tasks stay reward-free until you buy the $taskCoinUnlockCost-coin switch in Shop.';

    return CozyCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (enabled ? theme.accent : theme.primary).withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              enabled ? Icons.savings : Icons.timer_outlined,
              color: enabled ? theme.accent : theme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(detail, style: TextStyle(color: theme.muted, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
