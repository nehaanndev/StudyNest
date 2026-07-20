/// Base coins awarded when one Pomodoro focus cycle finishes naturally.
const int pomodoroBaseCoinReward = 15;

/// Highest configurable and payable reward for a completed task.
const int maximumTaskCoinReward = 50;

/// Stable ledger source used for the one-time task reward unlock.
const String taskCoinUnlockProductId = 'reward.taskCoins';

/// One-time price of unlocking task completion rewards.
const int taskCoinUnlockCost = 375;

/// Stable ledger source used for the one-time focus-length unlock.
const String pomodoroDurationUnlockProductId = 'reward.pomodoroDuration';

/// One-time price of unlocking selectable Pomodoro focus lengths.
const int pomodoroDurationUnlockCost = 225;

/// Default focus length for new profiles and older saved snapshots.
const int defaultPomodoroFocusMinutes = 25;

/// Supported focus lengths displayed after the duration upgrade is owned.
const List<int> pomodoroFocusMinuteOptions = [15, 20, 25, 30, 45, 60];

/// Smallest custom focus cycle accepted by the duration control.
const int minimumPomodoroFocusMinutes = 1;

/// Largest custom focus cycle accepted by the duration control.
const int maximumPomodoroFocusMinutes = 180;

/// Reports whether a preset or custom Pomodoro duration can be saved.
bool isValidPomodoroFocusMinutes(int minutes) {
  return minutes >= minimumPomodoroFocusMinutes &&
      minutes <= maximumPomodoroFocusMinutes;
}

/// Describes a permanent Pomodoro reward multiplier sold in the shop.
class CoinMultiplierOffer {
  const CoinMultiplierOffer({required this.factor, required this.cost});

  final double factor;
  final int cost;

  /// Returns the stable id stored in purchase ledger entries.
  String get id => 'reward.multiplier.${factor.toStringAsFixed(1)}';

  /// Returns the deterministic whole-coin payout for one focus cycle.
  int get cycleReward => (pomodoroBaseCoinReward * factor).round();

  /// Returns concise shop copy for the multiplier value.
  String get label => '${coinMultiplierLabel(factor)}x';
}

/// Permanent multiplier products in their intended shop display order.
const coinMultiplierOffers = [
  CoinMultiplierOffer(factor: 1.5, cost: 75),
  CoinMultiplierOffer(factor: 2, cost: 125),
  CoinMultiplierOffer(factor: 2.5, cost: 200),
  CoinMultiplierOffer(factor: 3, cost: 250),
  CoinMultiplierOffer(factor: 4, cost: 300),
  CoinMultiplierOffer(factor: 5, cost: 350),
];

/// Finds a multiplier offer by factor, or null for the base 1x rate.
CoinMultiplierOffer? coinMultiplierOfferFor(double factor) {
  for (final offer in coinMultiplierOffers) {
    if (offer.factor == factor) {
      return offer;
    }
  }
  return null;
}

/// Keeps persisted multiplier values within the permanent product catalog.
double normalizedCoinMultiplier(Object? value) {
  final factor = (value as num?)?.toDouble() ?? 1;
  return factor == 1 || coinMultiplierOfferFor(factor) != null ? factor : 1;
}

/// Keeps persisted focus lengths within the supported customization options.
int normalizedPomodoroFocusMinutes(Object? value) {
  final minutes = (value as num?)?.toInt() ?? defaultPomodoroFocusMinutes;
  return isValidPomodoroFocusMinutes(minutes)
      ? minutes
      : defaultPomodoroFocusMinutes;
}

/// Formats whole factors without a trailing decimal for compact UI labels.
String coinMultiplierLabel(double factor) {
  return factor == factor.roundToDouble()
      ? factor.toInt().toString()
      : factor.toStringAsFixed(1);
}
