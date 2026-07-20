part of 'study_nest_state.dart';

extension StudyNestRewardsState on StudyNestState {
  /// Reports whether the one-time task reward upgrade has been purchased.
  bool get taskCoinRewardsUnlocked {
    return _coinLedger.any(
      (transaction) => transaction.sourceId == taskCoinUnlockProductId,
    );
  }

  /// Reports whether completed tasks currently award their configured coins.
  bool get taskCoinRewardsEnabled {
    return taskCoinRewardsUnlocked && _taskCoinRewardsEnabled;
  }

  /// Reports whether selectable Pomodoro focus lengths have been purchased.
  bool get pomodoroDurationUnlocked {
    return _coinLedger.any(
      (transaction) => transaction.sourceId == pomodoroDurationUnlockProductId,
    );
  }

  /// Returns the saved focus length used for new Pomodoro cycles.
  int get pomodoroFocusMinutes => _pomodoroFocusMinutes;

  /// Reports whether a completed task has a matching positive payout entry.
  bool taskCoinRewardWasPaid(String taskId) {
    return _coinLedger.any(
      (transaction) => transaction.sourceId == taskId && transaction.amount > 0,
    );
  }

  /// Returns the currently selected Pomodoro coin multiplier.
  double get activeCoinMultiplier => _activeCoinMultiplier;

  /// Returns the active multiplier as concise interface copy.
  String get activeCoinMultiplierLabel {
    return '${coinMultiplierLabel(_activeCoinMultiplier)}x';
  }

  /// Returns the deterministic coin payout for the next completed focus cycle.
  int get pomodoroCycleReward {
    return (pomodoroBaseCoinReward * _activeCoinMultiplier).round();
  }

  /// Reports whether a permanent multiplier product has been purchased.
  bool ownsCoinMultiplier(CoinMultiplierOffer offer) {
    return _coinLedger.any((transaction) => transaction.sourceId == offer.id);
  }

  /// Purchases the one-time task reward switch and enables it initially.
  Future<bool> buyTaskCoinRewards() async {
    final purchaseCost = effectiveRewardShopCost(taskCoinUnlockCost);
    if (taskCoinRewardsUnlocked || coinBalance < purchaseCost) {
      return false;
    }
    final now = DateTime.now();
    _taskCoinRewardsEnabled = true;
    _coinLedger = [
      CoinTransaction(
        id: _newId('coins'),
        label: 'Unlocked task coins',
        amount: -purchaseCost,
        createdAt: now,
        sourceId: taskCoinUnlockProductId,
      ),
      ..._coinLedger,
    ];
    await _commitChanges();
    return true;
  }

  /// Enables or disables task rewards after the upgrade has been purchased.
  Future<bool> setTaskCoinRewardsEnabled(bool enabled) async {
    if (!taskCoinRewardsUnlocked) {
      return false;
    }
    if (_taskCoinRewardsEnabled == enabled) {
      return true;
    }
    _taskCoinRewardsEnabled = enabled;
    await _commitChanges();
    return true;
  }

  /// Purchases permanent access to the supported Pomodoro focus lengths.
  Future<bool> buyPomodoroDurationUnlock() async {
    final purchaseCost = effectiveRewardShopCost(pomodoroDurationUnlockCost);
    if (pomodoroDurationUnlocked || coinBalance < purchaseCost) {
      return false;
    }
    final now = DateTime.now();
    _coinLedger = [
      CoinTransaction(
        id: _newId('coins'),
        label: 'Unlocked custom Pomodoro lengths',
        amount: -purchaseCost,
        createdAt: now,
        sourceId: pomodoroDurationUnlockProductId,
      ),
      ..._coinLedger,
    ];
    await _commitChanges();
    return true;
  }

  /// Saves one supported focus length after the upgrade has been purchased.
  Future<bool> setPomodoroFocusMinutes(int minutes) async {
    if (!pomodoroDurationUnlocked || !isValidPomodoroFocusMinutes(minutes)) {
      return false;
    }
    if (_pomodoroFocusMinutes == minutes) {
      return true;
    }
    _pomodoroFocusMinutes = minutes;
    await _commitChanges();
    return true;
  }

  /// Purchases a multiplier permanently and makes it the active rate.
  Future<bool> buyCoinMultiplier(CoinMultiplierOffer offer) async {
    final catalogOffer = coinMultiplierOfferFor(offer.factor);
    final purchaseCost = effectiveRewardShopCost(catalogOffer?.cost ?? 0);
    if (catalogOffer == null ||
        catalogOffer.id != offer.id ||
        catalogOffer.cost != offer.cost ||
        ownsCoinMultiplier(catalogOffer) ||
        coinBalance < purchaseCost) {
      return false;
    }
    final now = DateTime.now();
    _activeCoinMultiplier = catalogOffer.factor;
    _coinLedger = [
      CoinTransaction(
        id: _newId('coins'),
        label: 'Bought ${catalogOffer.label} focus multiplier',
        amount: -purchaseCost,
        createdAt: now,
        sourceId: catalogOffer.id,
      ),
      ..._coinLedger,
    ];
    await _commitChanges();
    return true;
  }

  /// Activates either the free base rate or a purchased multiplier.
  Future<bool> activateCoinMultiplier(double factor) async {
    if (factor != 1) {
      final offer = coinMultiplierOfferFor(factor);
      if (offer == null || !ownsCoinMultiplier(offer)) {
        return false;
      }
    }
    if (_activeCoinMultiplier == factor) {
      return true;
    }
    _activeCoinMultiplier = factor;
    await _commitChanges();
    return true;
  }

  /// Awards a focus cycle once for its stable UI-generated source token.
  Future<int> awardPomodoroCycle(String cycleId) async {
    final sourceId = 'pomodoro.$cycleId';
    if (cycleId.isEmpty ||
        _coinLedger.any((transaction) => transaction.sourceId == sourceId)) {
      return 0;
    }
    final now = DateTime.now();
    final awardedCoins = pomodoroCycleReward;
    _coinLedger = [
      CoinTransaction(
        id: _newId('coins'),
        label: 'Completed Pomodoro focus cycle',
        amount: awardedCoins,
        createdAt: now,
        sourceId: sourceId,
      ),
      ..._coinLedger,
    ];
    await _commitChanges();
    return awardedCoins;
  }
}
