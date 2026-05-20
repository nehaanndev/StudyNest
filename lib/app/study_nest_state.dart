import 'package:flutter/material.dart';

import '../models/study_models.dart';
import '../theme/study_theme.dart';
import 'study_nest_catalog.dart';
import 'study_nest_storage.dart';

part 'study_nest_space_state.dart';

class StudyNestState extends ChangeNotifier {
  StudyNestState._({
    required StudyNestStorage? storage,
    required List<StudyTask> tasks,
    required List<StudyNote> notes,
    required List<PlannerEvent> events,
    required List<CoinTransaction> coinLedger,
    required List<String> ownedShopItemIds,
    required List<String> ownedDecorItemIds,
    required List<String> appliedDecorItemIds,
    required Map<String, Offset> decorPositions,
    required String selectedThemeId,
    required String studySpaceStyleId,
    required StudySessionGoal sessionGoal,
  }) : _storage = storage,
       _tasks = tasks,
       _notes = notes,
       _events = events,
       _coinLedger = coinLedger,
       _ownedShopItemIds = ownedShopItemIds,
       _ownedDecorItemIds = ownedDecorItemIds,
       _appliedDecorItemIds = appliedDecorItemIds,
       _decorPositions = decorPositions,
       _selectedThemeId = selectedThemeId,
       _studySpaceStyleId = studySpaceStyleId,
       _sessionGoal = sessionGoal;

  final StudyNestStorage? _storage;
  List<StudyTask> _tasks;
  List<StudyNote> _notes;
  List<PlannerEvent> _events;
  List<CoinTransaction> _coinLedger;
  List<String> _ownedShopItemIds;
  List<String> _ownedDecorItemIds;
  List<String> _appliedDecorItemIds;
  Map<String, Offset> _decorPositions;
  String _selectedThemeId;
  String _studySpaceStyleId;
  StudySessionGoal _sessionGoal;

  static const shopItems = studyThemeShopItems;

  // Loads the saved app state, or creates a starter state on first launch.
  static Future<StudyNestState> load({StudyNestStorage? storage}) async {
    final activeStorage =
        storage ?? await SharedPreferencesStudyNestStorage.create();
    try {
      final storedState = await activeStorage.load();
      if (storedState == null) {
        final state = _starterState(activeStorage);
        await state._save();
        return state;
      }
      return _fromSnapshot(activeStorage, storedState);
    } on FormatException {
      return _starterState(activeStorage);
    } on TypeError {
      return _starterState(activeStorage);
    }
  }

  // Creates an in-memory state for tests and previews without platform storage.
  static StudyNestState preview() {
    return _starterState(null);
  }

  // Returns a read-only view of all tasks.
  List<StudyTask> get tasks {
    return List.unmodifiable(_tasks);
  }

