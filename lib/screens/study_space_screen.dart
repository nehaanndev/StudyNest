import 'package:flutter/material.dart';

import '../app/study_nest_catalog.dart';
import '../app/study_nest_scope.dart';
import '../app/study_nest_state.dart';
import '../models/study_models.dart';
import '../theme/study_theme.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/decor_shop_widgets.dart';
import '../widgets/movable_decor_scene.dart';
import '../widgets/study_photo_widgets.dart';

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
        : 'detail';

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
                      const SizedBox(height: 12),
                      StudySceneStrip(themeId: theme.id, height: 96),
                      const SizedBox(height: 16),
                      MovableDecorScene(
                        environmentName: theme.name,
                        focusTitle: state.sessionGoal.title,
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
                      const SectionHeader(title: 'Your collection'),
                      const _DecorInventorySection(),
                      SectionHeader(title: '${theme.name} decor shop'),
                      const DecorCollectionProgressCard(),
                      for (final shelf in state.decorShelvesByRarity.entries)
                        DecorRarityShelf(rarity: shelf.key, items: shelf.value),
                      const SectionHeader(title: 'Room themes'),
                      const _CozyCafeThemeCard(),
                      const SizedBox(height: 12),
                      for (final item in StudyNestState.shopItems) ...[
                        _ThemeControlCard(item: item),
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

class _DecorInventorySection extends StatelessWidget {
  const _DecorInventorySection();

  // Builds the owned-decor inventory with placement toggles for this theme.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final ownedItems = state.ownedActiveThemeDecorItems;

    if (ownedItems.isEmpty) {
      return CozyCard(
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: state.selectedTheme.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No decorations collected for this room yet. Earn coins by studying, then unlock pieces below.',
                style: TextStyle(
                  color: state.selectedTheme.muted,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in ownedItems) ...[
                DecorInventoryTile(item: item),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
          child: Text(
            'Tap a piece to place or store it, then drag it around the room above. Small sprites have larger grab areas.',
            style: TextStyle(
              color: state.selectedTheme.muted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
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
      padding: EdgeInsets.zero,
      child: StudyThemeShowcaseCard(
        theme: themeById('cozyCafe'),
        description: themeById('cozyCafe').description,
        decorPreviewItems: _decorPreviewForTheme('cozyCafe'),
        action: FilledButton.tonal(
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
      padding: EdgeInsets.zero,
      child: StudyThemeShowcaseCard(
        theme: visualTheme,
        description: item.description,
        decorPreviewItems: _decorPreviewForTheme(item.themeId),
        tags: [
          CozyTag(label: '${item.cost}', icon: Icons.savings),
          if (owned) const CozyTag(label: 'Owned', icon: Icons.lock_open),
        ],
        action: FilledButton.tonal(
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

// Shows a short message for room customization actions.
void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

// Returns a few collectible decor items for immersive theme card previews.
List<StudyDecorItem> _decorPreviewForTheme(String themeId) {
  return studyDecorItems
      .where((item) => item.themeId == themeId)
      .take(3)
      .toList();
}
