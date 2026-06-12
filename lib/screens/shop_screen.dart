import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_state.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_models.dart';
import '../theme/study_theme.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/decor_shop_widgets.dart';
import '../widgets/study_photo_widgets.dart';
import '../widgets/study_station_banner.dart';

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
          StudyStationBanner(
            title: 'Shop',
            detail: 'Spend your earned coins on themes and room decor.',
            metric: '${state.coinBalance} coins',
            icon: Icons.storefront,
            imagePath: screenBannerAsset('shop', state.selectedTheme.id),
            imageAlignment: Alignment.topCenter,
          ),
          const SizedBox(height: 14),
          CozyCard(
            child: Row(
              children: [
                const StudyThemeThumbnail(
                  themeId: 'cozyCafe',
                  width: 52,
                  height: 52,
                  radius: 16,
                ),
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
          SectionHeader(title: '${state.selectedTheme.name} decor'),
          const DecorCollectionProgressCard(),
          for (final shelf in state.decorShelvesByRarity.entries)
            DecorRarityShelf(rarity: shelf.key, items: shelf.value),
          const SizedBox(height: 8),
          CozyCard(
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: state.selectedTheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Each room theme has its own decoration pack. Switch themes to browse and collect their exclusive pieces.',
                    style: TextStyle(
                      color: state.selectedTheme.muted,
                      height: 1.35,
                    ),
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
              color: visualTheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: StudyThemeThumbnail(
              themeId: item.themeId,
              width: 52,
              height: 52,
              radius: 18,
            ),
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
