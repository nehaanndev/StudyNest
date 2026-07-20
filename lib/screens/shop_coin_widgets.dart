part of 'shop_screen.dart';

class _PomodoroDurationCard extends StatelessWidget {
  const _PomodoroDurationCard({
    required this.pending,
    required this.onBuy,
    required this.onMinutesSelected,
  });

  final bool pending;
  final VoidCallback onBuy;
  final ValueChanged<int> onMinutesSelected;

  // Builds the duration unlock and selectable focus-length settings.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final unlocked = state.pomodoroDurationUnlocked;
    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  unlocked ? Icons.timer_outlined : Icons.lock_clock_outlined,
                  color: theme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unlocked ? 'Focus length' : 'Unlock focus lengths',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlocked
                          ? 'Choose the duration used by idle and future focus cycles.'
                          : 'Customize Pomodoro focus cycles with one permanent upgrade.',
                      style: TextStyle(color: theme.muted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!unlocked) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const CozyTag(
                  label: '$pomodoroDurationUnlockCost coins',
                  icon: Icons.savings,
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: pending ? null : onBuy,
                  child: Text(pending ? 'Buying…' : 'Buy'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in pomodoroFocusMinuteOptions)
                  ChoiceChip(
                    label: Text('$minutes min'),
                    selected: state.pomodoroFocusMinutes == minutes,
                    onSelected: pending || state.pomodoroFocusMinutes == minutes
                        ? null
                        : (_) => onMinutesSelected(minutes),
                  ),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: !pomodoroFocusMinuteOptions.contains(
                    state.pomodoroFocusMinutes,
                  ),
                  onSelected: pending
                      ? null
                      : (_) => _showCustomMinutesDialog(
                          context,
                          state.pomodoroFocusMinutes,
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Collects and validates a custom focus duration before applying it.
  Future<void> _showCustomMinutesDialog(
    BuildContext context,
    int currentMinutes,
  ) async {
    final controller = TextEditingController(
      text: pomodoroFocusMinuteOptions.contains(currentMinutes)
          ? ''
          : currentMinutes.toString(),
    );
    String? errorText;
    final minutes = await showManagedDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Custom focus length'),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Minutes',
                  helperText:
                      '$minimumPomodoroFocusMinutes–$maximumPomodoroFocusMinutes minutes',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text);
                    if (value == null || !isValidPomodoroFocusMinutes(value)) {
                      setDialogState(
                        () => errorText =
                            'Enter $minimumPomodoroFocusMinutes–$maximumPomodoroFocusMinutes minutes.',
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    if (minutes != null && context.mounted) {
      onMinutesSelected(minutes);
    }
  }
}

class _CoinMultiplierCard extends StatelessWidget {
  const _CoinMultiplierCard({
    required this.factor,
    required this.reward,
    required this.active,
    required this.owned,
    required this.pending,
    required this.onPressed,
    this.cost,
  });

  final double factor;
  final int reward;
  final int? cost;
  final bool active;
  final bool owned;
  final bool pending;
  final VoidCallback onPressed;

  // Builds one multiplier offer with clearer badge and text separation.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final factorLabel = '${coinMultiplierLabel(factor)}x';
    return CozyCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              factorLabel,
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor == 1 ? 'Original rate' : '$factorLabel boost',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  '$reward coins per completed cycle',
                  style: TextStyle(color: theme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (active)
            const CozyTag(label: 'Active', icon: Icons.check_circle)
          else
            FilledButton.tonal(
              onPressed: pending ? null : onPressed,
              child: Text(
                pending
                    ? 'Working…'
                    : owned
                    ? 'Use'
                    : '🪙 ${cost ?? 0}',
              ),
            ),
        ],
      ),
    );
  }
}
