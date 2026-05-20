import 'package:flutter_test/flutter_test.dart';
import 'package:studynest/app/study_nest_catalog.dart';
import 'package:studynest/app/study_nest_state.dart';
import 'package:studynest/app/study_nest_storage.dart';

// Verifies the local-first app state behaviors that power the phone MVP.
void main() {
  test('loads and saves through the storage abstraction', () async {
    final storage = InMemoryStudyNestStorage();
    final state = await StudyNestState.load(storage: storage);

    await state.addNote(
      title: 'Local storage note',
      body: 'This should survive a reload.',
      colorName: 'honey',
    );

    final reloaded = await StudyNestState.load(storage: storage);

    expect(storage.snapshot, isNotNull);
    expect(
      reloaded.notes.any((note) => note.title == 'Local storage note'),
      isTrue,
    );
  });

  test('awards task completion coins only once per task', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );
    final task = state.tasks.first;
    final startingCoins = state.coinBalance;

    final firstAward = await state.toggleTask(task.id);
    await state.toggleTask(task.id);
    final secondAward = await state.toggleTask(task.id);

    expect(firstAward, task.reward);
    expect(secondAward, 0);
    expect(state.coinBalance, startingCoins + task.reward);
  });

  test('awards the session goal once per day', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );
    final goalReward = state.sessionGoal.reward;

    final firstAward = await state.completeSessionGoal();
    final secondAward = await state.completeSessionGoal();

    expect(firstAward, goalReward);
    expect(secondAward, 0);
  });

  test('purchases and applies an unlocked theme', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );
    final item = StudyNestState.shopItems.firstWhere(
      (shopItem) => shopItem.themeId == 'gardenMatcha',
    );

    for (final task in state.tasks) {
      await state.toggleTask(task.id);
    }
    final purchased = await state.buyShopItem(item);

    expect(purchased, isTrue);
    expect(state.ownsShopItem(item.id), isTrue);
    expect(state.ownsTheme(item.themeId), isTrue);
    expect(state.selectedTheme.id, item.themeId);

    final applied = await state.applyTheme('cozyCafe');

    expect(applied, isTrue);
    expect(state.selectedTheme.id, 'cozyCafe');
  });

  test('persists study-space style and applied decor', () async {
    final storage = InMemoryStudyNestStorage();
    final state = await StudyNestState.load(storage: storage);
    final decor = studyDecorItems.firstWhere((item) {
      return item.id == 'decor.cozyCafe.brassLamp';
    });

    await state.setStudySpaceStyle('simple');
    final purchased = await state.buyDecorItem(decor);
    await state.setDecorPosition(decor.id, const Offset(0.22, 0.44));

    final reloaded = await StudyNestState.load(storage: storage);

    expect(purchased, isTrue);
    expect(reloaded.studySpaceStyleId, 'simple');
    expect(reloaded.ownsDecorItem(decor.id), isTrue);
    expect(reloaded.isDecorItemApplied(decor.id), isTrue);
    expect(
      reloaded.appliedDecorItems.any((item) => item.id == decor.id),
      isTrue,
    );
    expect(reloaded.decorPositionFor(decor.id), const Offset(0.22, 0.44));
  });
}
