import 'package:flutter_test/flutter_test.dart';
import 'package:studynest/app/study_nest_auth_snapshot.dart';

// Verifies that snapshot ownership helpers preserve account boundaries.
void main() {
  test('adds the authenticated owner before persisting a snapshot', () {
    final snapshot = withStudyNestSnapshotOwner({
      'tasks': const [],
    }, 'current-user');

    expect(snapshot['ownerUserId'], 'current-user');
  });

  test('prefers a newer remote snapshot timestamp', () {
    final remoteIsNewer = isRemoteStudyNestSnapshotNewer(
      localSnapshot: {'updatedAt': '2026-07-18T18:15:00.000Z'},
      remoteSnapshot: {'updatedAt': '2026-07-18T18:16:00.000Z'},
    );

    expect(remoteIsNewer, isTrue);
  });

  test(
    'merges an intentional account transfer without dropping remote records',
    () {
      final merged = mergeStudyNestSnapshots(
        {
          'updatedAt': '2026-07-18T18:16:00.000Z',
          'tasks': [
            {'id': 'local-task', 'updatedAt': '2026-07-18T18:16:00.000Z'},
          ],
          'notes': const [],
          'events': const [],
          'coinLedger': const [],
          'habits': const [],
        },
        {
          'updatedAt': '2026-07-18T18:15:00.000Z',
          'tasks': [
            {'id': 'remote-task', 'updatedAt': '2026-07-18T18:15:00.000Z'},
          ],
          'notes': const [],
          'events': const [],
          'coinLedger': const [],
          'habits': const [],
        },
      );
      final taskIds = (merged['tasks'] as List<dynamic>)
          .map((task) => (task as Map<String, dynamic>)['id'])
          .toSet();

      expect(taskIds, {'local-task', 'remote-task'});
    },
  );

  test('deduplicates cross-device coin entries from the same source', () {
    final merged = mergeStudyNestSnapshots(
      {
        'updatedAt': '2026-07-18T18:16:00.000Z',
        'coinLedger': [
          {
            'id': 'local-purchase',
            'sourceId': 'reward.taskCoins',
            'amount': -500,
            'createdAt': '2026-07-18T18:16:00.000Z',
          },
        ],
      },
      {
        'updatedAt': '2026-07-18T18:15:00.000Z',
        'coinLedger': [
          {
            'id': 'remote-purchase',
            'sourceId': 'reward.taskCoins',
            'amount': -500,
            'createdAt': '2026-07-18T18:15:00.000Z',
          },
        ],
      },
    );
    final ledger = merged['coinLedger'] as List<dynamic>;

    expect(ledger, hasLength(1));
    expect((ledger.single as Map<String, dynamic>)['id'], 'local-purchase');
  });
}
