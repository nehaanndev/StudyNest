import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/study_nest_catalog.dart';
import '../app/study_nest_scope.dart';
import '../theme/study_theme.dart';
import 'cozy_widgets.dart';

part 'study_town_painters.dart';
part 'study_town_cafe_painter.dart';
part 'study_town_city_painter.dart';
part 'study_town_library_painter.dart';
part 'study_town_matcha_painter.dart';
part 'study_town_reference_details.dart';

class StudyTownScene extends StatelessWidget {
  const StudyTownScene({
    super.key,
    required this.environmentName,
    required this.focusTitle,
    required this.reward,
    required this.isComplete,
    required this.onComplete,
    required this.onEdit,
    this.decorItems = const [],
    this.styleId = 'reference',
    this.showFocusPanel = true,
    this.onExplore,
  });

  final String environmentName;
  final String focusTitle;
  final int reward;
  final bool isComplete;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final List<StudyDecorItem> decorItems;
  final String styleId;
  final bool showFocusPanel;
  final VoidCallback? onExplore;

  // Builds the low-poly study room hero with focus-session controls.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneHeight = showFocusPanel
            ? constraints.maxWidth > 520
                  ? 380.0
                  : 372.0
            : constraints.maxWidth > 520
            ? 430.0
            : 410.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: sceneHeight,
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border.all(color: theme.primary.withValues(alpha: 0.22)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StudyTownPainter(
                      theme: theme,
                      isComplete: isComplete,
                      decorItems: decorItems,
                      styleId: styleId,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  right: onExplore == null ? 14 : 66,
                  child: _SceneHeader(
                    environmentName: environmentName,
                    isComplete: isComplete,
                  ),
                ),
                if (onExplore != null)
                  Positioned(
                    right: 14,
                    top: 14,
                    child: IconButton.filledTonal(
                      tooltip: 'Open study space',
                      onPressed: onExplore,
                      icon: const Icon(Icons.open_in_full),
                    ),
                  ),
                if (showFocusPanel)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: _FocusPanel(
                      focusTitle: focusTitle,
                      reward: reward,
                      isComplete: isComplete,
                      onComplete: onComplete,
                      onEdit: onEdit,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StudyFeatureStrip extends StatelessWidget {
  const StudyFeatureStrip({
    super.key,
    required this.openTasks,
    required this.notes,
    required this.todayBlocks,
    required this.coins,
  });

  final int openTasks;
  final int notes;
  final int todayBlocks;
  final int coins;

  // Builds the horizontal feature-station strip for the app's core tools.
  @override
  Widget build(BuildContext context) {
    final features = [
      _StudyFeature(
        title: 'Task desk',
        detail: '$openTasks open',
        value: 'Earn coins',
        icon: Icons.checklist,
        color: const Color(0xFFDF7F63),
      ),
      _StudyFeature(
        title: 'Notes shelf',
        detail: '$notes saved',
        value: 'Recap ideas',
        icon: Icons.note_alt,
        color: const Color(0xFF6FA16D),
      ),
      _StudyFeature(
        title: 'Planner wall',
        detail: '$todayBlocks today',
        value: 'Block time',
        icon: Icons.calendar_month,
        color: const Color(0xFF6697BD),
      ),
      _StudyFeature(
        title: 'Coin shop',
        detail: '$coins coins',
        value: 'Unlock rooms',
        icon: Icons.storefront,
        color: const Color(0xFFB98556),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final feature in features) ...[
            _StudyFeatureChip(feature: feature),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _SceneHeader extends StatelessWidget {
  const _SceneHeader({required this.environmentName, required this.isComplete});

  final String environmentName;
  final bool isComplete;

  // Builds room metadata chips over the illustrated scene.
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        CozyTag(label: environmentName, icon: Icons.local_cafe),
        CozyTag(
          label: isComplete ? 'Goal done' : 'Focus room',
          icon: isComplete ? Icons.check_circle : Icons.timer,
        ),
      ],
    );
  }
}

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({
    required this.focusTitle,
    required this.reward,
    required this.isComplete,
    required this.onComplete,
    required this.onEdit,
  });

  final String focusTitle;
  final int reward;
  final bool isComplete;
  final VoidCallback onComplete;
  final VoidCallback onEdit;

  // Builds the foreground focus-goal panel and action buttons.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 470;
          final content = _FocusPanelContent(
            focusTitle: focusTitle,
            reward: reward,
            isComplete: isComplete,
          );
          final actions = _FocusPanelActions(
            isComplete: isComplete,
            onComplete: onComplete,
            onEdit: onEdit,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: actions),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 12),
              SizedBox(width: 210, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class _FocusPanelContent extends StatelessWidget {
  const _FocusPanelContent({
    required this.focusTitle,
    required this.reward,
    required this.isComplete,
  });

  final String focusTitle;
  final int reward;
  final bool isComplete;

  // Builds the focus-goal text and circular status mark.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isComplete ? theme.secondary : theme.accent).withValues(
              alpha: 0.2,
            ),
            border: Border.all(
              color: isComplete ? theme.secondary : theme.accent,
              width: 2,
            ),
          ),
          child: Icon(
            isComplete ? Icons.check : Icons.hourglass_bottom,
            color: isComplete ? theme.secondary : theme.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current focus goal',
                style: TextStyle(
                  color: theme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                focusTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              CozyTag(label: '+$reward', icon: Icons.savings),
            ],
          ),
        ),
      ],
    );
  }
}

class _FocusPanelActions extends StatelessWidget {
  const _FocusPanelActions({
    required this.isComplete,
    required this.onComplete,
    required this.onEdit,
  });

  final bool isComplete;
  final VoidCallback onComplete;
  final VoidCallback onEdit;

  // Builds the focus completion and edit controls.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isComplete ? null : onComplete,
            icon: Icon(isComplete ? Icons.check_circle : Icons.play_arrow),
            label: Text(isComplete ? 'Completed' : 'Start'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Edit goal',
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
        ),
      ],
    );
  }
}

class _StudyFeatureChip extends StatelessWidget {
  const _StudyFeatureChip({required this.feature});

  final _StudyFeature feature;

  // Builds a compact feature card that replaces generic study buddies.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Container(
      width: 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _FeatureBadge(icon: feature.icon, color: feature.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  feature.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  feature.value,
                  style: TextStyle(
                    color: theme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  // Builds a small room-station badge for a StudyNest feature.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.44)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _StudyFeature {
  const _StudyFeature({
    required this.title,
    required this.detail,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final String value;
  final IconData icon;
  final Color color;
}
