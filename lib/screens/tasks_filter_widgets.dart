part of 'tasks_screen.dart';

class _PriorityHeader extends StatelessWidget {
  const _PriorityHeader({
    required this.priority,
    required this.count,
    required this.color,
  });

  final String priority;
  final int count;
  final Color color;

  // Builds a priority group heading with its visible task count.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$priority Priority',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
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

  // Builds the horizontal completion and due-date filter controls.
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

class _PriorityFilterBar extends StatelessWidget {
  const _PriorityFilterBar({
    required this.selectedPriority,
    required this.onSelected,
  });

  final String selectedPriority;
  final ValueChanged<String> onSelected;

  static const _options = [
    ('All', Colors.grey),
    ('High', Colors.red),
    ('Medium', Colors.orange),
    ('Low', Colors.green),
  ];

  // Builds the horizontal priority filter controls.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return Row(
      children: [
        Text(
          'Priority:',
          style: TextStyle(
            color: theme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (label, color) in _options) ...[
                  GestureDetector(
                    onTap: () => onSelected(label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selectedPriority == label
                            ? color.withValues(alpha: 0.20)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selectedPriority == label
                              ? color.withValues(alpha: 0.70)
                              : theme.muted.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selectedPriority == label
                              ? color
                              : theme.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
