import 'package:flutter/material.dart';

import '../app/study_nest_catalog.dart';
import '../app/study_nest_scope.dart';
import '../app/study_nest_state.dart';
import '../models/study_models.dart';
import '../theme/study_theme.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/movable_decor_scene.dart';

class StudySpaceScreen extends StatelessWidget {
  const StudySpaceScreen({super.key});

  // Builds the full-screen study-space viewer and customization controls.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final selectedStyle =
        studySpaceLookOptions.any((option) {
          return option.id == state.studySpaceStyleId;
        })
        ? state.studySpaceStyleId
        : 'reference';

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.background,
              Color.alphaBlend(
                theme.primary.withValues(alpha: 0.18),
                theme.background,
              ),
              theme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pageWidth = constraints.maxWidth > 500
                  ? 460.0
                  : double.infinity;

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: pageWidth,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                    children: [
                      _StudySpaceHeader(theme: theme, coins: state.coinBalance),
                      const SizedBox(height: 16),
                      MovableDecorScene(
                        environmentName: theme.name,
                        focusTitle: state.sessionGoal.title,
                        reward: state.sessionGoal.reward,
                        isComplete: state.sessionGoal.isCompleteOn(
                          DateTime.now(),
                        ),
                        decorItems: state.appliedDecorItems,
                        decorPositions: state.decorPositions,
                        styleId: selectedStyle,
                        onDecorMoved: state.setDecorPosition,
                      ),
                      const SizedBox(height: 14),
                      _StudySpaceStyleCard(selectedStyle: selectedStyle),
                      const SectionHeader(title: 'Room themes'),
                      const _CozyCafeThemeCard(),
                      const SizedBox(height: 12),
                      for (final item in StudyNestState.shopItems) ...[
                        _ThemeControlCard(item: item),
                        const SizedBox(height: 12),
                      ],
                      SectionHeader(title: '${theme.name} decor'),
                      for (final item in state.activeThemeDecorItems) ...[
                        _DecorControlCard(item: item),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StudySpaceHeader extends StatelessWidget {
  const _StudySpaceHeader({required this.theme, required this.coins});

  final StudyVisualTheme theme;
  final int coins;

  // Builds the study-space route header with back navigation and coin balance.
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Space',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${theme.emoji} ${theme.name}',
                style: TextStyle(
                  color: theme.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        CoinBadge(coins: coins),
      ],
    );
  }
}

class _StudySpaceStyleCard extends StatelessWidget {
  const _StudySpaceStyleCard({required this.selectedStyle});

  final String selectedStyle;

  // Builds the room detail selector for simple and photo-inspired spaces.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);

    return CozyCard(
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          for (final option in studySpaceLookOptions)
            ButtonSegment<String>(
              value: option.id,
              icon: Icon(option.icon),
              label: Text(option.title),
            ),
        ],
        selected: {selectedStyle},
        onSelectionChanged: (selection) {
          state.setStudySpaceStyle(selection.first);
        },
      ),
    );
  }
}

class _CozyCafeThemeCard extends StatelessWidget {
  const _CozyCafeThemeCard();

  // Builds the built-in default theme control.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final active = state.selectedTheme.id == 'cozyCafe';

    return CozyCard(
      child: _ShopControlRow(
        icon: const Text('☕', style: TextStyle(fontSize: 28)),
        title: 'Cozy Cafe',
        description: 'Warm bookstore cafe with wood tables and soft lamps.',
        trailing: FilledButton.tonal(
          onPressed: active ? null : () => state.applyTheme('cozyCafe'),
          child: Text(active ? 'Active' : 'Apply'),
        ),
      ),
    );
  }
}

class _ThemeControlCard extends StatelessWidget {
  const _ThemeControlCard({required this.item});

  final ShopItem item;

  // Builds one theme purchase or apply control for the study space.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final visualTheme = themeById(item.themeId);
    final owned = state.ownsShopItem(item.id);
    final active = state.selectedTheme.id == item.themeId;
    final canAfford = state.coinBalance >= item.cost;

    return CozyCard(
      child: _ShopControlRow(
        icon: Text(item.icon, style: const TextStyle(fontSize: 28)),
        title: item.title,
        description: item.description,
        previewColor: visualTheme.primary,
        tags: [
          CozyTag(label: '${item.cost}', icon: Icons.savings),
          if (owned) const CozyTag(label: 'Owned', icon: Icons.lock_open),
        ],
        trailing: FilledButton.tonal(
          onPressed: active
              ? null
              : () => owned
                    ? state.applyTheme(item.themeId)
                    : _buyTheme(context, item, canAfford),
          child: Text(
            active
                ? 'Active'
                : owned
                ? 'Apply'
                : 'Buy',
          ),
        ),
      ),
    );
  }

  // Purchases a theme from the room screen and reports the result.
  Future<void> _buyTheme(
    BuildContext context,
    ShopItem item,
    bool canAfford,
  ) async {
    if (!canAfford) {
      _showSnack(context, 'Not enough coins yet.');
      return;
    }
    final bought = await StudyNestScope.read(context).buyShopItem(item);
    if (!context.mounted) {
      return;
    }
    _showSnack(context, bought ? 'Theme unlocked.' : 'Purchase skipped.');
  }
}

class _DecorControlCard extends StatelessWidget {
  const _DecorControlCard({required this.item});

  final StudyDecorItem item;

  // Builds one decor purchase or apply control for the active room theme.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final owned = state.ownsDecorItem(item.id);
    final applied = state.isDecorItemApplied(item.id);
    final canAfford = state.coinBalance >= item.cost;

    return CozyCard(
      child: _ShopControlRow(
        icon: Icon(item.icon, color: state.selectedTheme.primary, size: 28),
        title: item.title,
        description: item.description,
        tags: [
          CozyTag(label: '${item.cost}', icon: Icons.savings),
          if (owned)
            CozyTag(
              label: applied ? 'Applied' : 'Owned',
              icon: applied ? Icons.check_circle : Icons.lock_open,
            ),
        ],
        trailing: FilledButton.tonal(
          onPressed: () => owned
              ? state.toggleDecorItem(item.id)
              : _buyDecor(context, item, canAfford),
          child: Text(
            owned
                ? applied
                      ? 'Hide'
                      : 'Apply'
                : 'Buy',
          ),
        ),
      ),
    );
  }

  // Purchases a decor item from the room screen and reports the result.
  Future<void> _buyDecor(
    BuildContext context,
    StudyDecorItem item,
    bool canAfford,
  ) async {
    if (!canAfford) {
      _showSnack(context, 'Not enough coins yet.');
      return;
    }
    final bought = await StudyNestScope.read(context).buyDecorItem(item);
    if (!context.mounted) {
      return;
    }
    _showSnack(context, bought ? 'Decor applied.' : 'Purchase skipped.');
  }
}

class _ShopControlRow extends StatelessWidget {
  const _ShopControlRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.trailing,
    this.previewColor,
    this.tags = const [],
  });

  final Widget icon;
  final String title;
  final String description;
  final Widget trailing;
  final Color? previewColor;
  final List<Widget> tags;

  // Builds shared rows for theme and decor controls.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (previewColor ?? theme.surfaceAlt).withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(14),
          ),
          child: icon,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(color: theme.muted, height: 1.28),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: tags),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        trailing,
      ],
    );
  }
}

// Shows a short message for room customization actions.
void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
