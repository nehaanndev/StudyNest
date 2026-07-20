import 'package:flutter_test/flutter_test.dart';
import 'package:studynest/app/study_nest_auth_snapshot.dart';
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

  test('persists the entry choice and last selected destination', () async {
    final storage = InMemoryStudyNestStorage();
    final state = await StudyNestState.load(storage: storage);

    await state.completeWelcome();
    await state.setLastDestination('habits');
    final reloaded = await StudyNestState.load(storage: storage);

    expect(reloaded.hasCompletedWelcome, isTrue);
    expect(reloaded.lastDestinationId, 'habits');
  });

  test('does not award tasks before the optional upgrade', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );
    final task = state.tasks.first;
    final startingCoins = state.coinBalance;

    final firstAward = await state.toggleTask(task.id);
    await state.toggleTask(task.id);
    final secondAward = await state.toggleTask(task.id);

    expect(firstAward, 0);
    expect(secondAward, 0);
    expect(state.coinBalance, startingCoins);
  });

  test('completes the session goal without minting coins', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );
    final firstAward = await state.completeSessionGoal();
    final secondAward = await state.completeSessionGoal();

    expect(firstAward, 0);
    expect(secondAward, 0);
    expect(state.sessionGoal.isCompleteOn(DateTime.now()), isTrue);
  });

  test('purchases and applies an unlocked theme', () async {
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(),
    );
    final item = StudyNestState.shopItems.firstWhere(
      (shopItem) => shopItem.themeId == 'gardenMatcha',
    );

    for (var cycle = 0; cycle < 14; cycle++) {
      await state.awardPomodoroCycle('theme-$cycle');
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
    // Completes focus cycles so the lamp purchase is affordable.
    for (var cycle = 0; cycle < 16; cycle++) {
      await state.awardPomodoroCycle('decor-$cycle');
    }
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
    expect(storage.snapshot?['schemaVersion'], 4);
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

  test('clears previous user data before creating a logout session', () async {
    final storage = InMemoryStudyNestStorage();
    final syncService = _FakeSyncService(
      session: const StudyNestSessionState(
        authStatus: StudyNestAuthStatus.ready,
        syncStatus: StudyNestSyncStatus.idle,
        cloudEnabled: true,
        isAnonymous: false,
        hasPendingSync: false,
        userId: 'user-a',
        userEmail: 'a@example.com',
      ),
      signOutResolution: const StudyNestSyncResolution(
        session: StudyNestSessionState(
          authStatus: StudyNestAuthStatus.ready,
          syncStatus: StudyNestSyncStatus.idle,
          cloudEnabled: true,
          isAnonymous: true,
          hasPendingSync: false,
          userId: 'anon-b',
        ),
      ),
    );
    final state = await StudyNestState.load(
      storage: storage,
      syncService: syncService,
    );

    await state.addNote(
      title: 'Private user A note',
      body: 'This must not follow the next login.',
      colorName: 'matcha',
    );
    await state.addHabit(name: 'Private habit', emoji: 'P');
    await state.signOut();

    final signOutSnapshot = syncService.signOutSnapshot;
    final signOutNotes = signOutSnapshot?['notes'] as List<dynamic>? ?? [];
    final signOutHabits = signOutSnapshot?['habits'] as List<dynamic>? ?? [];

    expect(
      state.notes.any((note) => note.title == 'Private user A note'),
      isFalse,
    );
    expect(state.habits.any((habit) => habit.name == 'Private habit'), isFalse);
    expect(storage.snapshot, isNull);
    expect(
      signOutNotes.any((note) {
        return (note as Map<String, dynamic>)['title'] == 'Private user A note';
      }),
      isFalse,
    );
    expect(
      signOutHabits.any((habit) {
        return (habit as Map<String, dynamic>)['name'] == 'Private habit';
      }),
      isFalse,
    );
  });

  test('merges anonymous records into an existing account snapshot', () {
    final merged = mergeStudyNestSnapshots(
      {
        'notes': [
          {'id': 'note.anon', 'title': 'Anonymous note'},
        ],
        'tasks': [
          {'id': 'task.anon', 'title': 'Anonymous task'},
        ],
        'events': const [],
        'coinLedger': [
          {'id': 'coin.anon', 'label': 'Anonymous coins'},
        ],
        'habits': [
          {'id': 'habit.anon', 'name': 'Anonymous habit'},
        ],
        'ownedShopItemIds': const ['theme.anon'],
        'ownedDecorItemIds': const ['decor.cozyCafe.mug'],
        'appliedDecorItemIds': const ['decor.cozyCafe.mug'],
        'decorPositions': const {},
        'selectedThemeId': 'gardenMatcha',
        'studySpaceStyleId': 'simple',
        'sessionGoal': const {'title': 'Anonymous goal', 'reward': 10},
      },
      {
        'notes': [
          {'id': 'note.remote', 'title': 'Remote note'},
        ],
        'tasks': const [],
        'events': const [],
        'coinLedger': const [],
        'habits': const [],
        'ownedShopItemIds': const ['theme.remote'],
        'ownedDecorItemIds': const [],
        'appliedDecorItemIds': const [],
        'decorPositions': const {},
      },
    );

    final notes = merged['notes'] as List<dynamic>;
    final tasks = merged['tasks'] as List<dynamic>;
    final habits = merged['habits'] as List<dynamic>;
    final coinLedger = merged['coinLedger'] as List<dynamic>;

    expect(notes.any((note) => (note as Map)['id'] == 'note.anon'), isTrue);
    expect(notes.any((note) => (note as Map)['id'] == 'note.remote'), isTrue);
    expect(tasks.any((task) => (task as Map)['id'] == 'task.anon'), isTrue);
    expect(habits.any((habit) => (habit as Map)['id'] == 'habit.anon'), isTrue);
    expect(
      coinLedger.any((coins) => (coins as Map)['id'] == 'coin.anon'),
      isTrue,
    );
    expect(
      merged['ownedShopItemIds'],
      containsAll(['theme.anon', 'theme.remote']),
    );
    expect(merged['selectedThemeId'], 'gardenMatcha');
    expect(merged['studySpaceStyleId'], 'simple');
    expect((merged['sessionGoal'] as Map)['title'], 'Anonymous goal');
  });

  test('rejects unowned legacy cache for signed-in users', () {
    final safeSnapshot = safeStudyNestLocalSnapshot(
      {
        'notes': const [
          {'id': 'note.old-user', 'title': 'Old user note'},
        ],
      },
      'signed-in-user',
      false,
    );

    expect(safeSnapshot['notes'], isEmpty);
  });

  test('user A cache does not hydrate for user B on the same device', () async {
    final storage = InMemoryStudyNestStorage(
      snapshot: {
        'schemaVersion': 2,
        'ownerUserId': 'user-a',
        'updatedAt': '2026-05-21T20:30:00.000Z',
        'tasks': [
          {
            'id': 'task.user-a',
            'title': 'User A private task',
            'details': '',
            'dueAt': '2026-05-22T20:30:00.000Z',
            'reward': 10,
            'completedAt': null,
            'rewardCollected': false,
          },
        ],
        'notes': [
          {
            'id': 'note.user-a',
            'title': 'User A private note',
            'body': 'Should not appear.',
            'colorName': 'matcha',
            'updatedAt': '2026-05-21T20:30:00.000Z',
          },
        ],
        'events': const [],
        'coinLedger': [
          {
            'id': 'coins.user-a',
            'label': 'User A coins',
            'amount': 99,
            'createdAt': '2026-05-21T20:30:00.000Z',
            'sourceId': 'private',
          },
        ],
        'ownedShopItemIds': const ['theme.user-a'],
        'ownedDecorItemIds': const ['decor.cozyCafe.brassLamp'],
        'appliedDecorItemIds': const ['decor.cozyCafe.brassLamp'],
        'decorPositions': const {},
        'selectedThemeId': 'gardenMatcha',
        'studySpaceStyleId': 'simple',
        'sessionGoal': {
          'title': 'User A goal',
          'reward': 25,
          'completedAt': null,
          'updatedAt': '2026-05-21T20:30:00.000Z',
        },
        'habits': [
          {
            'id': 'habit.user-a',
            'name': 'User A habit',
            'emoji': 'A',
            'streak': 3,
            'completions': const [],
          },
        ],
      },
    );
    final syncService = _FakeSyncService(
      session: const StudyNestSessionState(
        authStatus: StudyNestAuthStatus.ready,
        syncStatus: StudyNestSyncStatus.idle,
        cloudEnabled: true,
        isAnonymous: false,
        hasPendingSync: false,
        userId: 'user-b',
      ),
      initializeResolution: StudyNestSyncResolution(
        session: const StudyNestSessionState(
          authStatus: StudyNestAuthStatus.ready,
          syncStatus: StudyNestSyncStatus.idle,
          cloudEnabled: true,
          isAnonymous: false,
          hasPendingSync: false,
          userId: 'user-b',
        ),
        snapshot: {...emptyStudyNestSnapshot(), 'ownerUserId': 'user-b'},
      ),
    );

    final state = await StudyNestState.load(
      storage: storage,
      syncService: syncService,
    );

    expect(state.userId, 'user-b');
    expect(state.notes.any((note) => note.id == 'note.user-a'), isFalse);
    expect(state.tasks.any((task) => task.id == 'task.user-a'), isFalse);
    expect(state.habits.any((habit) => habit.id == 'habit.user-a'), isFalse);
    expect(
      state.coinLedger.any((coins) => coins.id == 'coins.user-a'),
      isFalse,
    );
    expect(state.ownsShopItem('theme.user-a'), isFalse);
    expect(state.sessionGoal.title, isNot('User A goal'));
    expect(state.studySpaceStyleId, isNot('simple'));
  });
}

class _FakeSyncService implements StudyNestSyncService {
  _FakeSyncService({
    required this.session,
    this.initializeResolution,
    this.syncResolution,
    this.signOutResolution,
  });

  final StudyNestSessionState session;
  final StudyNestSyncResolution? initializeResolution;
  final StudyNestSyncResolution? syncResolution;
  final StudyNestSyncResolution? signOutResolution;
  Map<String, dynamic>? signOutSnapshot;

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
    signOutSnapshot = localSnapshot;
    return signOutResolution ?? StudyNestSyncResolution(session: session);
  }

  @override
  Future<String?> sendPasswordResetEmail(String email) async => null;

  // Leaves nothing to clean up for the fake sync adapter.
  @override
  Future<void> dispose() async {}
}
