import 'package:flutter_test/flutter_test.dart';
import 'package:studynest/app/study_nest_catalog.dart';
import 'package:studynest/app/study_nest_session.dart';
import 'package:studynest/app/study_nest_state.dart';
import 'package:studynest/app/study_nest_storage.dart';
import 'package:studynest/app/study_nest_sync_service.dart';

// Verifies the local-first app state behaviors that power the phone MVP.
void main() {
  test('loads and saves through the storage abstraction', () async {
    final storage = InMemoryStudyNestStorage();
    final state = await StudyNestState.load(storage: storage);

    final result = await state.addNote(
      title: 'Local storage note',
      body: 'This should survive a reload.',
      colorName: 'honey',
    );

    final reloaded = await StudyNestState.load(storage: storage);

    expect(result.applied, isTrue);
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
    final purchaseResult = await state.buyDecorItem(decor);
    await state.setDecorPosition(decor.id, const Offset(0.22, 0.44));

    final reloaded = await StudyNestState.load(storage: storage);

    expect(purchaseResult.applied, isTrue);
    expect(reloaded.studySpaceStyleId, 'simple');
    expect(reloaded.ownsDecorItem(decor.id), isTrue);
    expect(reloaded.isDecorItemApplied(decor.id), isTrue);
    expect(
      reloaded.appliedDecorItems.any((item) => item.id == decor.id),
      isTrue,
    );
    expect(reloaded.decorPositionFor(decor.id), const Offset(0.22, 0.44));
  });

  test('migrates legacy reference style snapshots to detail', () async {
    final storage = InMemoryStudyNestStorage(
      snapshot: {
        'studySpaceStyleId': 'reference',
        'tasks': const [],
        'notes': const [],
        'events': const [],
        'coinLedger': const [],
        'ownedShopItemIds': const [],
        'ownedDecorItemIds': const ['decor.cozyCafe.mug'],
        'appliedDecorItemIds': const ['decor.cozyCafe.mug'],
        'decorPositions': const {},
        'selectedThemeId': 'cozyCafe',
        'sessionGoal': {
          'title': 'Finish one focused study block',
          'reward': 25,
          'completedAt': null,
          'updatedAt': '2026-05-21T20:30:00.000Z',
        },
      },
    );

    final state = await StudyNestState.load(storage: storage);

    expect(state.studySpaceStyleId, 'detail');
    expect(storage.snapshot?['studySpaceStyleId'], 'detail');
    expect(storage.snapshot?['schemaVersion'], 2);
  });

  test(
    'enforces anonymous note limits when cloud auth stays anonymous',
    () async {
      final syncService = _FakeSyncService(
        session: const StudyNestSessionState(
          authStatus: StudyNestAuthStatus.ready,
          syncStatus: StudyNestSyncStatus.idle,
          cloudEnabled: true,
          isAnonymous: true,
          hasPendingSync: false,
          userId: 'anon-123',
        ),
      );
      final state = await StudyNestState.load(
        storage: InMemoryStudyNestStorage(),
        syncService: syncService,
      );

      for (var index = state.notes.length; index < 10; index++) {
        final result = await state.addNote(
          title: 'Note $index',
          body: 'Body $index',
          colorName: 'matcha',
        );
        expect(result.applied, isTrue);
      }

      final blocked = await state.addNote(
        title: 'Too many',
        body: 'Blocked',
        colorName: 'matcha',
      );

      expect(blocked.applied, isFalse);
      expect(blocked.requiresLoginUpgrade, isTrue);
    },
  );

  test(
    'keeps pending sync state when the cloud adapter reports offline',
    () async {
      final syncService = _FakeSyncService(
        session: const StudyNestSessionState(
          authStatus: StudyNestAuthStatus.ready,
          syncStatus: StudyNestSyncStatus.idle,
          cloudEnabled: true,
          isAnonymous: true,
          hasPendingSync: false,
          userId: 'anon-123',
        ),
        syncResolution: const StudyNestSyncResolution(
          session: StudyNestSessionState(
            authStatus: StudyNestAuthStatus.ready,
            syncStatus: StudyNestSyncStatus.offline,
            cloudEnabled: true,
            isAnonymous: true,
            hasPendingSync: true,
            userId: 'anon-123',
            message: 'Offline.',
          ),
        ),
      );
      final state = await StudyNestState.load(
        storage: InMemoryStudyNestStorage(),
        syncService: syncService,
      );

      await state.addTask(
        title: 'Offline task',
        details: '',
        dueAt: DateTime.now(),
        reward: 10,
      );

      expect(state.hasPendingSync, isTrue);
      expect(state.syncStatus, StudyNestSyncStatus.offline);
    },
  );

  test('hydrates from a newer cloud snapshot during initialization', () async {
    final syncService = _FakeSyncService(
      session: const StudyNestSessionState(
        authStatus: StudyNestAuthStatus.ready,
        syncStatus: StudyNestSyncStatus.idle,
        cloudEnabled: true,
        isAnonymous: true,
        hasPendingSync: false,
        userId: 'anon-123',
      ),
      initializeResolution: StudyNestSyncResolution(
        session: const StudyNestSessionState(
          authStatus: StudyNestAuthStatus.ready,
          syncStatus: StudyNestSyncStatus.idle,
          cloudEnabled: true,
          isAnonymous: true,
          hasPendingSync: false,
          userId: 'anon-123',
        ),
        snapshot: {
          'schemaVersion': 2,
          'updatedAt': '2026-05-21T20:30:00.000Z',
          'tasks': const [],
          'notes': [
            {
              'id': 'note.cloud',
              'title': 'Cloud note',
              'body': 'Loaded from Firebase',
              'colorName': 'matcha',
              'updatedAt': '2026-05-21T20:30:00.000Z',
            },
          ],
          'events': const [],
          'coinLedger': const [],
          'ownedShopItemIds': const [],
          'ownedDecorItemIds': const ['decor.cozyCafe.mug'],
          'appliedDecorItemIds': const ['decor.cozyCafe.mug'],
          'decorPositions': const {},
          'selectedThemeId': 'cozyCafe',
          'studySpaceStyleId': 'detail',
          'sessionGoal': {
            'title': 'Cloud focus goal',
            'reward': 20,
            'completedAt': null,
            'updatedAt': '2026-05-21T20:30:00.000Z',
          },
        },
      ),
    );

    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
      syncService: syncService,
    );

    expect(state.notes.single.title, 'Cloud note');
    expect(state.sessionGoal.title, 'Cloud focus goal');
  });
}

