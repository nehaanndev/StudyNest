import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_rewards.dart';
import '../app/study_nest_state.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_models.dart';
import '../theme/study_theme.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/decor_shop_widgets.dart';
import '../widgets/study_photo_widgets.dart';
import '../widgets/study_station_banner.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  // Creates local pending state for coin-system purchase controls.
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Set<String> _pendingActions = {};

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
          const SectionHeader(title: 'Coin earning'),
          _TaskCoinUpgradeCard(
            pending: _pendingActions.contains(taskCoinUnlockProductId),
            onBuy: () => _buyTaskCoinUpgrade(context),
            onToggle: (enabled) => _toggleTaskCoins(context, enabled),
          ),
          const SectionHeader(title: 'Pomodoro boosts'),
          Text(
            'Choose how many coins each completed 25-minute focus cycle earns.',
            style: TextStyle(color: state.selectedTheme.muted, height: 1.35),
          ),
          const SizedBox(height: 10),
          _CoinMultiplierCard(
            factor: 1,
            reward: pomodoroBaseCoinReward,
            active: state.activeCoinMultiplier == 1,
            owned: true,
            pending: _pendingActions.contains('multiplier.1'),
            onPressed: () => _activateMultiplier(context, 1),
          ),
          const SizedBox(height: 10),
          for (final offer in coinMultiplierOffers) ...[
            _CoinMultiplierCard(
              factor: offer.factor,
              reward: offer.cycleReward,
              cost: offer.cost,
              active: state.activeCoinMultiplier == offer.factor,
              owned: state.ownsCoinMultiplier(offer),
              pending: _pendingActions.contains(offer.id),
              onPressed: () => _selectMultiplier(context, offer),
            ),
            const SizedBox(height: 10),
          ],
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

  // Purchases the permanent task reward switch while preventing repeat taps.
  Future<void> _buyTaskCoinUpgrade(BuildContext context) async {
    await _runPendingAction(taskCoinUnlockProductId, () async {
      final state = StudyNestScope.read(context);
      final missingCoins = taskCoinUnlockCost - state.coinBalance;
      final bought = await state.buyTaskCoinRewards();
      if (!context.mounted) return;
      _showMessage(
        context,
        bought
            ? 'Task coins unlocked and switched on.'
            : 'You need $missingCoins more coins to unlock task rewards.',
      );
    });
  }

  // Updates the purchased task reward switch and confirms the new mode.
  Future<void> _toggleTaskCoins(BuildContext context, bool enabled) async {
    await _runPendingAction(taskCoinUnlockProductId, () async {
      final changed = await StudyNestScope.read(
        context,
      ).setTaskCoinRewardsEnabled(enabled);
      if (!context.mounted || !changed) return;
      _showMessage(
        context,
        enabled
            ? 'Tasks will now earn their listed coins.'
            : 'Task coins paused. Pomodoro cycles still earn coins.',
      );
    });
  }

  // Purchases an unowned boost or activates it when it is already owned.
  Future<void> _selectMultiplier(
    BuildContext context,
    CoinMultiplierOffer offer,
  ) async {
    await _runPendingAction(offer.id, () async {
      final state = StudyNestScope.read(context);
      final owned = state.ownsCoinMultiplier(offer);
      final missingCoins = offer.cost - state.coinBalance;
      final applied = owned
          ? await state.activateCoinMultiplier(offer.factor)
          : await state.buyCoinMultiplier(offer);
      if (!context.mounted) return;
      _showMessage(
        context,
        applied
            ? '${offer.label} boost is active: ${offer.cycleReward} coins per cycle.'
            : 'You need $missingCoins more coins for the ${offer.label} boost.',
      );
    });
  }

  // Activates the free base reward rate.
  Future<void> _activateMultiplier(BuildContext context, double factor) async {
    await _runPendingAction('multiplier.1', () async {
      await StudyNestScope.read(context).activateCoinMultiplier(factor);
      if (context.mounted) {
        _showMessage(context, 'Base rate active: 5 coins per cycle.');
      }
    });
  }

  // Runs one shop action at a time for a product and restores its button state.
  Future<void> _runPendingAction(
    String actionId,
    Future<void> Function() action,
  ) async {
    if (_pendingActions.contains(actionId)) return;
    setState(() => _pendingActions.add(actionId));
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _pendingActions.remove(actionId));
      }
    }
  }

  // Shows concise purchase and activation feedback above the shop navigation.
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TaskCoinUpgradeCard extends StatelessWidget {
  const _TaskCoinUpgradeCard({
    required this.pending,
    required this.onBuy,
    required this.onToggle,
  });

  final bool pending;
  final VoidCallback onBuy;
  final ValueChanged<bool> onToggle;

  // Builds the permanent task-coin unlock and its post-purchase switch.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final unlocked = state.taskCoinRewardsUnlocked;
    return CozyCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              unlocked ? Icons.task_alt : Icons.lock_outline,
              color: theme.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unlocked ? 'Task coins' : 'Unlock task coins',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unlocked
                      ? state.taskCoinRewardsEnabled
                            ? 'Tasks and Pomodoro cycles both earn coins.'
                            : 'Task rewards are paused; cycles still earn coins.'
                      : 'One-time upgrade. Add task rewards alongside Pomodoro cycles.',
                  style: TextStyle(color: theme.muted, height: 1.3),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 8),
                  const CozyTag(
                    label: '$taskCoinUnlockCost coins',
                    icon: Icons.savings,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (unlocked)
            Switch(
              value: state.taskCoinRewardsEnabled,
              onChanged: pending ? null : onToggle,
            )
          else
            FilledButton.tonal(
              onPressed: pending ? null : onBuy,
              child: Text(pending ? 'Buying…' : 'Buy'),
            ),
        ],
      ),
    );
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

  // Builds one multiplier offer with payout, ownership, and active state.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final factorLabel = '${coinMultiplierLabel(factor)}x';
    return CozyCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor == 1 ? 'Original rate' : '$factorLabel boost',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '$reward coins per completed cycle',
                  style: TextStyle(color: theme.muted),
                ),
              ],
            ),
          ),
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
