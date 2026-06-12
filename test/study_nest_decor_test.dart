import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studynest/app/study_nest_catalog.dart';
import 'package:studynest/app/study_nest_state.dart';
import 'package:studynest/app/study_nest_storage.dart';

// Verifies the sprite-backed decoration collection, shop, and placement logic.
void main() {
  test('catalog references every bundled decor pack sprite', () {
    final catalogSprites = studyDecorItems
        .map((item) => item.assetPath)
        .where((path) => path.startsWith('assets/decor/packs/'))
        .toSet();
    final packedSprites = Directory('assets/decor/packs')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.png'))
        .toSet();

    expect(catalogSprites.containsAll(packedSprites), isTrue);
    expect(packedSprites.containsAll(catalogSprites), isTrue);
  });

  test('groups the decoration shop by rarity for the active theme', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );

    final shelves = state.decorShelvesByRarity;

    expect(shelves.isNotEmpty, isTrue);
    for (final shelf in shelves.entries) {
      for (final item in shelf.value) {
        expect(item.themeId, state.selectedTheme.id);
        expect(item.rarity, shelf.key);
      }
    }
  });

  test('tracks decoration collection progress for the active theme', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );

    expect(state.activeThemeTotalDecorCount, greaterThanOrEqualTo(15));
    expect(state.activeThemeOwnedDecorCount, 1);
    expect(state.ownedDecorCount, 1);
    expect(state.totalDecorCount, greaterThanOrEqualTo(75));
  });

  test('blocks decor purchases that cost more than the balance', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );
    final legendary = studyDecorItems.firstWhere((item) {
      return item.rarity == DecorRarity.legendary && item.themeId == 'cozyCafe';
    });

    final result = await state.buyDecorItem(legendary);

    expect(result.applied, isFalse);
    expect(state.ownsDecorItem(legendary.id), isFalse);
  });

  test('clamps decor placement to the item placement zone', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );
    for (final task in state.tasks) {
      await state.toggleTask(task.id);
    }
    final deskItem = studyDecorItems.firstWhere((item) {
      return item.themeId == 'cozyCafe' && item.zone == DecorZone.desk;
    });
    await state.buyDecorItem(deskItem);

    await state.setDecorPosition(deskItem.id, const Offset(0.99, 0.05));

    final saved = state.decorPositionFor(deskItem.id);
    final zoneBounds = DecorZone.desk.bounds;
    expect(saved.dx, lessThanOrEqualTo(zoneBounds.right));
    expect(saved.dy, greaterThanOrEqualTo(zoneBounds.top));
  });
}