class _FakeSyncService implements StudyNestSyncService {
  _FakeSyncService({
    required this.session,
    this.initializeResolution,
    this.syncResolution,
  });

  final StudyNestSessionState session;
  final StudyNestSyncResolution? initializeResolution;
  final StudyNestSyncResolution? syncResolution;

  @override
  Stream<void> get retryEvents => const Stream<void>.empty();

  // Returns the configured initialization result for deterministic state tests.
  @override
  Future<StudyNestSyncResolution> initialize(
    Map<String, dynamic> localSnapshot,
  ) async {
    return initializeResolution ?? StudyNestSyncResolution(session: session);
  }

  // Returns the configured sync result for deterministic state tests.
  @override
  Future<StudyNestSyncResolution> sync(
    Map<String, dynamic> localSnapshot,
  ) async {
    return syncResolution ?? StudyNestSyncResolution(session: session);
  }

  // Returns the configured link result for deterministic auth-upgrade tests.
  @override
  Future<StudyNestSyncResolution> linkWithGoogle(
    Map<String, dynamic> localSnapshot,
  ) async {
    return StudyNestSyncResolution(session: session);
  }

  @override
  Future<StudyNestSyncResolution> signInWithEmail(
    Map<String, dynamic> localSnapshot,
    String email,
    String password,
  ) async {
    return StudyNestSyncResolution(session: session);
  }

  @override
  Future<StudyNestSyncResolution> signUpWithEmail(
    Map<String, dynamic> localSnapshot,
    String email,
    String password,
  ) async {
    return StudyNestSyncResolution(session: session);
  }

  @override
  Future<StudyNestSyncResolution> signOut(
    Map<String, dynamic> localSnapshot,
  ) async {
    return StudyNestSyncResolution(session: session);
  }

  @override
  Future<String?> sendPasswordResetEmail(String email) async => null;

  // Leaves nothing to clean up for the fake sync adapter.
  @override
  Future<void> dispose() async {}
}
