part of 'study_nest_state.dart';

// Creates a starter state that makes the app useful before user data exists.
StudyNestState _starterState(
  StudyNestStorage? storage,
  StudyNestSyncService syncService,
) {
  final now = DateTime.now();
  return StudyNestState._(
    storage: storage,
    syncService: syncService,
    tasks: [
      StudyTask(
        id: 'task.seed.read',
        title: 'Read chapter notes',
        details: 'Turn the hardest section into three bullet points.',
        dueAt: DateTime(now.year, now.month, now.day, 19),
        reward: 20,
        completedAt: null,
        rewardCollected: false,
      ),
      StudyTask(
        id: 'task.seed.practice',
        title: 'Practice problem set',
        details: 'Finish ten questions before checking answers.',
        dueAt: DateTime(now.year, now.month, now.day + 1, 16),
        reward: 35,
        completedAt: null,
        rewardCollected: false,
      ),
    ],
    notes: [
      StudyNote(
        id: 'note.seed.method',
        title: 'Study method',
        body: 'Use 45 minutes of focus, then write a tiny recap.',
        colorName: 'matcha',
        tags: const ['focus', 'method'],
        updatedAt: now,
      ),
      StudyNote(
        id: 'note.seed.idea',
        title: 'Cafe desk setup',
        body: 'Warm theme, soft cards, and a calm daily plan.',
        colorName: 'honey',
        tags: const ['setup'],
        updatedAt: now.subtract(const Duration(minutes: 8)),
      ),
    ],
    events: [
      PlannerEvent(
        id: 'event.seed.focus',
        title: 'Deep study block',
        startsAt: DateTime(now.year, now.month, now.day, 17),
        endsAt: DateTime(now.year, now.month, now.day, 18),
        category: 'Study',
      ),
      PlannerEvent(
        id: 'event.seed.review',
        title: 'Quick review',
        startsAt: DateTime(now.year, now.month, now.day + 1, 10),
        endsAt: DateTime(now.year, now.month, now.day + 1, 10, 30),
        category: 'Review',
      ),
    ],
    coinLedger: [
      CoinTransaction(
        id: 'coins.seed.welcome',
        label: 'Welcome bonus',
        amount: 40,
        createdAt: now,
        sourceId: 'welcome',
      ),
    ],
    ownedShopItemIds: const [],
    ownedDecorItemIds: _defaultOwnedDecorItemIds(),
    appliedDecorItemIds: _defaultAppliedDecorItemIds(),
    decorPositions: _defaultDecorPositions(),
    selectedThemeId: 'cozyCafe',
    studySpaceStyleId: 'detail',
    sessionGoal: _defaultSessionGoal(),
    updatedAt: now,
    session: StudyNestSessionState.disabled(),
  );
}

// Creates the default session goal used before the user customizes it.
StudySessionGoal _defaultSessionGoal() {
  return StudySessionGoal(
    title: 'Finish one focused study block',
    reward: 25,
    completedAt: null,
    updatedAt: DateTime.now(),
  );
}

// Returns starter decor ownership for first launch and older snapshots.
List<String> _defaultOwnedDecorItemIds() {
  return const ['decor.cozyCafe.mug'];
}

// Returns starter applied decor for first launch and older snapshots.
List<String> _defaultAppliedDecorItemIds() {
  return const ['decor.cozyCafe.mug'];
}

// Returns starter decor positions for first launch and older snapshots.
Map<String, Offset> _defaultDecorPositions() {
  return {
    for (final item in studyDecorItems)
      item.id: defaultDecorPositionFor(item.id),
  };
}

// Converts persisted decor coordinates into normalized Offsets.
Map<String, Offset> _decodeDecorPositions(Object? source) {
  final fallback = _defaultDecorPositions();
  final decoded = (source as Map?)?.cast<String, dynamic>() ?? const {};
  return {
    ...fallback,
    for (final entry in decoded.entries)
      entry.key: _decodeDecorPosition(entry.value, fallback[entry.key]),
  };
}

// Converts one persisted coordinate pair into a normalized Offset.
Offset _decodeDecorPosition(Object? source, Offset? fallback) {
  final map = source as Map<String, dynamic>?;
  if (map == null) {
    return fallback ?? const Offset(0.5, 0.6);
  }
  final x = (map['x'] as num?)?.toDouble() ?? fallback?.dx ?? 0.5;
  final y = (map['y'] as num?)?.toDouble() ?? fallback?.dy ?? 0.6;
  return Offset(x.clamp(0.08, 0.92).toDouble(), y.clamp(0.12, 0.88).toDouble());
}

// Converts decor positions into JSON-safe coordinate pairs.
Map<String, Map<String, double>> _encodeDecorPositions(
  Map<String, Offset> positions,
) {
  return {
    for (final entry in positions.entries)
      entry.key: {'x': entry.value.dx, 'y': entry.value.dy},
  };
}

// Decodes a list from persisted JSON using the provided item parser.
List<T> _decodeList<T>(
  Object? source,
  T Function(Map<String, dynamic>) fromJson,
) {
  return (source as List<dynamic>? ?? [])
      .map((item) => fromJson(item as Map<String, dynamic>))
      .toList();
}

// Creates a simple unique id for locally generated app records.
String _newId(String prefix) {
  return '$prefix.${DateTime.now().microsecondsSinceEpoch}';
}

// Normalizes saved room-style ids after the reference-to-detail rename.
String _normalizedStyleId(String? styleId) {
  if (styleId == 'reference') {
    return 'detail';
  }
  return styleId ?? 'detail';
}

// Migrates older snapshots forward before they are decoded into app state.
Map<String, dynamic>? _migrateSnapshot(Map<String, dynamic>? snapshot) {
  if (snapshot == null) {
    return null;
  }
  return {
    ...snapshot,
    'schemaVersion': (snapshot['schemaVersion'] as int?) ?? 2,
    'updatedAt':
        snapshot['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
    'studySpaceStyleId': _normalizedStyleId(
      snapshot['studySpaceStyleId'] as String?,
    ),
  };
}