  // Returns a read-only view of all notes, newest first.
  List<StudyNote> get notes {
    final sorted = [..._notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(sorted);
  }

  // Returns a read-only view of all planned calendar events.
  List<PlannerEvent> get events {
    final sorted = [..._events]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return List.unmodifiable(sorted);
  }

  // Returns a read-only view of all coin transactions.
  List<CoinTransaction> get coinLedger {
    final sorted = [..._coinLedger]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  // Calculates the current coin balance from the full transaction ledger.
  int get coinBalance {
    return _coinLedger.fold(
      0,
      (total, transaction) => total + transaction.amount,
    );
  }

  // Finds the currently selected visual theme.
  StudyVisualTheme get selectedTheme {
    return themeById(_selectedThemeId);
  }

  // Returns the active study session goal.
  StudySessionGoal get sessionGoal {
    return _sessionGoal;
  }

  // Counts tasks that are currently complete.
  int get completedTaskCount {
    return _tasks.where((task) => task.completedAt != null).length;
  }

  // Counts tasks that still need attention.
  int get openTaskCount {
    return _tasks.where((task) => task.completedAt == null).length;
  }

  // Reports whether the user has already unlocked a shop item.
  bool ownsShopItem(String itemId) {
    return _ownedShopItemIds.contains(itemId);
  }

  // Reports whether the user has unlocked a theme.
  bool ownsTheme(String themeId) {
    if (themeId == 'cozyCafe') {
      return true;
    }
    return shopItems.any(
      (item) => item.themeId == themeId && ownsShopItem(item.id),
    );
  }

  // Returns only the events that happen on a specific calendar day.
  List<PlannerEvent> eventsForDay(DateTime day) {
    final matches = _events.where((event) {
      return event.startsAt.year == day.year &&
          event.startsAt.month == day.month &&
          event.startsAt.day == day.day;
    }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return List.unmodifiable(matches);
  }

  // Returns the next few open tasks for the dashboard.
  List<StudyTask> upcomingTasks({int limit = 3}) {
    final openTasks = _tasks.where((task) => task.completedAt == null).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return List.unmodifiable(openTasks.take(limit));
  }

  // Adds a new task and saves the changed state.
  Future<void> addTask({
    required String title,
    required String details,
    required DateTime dueAt,
    required int reward,
  }) async {
    _tasks = [
      StudyTask(
        id: _newId('task'),
        title: title.trim(),
        details: details.trim(),
        dueAt: dueAt,
        reward: reward,
        completedAt: null,
        rewardCollected: false,
      ),
      ..._tasks,
    ];
    notifyListeners();
    await _save();
  }

  // Toggles completion and awards coins once when a task is completed.
  Future<int> toggleTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) {
      return 0;
    }

    final task = _tasks[taskIndex];
    final isCompleted = task.completedAt != null;
    final now = DateTime.now();
    var awardedCoins = 0;

    if (isCompleted) {
      _tasks[taskIndex] = task.copyWith(clearCompletedAt: true);
    } else {
      awardedCoins = task.rewardCollected ? 0 : task.reward;
      _tasks[taskIndex] = task.copyWith(
        completedAt: now,
        rewardCollected: true,
      );
      if (awardedCoins > 0) {
        _coinLedger = [
          CoinTransaction(
            id: _newId('coins'),
            label: 'Completed: ${task.title}',
            amount: awardedCoins,
            createdAt: now,
            sourceId: task.id,
          ),
          ..._coinLedger,
        ];
      }
    }

    notifyListeners();
    await _save();
    return awardedCoins;
  }

  // Deletes a task without changing previously earned coin history.
  Future<void> deleteTask(String taskId) async {
    _tasks = _tasks.where((task) => task.id != taskId).toList();
    notifyListeners();
    await _save();
  }

  // Adds a new note and saves the changed state.
  Future<void> addNote({
    required String title,
    required String body,
    required String colorName,
  }) async {
    _notes = [
      StudyNote(
        id: _newId('note'),
        title: title.trim(),
        body: body.trim(),
        colorName: colorName,
        updatedAt: DateTime.now(),
      ),
      ..._notes,
    ];
    notifyListeners();
    await _save();
  }

  // Deletes a note by id and saves the changed state.
  Future<void> deleteNote(String noteId) async {
    _notes = _notes.where((note) => note.id != noteId).toList();
    notifyListeners();
    await _save();
  }

  // Adds a new planned schedule block to the calendar.
  Future<void> addPlannerEvent({
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    required String category,
  }) async {
    _events = [
      ..._events,
      PlannerEvent(
        id: _newId('event'),
        title: title.trim(),
        startsAt: startsAt,
        endsAt: endsAt,
        category: category,
      ),
    ];
    notifyListeners();
    await _save();
  }

  // Deletes a planned schedule block by id.
  Future<void> deletePlannerEvent(String eventId) async {
    _events = _events.where((event) => event.id != eventId).toList();
    notifyListeners();
    await _save();
  }

  // Updates the current study session goal and resets today's completion.
  Future<void> setSessionGoal(String title, int reward) async {
    _sessionGoal = StudySessionGoal(
      title: title.trim(),
      reward: reward,
      completedAt: null,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _save();
  }

  // Completes today's study session goal and awards coins once per day.
  Future<int> completeSessionGoal() async {
    final now = DateTime.now();
    if (_sessionGoal.isCompleteOn(now)) {
      return 0;
    }

    _sessionGoal = _sessionGoal.copyWith(completedAt: now, updatedAt: now);
    _coinLedger = [
      CoinTransaction(
        id: _newId('coins'),
        label: 'Study goal: ${_sessionGoal.title}',
        amount: _sessionGoal.reward,
        createdAt: now,
        sourceId: 'session.${now.year}.${now.month}.${now.day}',
      ),
      ..._coinLedger,
    ];
    notifyListeners();
    await _save();
    return _sessionGoal.reward;
  }

  // Purchases a shop item when the user has enough coins.
  Future<bool> buyShopItem(ShopItem item) async {
    if (ownsShopItem(item.id) || coinBalance < item.cost) {
      return false;
    }

    final now = DateTime.now();
    _ownedShopItemIds = [..._ownedShopItemIds, item.id];
    _selectedThemeId = item.themeId;
    _coinLedger = [
      CoinTransaction(
        id: _newId('coins'),
        label: 'Bought: ${item.title}',
        amount: -item.cost,
        createdAt: now,
        sourceId: item.id,
      ),
      ..._coinLedger,
    ];
    notifyListeners();
    await _save();
    return true;
  }

  // Applies an unlocked theme to the app.
  Future<bool> applyTheme(String themeId) async {
    if (!ownsTheme(themeId)) {
      return false;
    }
    _selectedThemeId = themeId;
    notifyListeners();
    await _save();
    return true;
  }

  // Saves the current state to local device storage when persistence is active.
  Future<void> _save() async {
    await _storage?.save(_toSnapshot());
  }

  // Notifies listeners and saves after extension-owned state changes.
  Future<void> _commitChanges() async {
    notifyListeners();
    await _save();
  }

  // Converts the current app state into the local persistence snapshot.
  Map<String, dynamic> _toSnapshot() {
    return {
      'tasks': _tasks.map((task) => task.toJson()).toList(),
      'notes': _notes.map((note) => note.toJson()).toList(),
      'events': _events.map((event) => event.toJson()).toList(),
      'coinLedger': _coinLedger
          .map((transaction) => transaction.toJson())
          .toList(),
      'ownedShopItemIds': _ownedShopItemIds,
      'ownedDecorItemIds': _ownedDecorItemIds,
      'appliedDecorItemIds': _appliedDecorItemIds,
      'decorPositions': _encodeDecorPositions(_decorPositions),
      'selectedThemeId': _selectedThemeId,
      'studySpaceStyleId': _studySpaceStyleId,
      'sessionGoal': _sessionGoal.toJson(),
    };
  }

  // Rebuilds app state from a storage snapshot without exposing storage details.
  static StudyNestState _fromSnapshot(
    StudyNestStorage storage,
    Map<String, dynamic> snapshot,
  ) {
    return StudyNestState._(
      storage: storage,
      tasks: _decodeList(snapshot['tasks'], StudyTask.fromJson),
      notes: _decodeList(snapshot['notes'], StudyNote.fromJson),
      events: _decodeList(snapshot['events'], PlannerEvent.fromJson),
      coinLedger: _decodeList(snapshot['coinLedger'], CoinTransaction.fromJson),
      ownedShopItemIds: (snapshot['ownedShopItemIds'] as List<dynamic>? ?? [])
          .map((itemId) => itemId as String)
          .toList(),
      ownedDecorItemIds:
          (snapshot['ownedDecorItemIds'] as List<dynamic>? ??
                  _defaultOwnedDecorItemIds())
              .map((itemId) => itemId as String)
              .toList(),
      appliedDecorItemIds:
          (snapshot['appliedDecorItemIds'] as List<dynamic>? ??
                  _defaultAppliedDecorItemIds())
              .map((itemId) => itemId as String)
              .toList(),
      decorPositions: _decodeDecorPositions(snapshot['decorPositions']),
      selectedThemeId: snapshot['selectedThemeId'] as String? ?? 'cozyCafe',
      studySpaceStyleId:
          snapshot['studySpaceStyleId'] as String? ?? 'reference',
      sessionGoal: snapshot['sessionGoal'] == null
          ? _defaultSessionGoal()
          : StudySessionGoal.fromJson(
              snapshot['sessionGoal'] as Map<String, dynamic>,
            ),
    );
  }

  // Creates a starter state that makes the app useful before user data exists.
  static StudyNestState _starterState(StudyNestStorage? storage) {
    final now = DateTime.now();
    return StudyNestState._(
      storage: storage,
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
          updatedAt: now,
        ),
        StudyNote(
          id: 'note.seed.idea',
          title: 'Cafe desk setup',
          body: 'Warm theme, soft cards, and a calm daily plan.',
          colorName: 'honey',
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
      studySpaceStyleId: 'reference',
      sessionGoal: _defaultSessionGoal(),
    );
  }

  // Creates the default session goal used before the user customizes it.
  static StudySessionGoal _defaultSessionGoal() {
    return StudySessionGoal(
      title: 'Finish one focused study block',
      reward: 25,
      completedAt: null,
      updatedAt: DateTime.now(),
    );
  }

  // Returns starter decor ownership for first launch and older snapshots.
  static List<String> _defaultOwnedDecorItemIds() {
    return const ['decor.cozyCafe.mug'];
  }

  // Returns starter applied decor for first launch and older snapshots.
  static List<String> _defaultAppliedDecorItemIds() {
    return const ['decor.cozyCafe.mug'];
  }

  // Returns starter decor positions for first launch and older snapshots.
  static Map<String, Offset> _defaultDecorPositions() {
    return {
      for (final item in studyDecorItems)
        item.id: defaultDecorPositionFor(item.id),
    };
  }

  // Converts persisted decor coordinates into normalized Offsets.
  static Map<String, Offset> _decodeDecorPositions(Object? source) {
    final fallback = _defaultDecorPositions();
    final decoded = source as Map<String, dynamic>? ?? const {};
    return {
      ...fallback,
      for (final entry in decoded.entries)
        entry.key: _decodeDecorPosition(entry.value, fallback[entry.key]),
    };
  }

  // Converts one persisted coordinate pair into a normalized Offset.
  static Offset _decodeDecorPosition(Object? source, Offset? fallback) {
    final map = source as Map<String, dynamic>?;
    if (map == null) {
      return fallback ?? const Offset(0.5, 0.6);
    }
    final x = (map['x'] as num?)?.toDouble() ?? fallback?.dx ?? 0.5;
    final y = (map['y'] as num?)?.toDouble() ?? fallback?.dy ?? 0.6;
    return Offset(
      x.clamp(0.08, 0.92).toDouble(),
      y.clamp(0.12, 0.88).toDouble(),
    );
  }

  // Converts decor positions into JSON-safe coordinate pairs.
  static Map<String, Map<String, double>> _encodeDecorPositions(
    Map<String, Offset> positions,
  ) {
    return {
      for (final entry in positions.entries)
        entry.key: {'x': entry.value.dx, 'y': entry.value.dy},
    };
  }

  // Decodes a list from persisted JSON using the provided item parser.
  static List<T> _decodeList<T>(
    Object? source,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return (source as List<dynamic>? ?? [])
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Creates a simple unique id for locally generated app records.
  static String _newId(String prefix) {
    return '$prefix.${DateTime.now().microsecondsSinceEpoch}';
  }
}
