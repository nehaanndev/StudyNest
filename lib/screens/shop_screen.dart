import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_state.dart';
import '../models/study_models.dart';
import '../theme/study_theme.dart';
import '../widgets/cozy_widgets.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  // Builds the rewards shop and unlocked theme controls.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);

    return CozyPage(
      title: 'Shop',
      subtitle: 'Spend study coins on cozy themes and collectibles.',
      action: CoinBadge(coins: state.coinBalance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CozyCard(
            child: Row(
              children: [
                const Text('☕', style: TextStyle(fontSize: 34)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cozy Cafe',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Default warm cafe theme.',
                        style: TextStyle(color: state.selectedTheme.muted),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: state.selectedTheme.id == 'cozyCafe'
                      ? null
                      : () => state.applyTheme('cozyCafe'),
                  child: Text(
                    state.selectedTheme.id == 'cozyCafe' ? 'Active' : 'Apply',
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Theme shelf'),
          for (final item in StudyNestState.shopItems) ...[
            _ShopItemCard(item: item),
            const SizedBox(height: 12),
          ],
          const SectionHeader(title: 'Coming later'),
          const CozyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leaderboard and collectibles',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Avatars, app icons, and richest-player leaderboard can use the same coin ledger later.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({required this.item});

  final ShopItem item;

  // Builds a purchasable shop item card.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final visualTheme = themeById(item.themeId);
    final owned = state.ownsShopItem(item.id);
    final active = state.selectedTheme.id == item.themeId;
    final canAfford = state.coinBalance >= item.cost;

    return CozyCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: visualTheme.primary.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(item.icon, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: TextStyle(
                    color: state.selectedTheme.muted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    CozyTag(label: '${item.cost}', icon: Icons.savings),
                    if (owned)
                      const CozyTag(label: 'Owned', icon: Icons.lock_open),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: active
                ? null
                : () => owned
                      ? state.applyTheme(item.themeId)
                      : _buyItem(context, item, canAfford),
            child: Text(
              active
                  ? 'Active'
                  : owned
                  ? 'Apply'
                  : 'Buy',
            ),
          ),
        ],
      ),
    );
  }

  // Purchases an item and reports whether the purchase succeeded.
  Future<void> _buyItem(
    BuildContext context,
    ShopItem item,
    bool canAfford,
  ) async {
    if (!canAfford) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not enough coins yet.')));
      return;
    }
    final bought = await StudyNestScope.read(context).buyShopItem(item);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(bought ? 'Theme unlocked.' : 'Purchase skipped.')),
    );
  }
}
