import 'package:flutter_test/flutter_test.dart';
import 'package:studynest/app/study_nest_auth_snapshot.dart';
import 'package:studynest/app/study_nest_rewards.dart';
import 'package:studynest/app/study_nest_state.dart';
import 'package:studynest/app/study_nest_storage.dart';

// Verifies Pomodoro rewards, optional task coins, multipliers, and persistence.
void main() {
  test(
    'new profiles earn five coins from each unique Pomodoro cycle',
    () async {
      final state = await StudyNestState.load(
        storage: InMemoryStudyNestStorage(),
      );

      final first = await state.awardPomodoroCycle('focus-1');
      final duplicate = await state.awardPomodoroCycle('focus-1');

      expect(first, pomodoroBaseCoinReward);
      expect(duplicate, 0);
      expect(state.coinBalance, pomodoroBaseCoinReward);
      expect(state.taskCoinRewardsUnlocked, isFalse);
      expect(state.taskCoinRewardsEnabled, isFalse);
      expect(state.pomodoroDurationUnlocked, isFalse);
      expect(state.pomodoroFocusMinutes, defaultPomodoroFocusMinutes);
    },
  );

  test(
    'task switch costs 500 and disabled completions stay consumed',
    () async {
      final state = await _loadStateWithCoins(1000);
      final bought = await state.buyTaskCoinRewards();
      final task = state.tasks.first;

      expect(bought, isTrue);
      expect(state.coinBalance, 1000 - taskCoinUnlockCost);
      expect(state.taskCoinRewardsEnabled, isTrue);

      await state.setTaskCoinRewardsEnabled(false);
      final disabledAward = await state.toggleTask(task.id);
      await state.toggleTask(task.id);
      await state.setTaskCoinRewardsEnabled(true);
      final laterAward = await state.toggleTask(task.id);

      expect(disabledAward, 0);
      expect(laterAward, 0);
    },
  );

  test(
    'task switch blocks insufficient and repeat purchases and persists',
    () async {
      final insufficient = await _loadStateWithCoins(taskCoinUnlockCost - 1);
      expect(await insufficient.buyTaskCoinRewards(), isFalse);
      expect(insufficient.taskCoinRewardsUnlocked, isFalse);

      final storage = InMemoryStudyNestStorage(
        snapshot: _snapshotWithCoins(taskCoinUnlockCost),
      );
      final state = await StudyNestState.load(storage: storage);
      expect(await state.buyTaskCoinRewards(), isTrue);
      expect(await state.buyTaskCoinRewards(), isFalse);
      await state.setTaskCoinRewardsEnabled(false);

      final reloaded = await StudyNestState.load(storage: storage);
      expect(reloaded.coinBalance, 0);
      expect(reloaded.taskCoinRewardsUnlocked, isTrue);
      expect(reloaded.taskCoinRewardsEnabled, isFalse);
    },
  );

  test('task values and payouts are capped at fifty coins', () async {
    final state = await _loadStateWithCoins(1000);
    await state.buyTaskCoinRewards();
    final created = await state.addTask(
      title: 'Oversized reward',
      details: '',
      dueAt: DateTime.now(),
      reward: 500,
    );
    final task = state.tasks.firstWhere(
      (candidate) => candidate.title == 'Oversized reward',
    );

    expect(created.applied, isTrue);
    expect(task.reward, maximumTaskCoinReward);
    expect(await state.toggleTask(task.id), maximumTaskCoinReward);
  });

  test(
    'focus-length unlock costs 300 and persists supported selections',
    () async {
      final insufficient = await _loadStateWithCoins(
        pomodoroDurationUnlockCost - 1,
      );
      expect(await insufficient.buyPomodoroDurationUnlock(), isFalse);
      expect(await insufficient.setPomodoroFocusMinutes(45), isFalse);

      final storage = InMemoryStudyNestStorage(
        snapshot: _snapshotWithCoins(pomodoroDurationUnlockCost),
      );
      final state = await StudyNestState.load(storage: storage);
      expect(await state.buyPomodoroDurationUnlock(), isTrue);
      expect(await state.buyPomodoroDurationUnlock(), isFalse);
      expect(state.coinBalance, 0);
      expect(await state.setPomodoroFocusMinutes(10), isFalse);
      expect(await state.setPomodoroFocusMinutes(45), isTrue);

      final reloaded = await StudyNestState.load(storage: storage);
      expect(reloaded.pomodoroDurationUnlocked, isTrue);
      expect(reloaded.pomodoroFocusMinutes, 45);
    },
  );

  test(
    'all permanent multiplier tiers use deterministic rounded payouts',
    () async {
      final storage = InMemoryStudyNestStorage(
        snapshot: _snapshotWithCoins(10000),
      );
      final state = await StudyNestState.load(storage: storage);
      const expectedRewards = [8, 10, 13, 15, 20, 25];
      const expectedCosts = [100, 175, 250, 325, 400, 475];

      expect(
        coinMultiplierOffers.every((offer) => offer.cost < taskCoinUnlockCost),
        isTrue,
      );
      expect(coinMultiplierOffers.map((offer) => offer.cost), expectedCosts);

      for (var index = 0; index < coinMultiplierOffers.length; index++) {
        final offer = coinMultiplierOffers[index];
        expect(await state.buyCoinMultiplier(offer), isTrue);
        expect(state.ownsCoinMultiplier(offer), isTrue);
        expect(state.pomodoroCycleReward, expectedRewards[index]);
        expect(
          await state.awardPomodoroCycle('boost-$index'),
          expectedRewards[index],
        );
      }

      final reloaded = await StudyNestState.load(storage: storage);
      expect(reloaded.activeCoinMultiplier, 5);
      expect(reloaded.pomodoroCycleReward, 25);
      expect(coinMultiplierOffers.every(reloaded.ownsCoinMultiplier), isTrue);
    },
  );

  test('rejects forged multiplier factors and prices', () async {
    final state = await _loadStateWithCoins(1000);
    const forged = CoinMultiplierOffer(factor: 100, cost: -500);

    expect(await state.buyCoinMultiplier(forged), isFalse);
    expect(state.coinBalance, 1000);
    expect(state.activeCoinMultiplier, 1);
    expect(state.pomodoroCycleReward, pomodoroBaseCoinReward);
  });

  test('session goals track progress but never award coins', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );

    expect(await state.completeSessionGoal(), 0);
    expect(state.coinBalance, 0);
    expect(state.sessionGoal.isCompleteOn(DateTime.now()), isTrue);
  });
}

// Loads a starter-shaped state with a controlled test-only coin balance.
Future<StudyNestState> _loadStateWithCoins(int coins) {
  return StudyNestState.load(
    storage: InMemoryStudyNestStorage(snapshot: _snapshotWithCoins(coins)),
  );
}

// Builds an account-safe snapshot containing one synthetic funding entry.
Map<String, dynamic> _snapshotWithCoins(int coins) {
  final snapshot = emptyStudyNestSnapshot();
  snapshot['tasks'] = [
    {
      'id': 'task.test',
      'title': 'Test task',
      'details': '',
      'dueAt': DateTime.now().toIso8601String(),
      'reward': 20,
      'completedAt': null,
      'rewardCollected': false,
      'priority': 'Medium',
    },
  ];
  snapshot['coinLedger'] = [
    {
      'id': 'coins.test-funding',
      'label': 'Test funding',
      'amount': coins,
      'createdAt': DateTime.now().toIso8601String(),
      'sourceId': 'test-funding',
    },
  ];
  return snapshot;
}
