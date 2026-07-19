part of 'planner_screen.dart';

// Renders the selected day's agenda and its empty state.
class _AgendaSection extends StatelessWidget {
  const _AgendaSection({
    required this.day,
    required this.events,
    required this.onEdit,
    required this.onAdd,
    required this.onDelete,
  });

  final DateTime day;
  final List<PlannerEvent> events;
  final ValueChanged<PlannerEvent> onEdit;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  // Builds the agenda header and either an empty state or editable blocks.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                compactDate(day),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${events.length} ${events.length == 1 ? 'block' : 'blocks'}',
              style: TextStyle(color: theme.muted, fontSize: 13),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Add block on this day',
              visualDensity: VisualDensity.compact,
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          EmptyState(
            icon: '📅',
            title: 'Nothing scheduled',
            body: 'Tap + to add a study block, review, or break.',
          )
        else
          for (final event in events) ...[
            _AgendaRow(
              event: event,
              onEdit: () => onEdit(event),
              onDelete: () => onDelete(event.id),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

// Displays one planner block with edit and delete controls.
class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final PlannerEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // Builds a tappable agenda row with timing, category, and quick actions.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final color = categoryColor(event.category);

    return CozyCard(
      padding: EdgeInsets.zero,
      onTap: onEdit,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            SizedBox(
              width: 58,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  clockTime(event.startsAt).replaceAll(' ', '\n'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: theme.text,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 0, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeRange(event.startsAt, event.endsAt),
                      style: TextStyle(color: theme.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 7),
                    _CategoryChip(category: event.category, color: color),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 18, color: theme.muted),
                ),
                IconButton(
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: theme.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// Shows the category name using its matching visual color.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.color});

  final String category;
  final Color color;

  // Builds a compact category label for an agenda row.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
