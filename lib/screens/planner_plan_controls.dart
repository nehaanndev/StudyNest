import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import 'planner_plan_models.dart';

/// Compact range controls shared by each Plan Mode timeline layout.
class PlannerViewSwitcher extends StatelessWidget {
  const PlannerViewSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PlannerTimelineView value;
  final ValueChanged<PlannerTimelineView> onChanged;

  /// Builds a three-option switch that remains readable on phone widths.
  @override
  Widget build(BuildContext context) {
    final visualTheme = StudyNestScope.watch(context).selectedTheme;

    return Semantics(
      label: 'Calendar range',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: visualTheme.surfaceAlt.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: visualTheme.accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            for (final view in PlannerTimelineView.values)
              Expanded(
                child: _PlannerViewOption(
                  view: view,
                  selected: view == value,
                  onPressed: () => onChanged(view),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One selectable range inside [PlannerViewSwitcher].
class _PlannerViewOption extends StatelessWidget {
  const _PlannerViewOption({
    required this.view,
    required this.selected,
    required this.onPressed,
  });

  final PlannerTimelineView view;
  final bool selected;
  final VoidCallback onPressed;

  /// Builds an accessible range button with a clear selected treatment.
  @override
  Widget build(BuildContext context) {
    final visualTheme = StudyNestScope.watch(context).selectedTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? visualTheme.accent.withValues(alpha: 0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
            child: Text(
              view.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? visualTheme.text : visualTheme.muted,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
