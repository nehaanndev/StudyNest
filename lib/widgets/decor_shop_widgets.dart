import 'package:flutter/material.dart';

import '../app/study_nest_catalog.dart';
import '../app/study_nest_scope.dart';
import '../app/study_nest_state.dart';
import '../app/study_nest_visuals.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_decor_layer.dart';

class DecorRarityTag extends StatelessWidget {
  const DecorRarityTag({super.key, required this.rarity});

  final DecorRarity rarity;

  // Builds the small colored chip naming a decor item's rarity tier.
  @override
  Widget build(BuildContext context) {
    final accent = rarity.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class DecorCollectionProgressCard extends StatelessWidget {
  const DecorCollectionProgressCard({super.key});

  // Builds the active theme's collection progress with rarity breakdowns.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final owned = state.activeThemeOwnedDecorCount;
    final total = state.activeThemeTotalDecorCount;
    final progress = total == 0 ? 0.0 : owned / total;

    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${theme.name} collection',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$owned of $total',
                style: TextStyle(
                  color: theme.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.surfaceAlt.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final rarity in decorRarityOrder)
                if (state.activeThemeTotalDecorCountForRarity(rarity) > 0)
                  _RarityProgressChip(
                    rarity: rarity,
                    owned: state.activeThemeOwnedDecorCountForRarity(rarity),
                    total: state.activeThemeTotalDecorCountForRarity(rarity),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RarityProgressChip extends StatelessWidget {
  const _RarityProgressChip({
    required this.rarity,
    required this.owned,
    required this.total,
  });

  final DecorRarity rarity;
  final int owned;
  final int total;

  // Builds one rarity tier's owned-versus-total progress chip.
  @override
  Widget build(BuildContext context) {
    final accent = rarity.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${rarity.label} $owned/$total',
        style: TextStyle(
          color: accent,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class DecorRarityShelf extends StatelessWidget {
  const DecorRarityShelf({
    super.key,
    required this.rarity,
    required this.items,
  });

  final DecorRarity rarity;
  final List<StudyDecorItem> items;

  // Builds one horizontal shop shelf holding all items of a rarity tier.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final ownedCount = items
        .where((item) => state.ownsDecorItem(item.id))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
          child: Row(
            children: [
              DecorRarityTag(rarity: rarity),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$ownedCount of ${items.length} collected',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: state.selectedTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in items) ...[
                DecorShopCard(item: item),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class DecorShopCard extends StatelessWidget {
  const DecorShopCard({super.key, required this.item});

  final StudyDecorItem item;

  // Builds one decor card with preview, rarity, price, and purchase state.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final owned = state.ownsDecorItem(item.id);
    final applied = state.isDecorItemApplied(item.id);
    final accent = item.rarity.color;

    return SizedBox(
      width: 138,
      child: CozyCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => showDecorRoomPreview(context, item),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: theme.surfaceAlt.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                    boxShadow: item.rarity.hasGlow
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.38),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: StudyDecorPreview(
                    item: item,
                    size: 76,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            DecorRarityTag(rarity: item.rarity),
            const SizedBox(height: 8),
            Row(
              children: [
                CozyTag(label: '${item.cost}', icon: Icons.savings),
                if (owned) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check_circle, size: 16, color: theme.primary),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => owned
                    ? state.toggleDecorItem(item.id)
                    : buyDecorItemWithFeedback(context, item),
                child: Text(
                  owned
                      ? applied
                            ? 'Hide'
                            : 'Place'
                      : 'Buy',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DecorInventoryTile extends StatelessWidget {
  const DecorInventoryTile({super.key, required this.item});

  final StudyDecorItem item;

  // Builds one owned-decor tile with its placement toggle for the inventory.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final applied = state.isDecorItemApplied(item.id);

    return SizedBox(
      width: 104,
      child: CozyCard(
        padding: const EdgeInsets.all(10),
        onTap: () => state.toggleDecorItem(item.id),
        child: Column(
          children: [
            Stack(
              children: [
                StudyDecorPreview(
                  item: item,
                  size: 64,
                  backgroundColor: theme.surfaceAlt.withValues(alpha: 0.30),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Icon(
                    applied ? Icons.visibility : Icons.visibility_off,
                    size: 15,
                    color: applied ? theme.primary : theme.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              applied ? 'In room' : 'Stored',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: applied ? theme.primary : theme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Purchases a decor item from any screen and reports the result.
Future<void> buyDecorItemWithFeedback(
  BuildContext context,
  StudyDecorItem item,
) async {
  final state = StudyNestScope.read(context);
  if (state.coinBalance < item.cost) {
    final missing = item.cost - state.coinBalance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Keep studying! You need $missing more coins.')),
    );
    return;
  }
  final result = await state.buyDecorItem(item);
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(result.message)));
}

// Opens a dialog previewing one decor item inside its room background.
Future<void> showDecorRoomPreview(BuildContext context, StudyDecorItem item) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _DecorRoomPreviewDialog(item: item),
  );
}

class _DecorRoomPreviewDialog extends StatelessWidget {
  const _DecorRoomPreviewDialog({required this.item});

  final StudyDecorItem item;

  // Builds the in-room preview with the item over its theme background.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final owned = state.ownsDecorItem(item.id);
    final visuals = visualsForTheme(item.themeId);

    return Dialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sceneSize = constraints.biggest;
                final spriteSize = (sceneSize.width * item.baseScale).clamp(
                  56.0,
                  132.0,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      visuals.detailImagePath,
                      fit: BoxFit.cover,
                      alignment: visuals.detailAlignment,
                      errorBuilder: (context, error, stackTrace) {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.primary.withValues(alpha: 0.35),
                                theme.background,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left:
                          item.defaultPosition.dx * sceneSize.width -
                          spriteSize / 2,
                      top:
                          item.defaultPosition.dy * sceneSize.height -
                          spriteSize * 0.72,
                      width: spriteSize,
                      height: spriteSize,
                      child: DecorSpriteImage(item: item),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    DecorRarityTag(rarity: item.rarity),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: TextStyle(color: theme.muted, height: 1.3),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CozyTag(
                      label: owned ? 'Owned' : '${item.cost} coins',
                      icon: owned ? Icons.lock_open : Icons.savings,
                    ),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: () async {
                        if (owned) {
                          Navigator.of(context).pop();
                          return;
                        }
                        await buyDecorItemWithFeedback(context, item);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(owned ? 'Close' : 'Buy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
