import 'package:flutter_test/flutter_test.dart';
import 'package:studynest/app/study_nest_auth_snapshot.dart';

// Verifies auth snapshot merge guards for account-bound cloud data.
void main() {
  test('empty anonymous snapshots do not reset existing account preferences', () {
    final merged = mergeStudyNestSnapshots(
      {
        'notes': const [],
        'tasks': const [],
        'events': const [],
        'coinLedger': const [],
        'habits': const [],
        'ownedShopItemIds': const [],
        'ownedDecorItemIds': const ['decor.cozyCafe.mug'],
        'appliedDecorItemIds': const ['decor.cozyCafe.mug'],
        'decorPositions': const {'decor.cozyCafe.mug': {'x': 0.57, 'y': 0.66}},
        'selectedThemeId': 'cozyCafe',
        'studySpaceStyleId': 'detail',
        'sessionGoal': const {
          'title': 'Finish one focused study block',
          'reward': 25,
        },
      },
      {
        'notes': [
          {'id': 'note.remote', 'title': 'Remote note'},
        ],
        'tasks': const [],
        'events': const [],
        'coinLedger': const [],
        'habits': const [],
        'ownedShopItemIds': const ['theme.midnightCity'],
        'ownedDecorItemIds': const ['decor.midnightCity.neonSign'],
        'appliedDecorItemIds': const ['decor.midnightCity.neonSign'],
        'decorPositions': const {
          'decor.midnightCity.neonSign': {'x': 0.76, 'y': 0.2},
        },
        'selectedThemeId': 'midnightCity',
        'studySpaceStyleId': 'simple',
        'sessionGoal': const {'title': 'Remote goal', 'reward': 50},
      },
    );

    expect(merged['selectedThemeId'], 'midnightCity');
    expect(merged['studySpaceStyleId'], 'simple');
    expect((merged['sessionGoal'] as Map)['title'], 'Remote goal');
    expect(
      (merged['decorPositions'] as Map).containsKey(
        'decor.midnightCity.neonSign',
      ),
      isTrue,
    );
    expect(hasStudyNestUserContent(merged), isTrue);
  });

  test('detects whether a snapshot belongs to the active auth user', () {
    expect(
      isStudyNestSnapshotOwnedBy({'ownerUserId': 'old-user'}, 'signed-in-user'),
      isFalse,
    );
    expect(
      isStudyNestSnapshotOwnedBy(
        {'ownerUserId': 'signed-in-user'},
        'signed-in-user',
      ),
      isTrue,
    );
  });
}
