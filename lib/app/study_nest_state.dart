import 'dart:async';

import 'package:flutter/material.dart';

import '../models/study_models.dart';
import '../theme/study_theme.dart';
import 'study_nest_action_result.dart';
import 'study_nest_anonymous_limits.dart';
import 'study_nest_catalog.dart';
import 'study_nest_session.dart';
import 'study_nest_storage.dart';
import 'study_nest_sync_service.dart';

part 'study_nest_space_state.dart';
part 'study_nest_mutations_state.dart';
part 'study_nest_sync_state.dart';

class StudyNestState extends ChangeNotifier {
  StudyNestState._({
    required StudyNestStorage? storage,
    required StudyNestSyncService syncService,
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
    required DateTime updatedAt,
    required StudyNestSessionState session,
    List<StudyHabit>? habits,
  }) : _storage = storage,
       _syncService = syncService,
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
       _sessionGoal = sessionGoal,
       _updatedAt = updatedAt,
       _session = session,
       _habits = habits ?? [];

  final StudyNestStorage? _storage;
  final StudyNestSyncService _syncService;
  List<StudyTask> _tasks;
  List<StudyNote> _notes;
  List<StudyHabit> _habits;
  List<PlannerEvent> _events;
  List<CoinTransaction> _coinLedger;
  List<String> _ownedShopItemIds;
  List<String> _ownedDecorItemIds;
  List<String> _appliedDecorItemIds;
  Map<String, Offset> _decorPositions;
  String _selectedThemeId;
  String _studySpaceStyleId;
  StudySessionGoal _sessionGoal;
  DateTime _updatedAt;
  StudyNestSessionState _session;
  StreamSubscription<void>? _retrySubscription;

  static const shopItems = studyThemeShopItems;

  // Loads the saved app state, or creates a starter state on first launch.
  static Future<StudyNestState> load({
    StudyNestStorage? storage,
    StudyNestSyncService? syncService,
  }) async {
    final activeStorage =
        storage ?? await SharedPreferencesStudyNestStorage.create();
    final activeSyncService =
        syncService ??
        (StudyNestFirebaseSync.isAvailable
            ? FirebaseStudyNestSyncService()
            : const DisabledStudyNestSyncService());
    try {
      final storedState = _migrateSnapshot(await activeStorage.load());
      if (storedState == null) {
        final state = _starterState(activeStorage, activeSyncService);
        await state._save();
        await state._initializeCloudSync();
        return state;
      }
      await activeStorage.save(storedState);
      final state = _fromSnapshot(
        activeStorage,
        activeSyncService,
        storedState,
      );
      await state._initializeCloudSync();
      return state;
    } on FormatException {
      final state = _starterState(activeStorage, activeSyncService);
      await state._initializeCloudSync();
      return state;
    } on TypeError {
      final state = _starterState(activeStorage, activeSyncService);
      await state._initializeCloudSync();
      return state;
    }
  }

  // Creates an in-memory state for tests and previews without platform storage.
  static StudyNestState preview() {
    return _starterState(null, const DisabledStudyNestSyncService());
  }

  // Returns a read-only view of all habits.
  List<StudyHabit> get habits => List.unmodifiable(_habits);

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

  // Adds a new habit while preserving the public StudyNestState API.
  Future<void> addHabit({required String name, required String emoji}) {
    return StudyNestMutationsState(this).addHabit(name: name, emoji: emoji);
  }

  // Toggles a habit day while preserving the public StudyNestState API.
  Future<void> toggleHabitDay(String habitId, DateTime day) {
    return StudyNestMutationsState(this).toggleHabitDay(habitId, day);
  }

  // Deletes a habit while preserving the public StudyNestState API.
  Future<void> deleteHabit(String habitId) {
    return StudyNestMutationsState(this).deleteHabit(habitId);
  }

  // Adds a new task while preserving the public StudyNestState API.
  Future<StudyNestActionResult> addTask({
    required String title,
    required String details,
    required DateTime dueAt,
    required int reward,
    String priority = 'Medium',
  }) {
    return StudyNestMutationsState(this).addTask(
      title: title,
      details: details,
      dueAt: dueAt,
      reward: reward,
      priority: priority,
    );
  }

  // Toggles task completion while preserving the public StudyNestState API.
  Future<int> toggleTask(String taskId) {
    return StudyNestMutationsState(this).toggleTask(taskId);
  }

  // Updates an existing task while preserving reward collection history.
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String details,
    required DateTime dueAt,
    required int reward,
    String? priority,
  }) {
    return StudyNestMutationsState(this).updateTask(
      taskId: taskId,
      title: title,
      details: details,
      dueAt: dueAt,
      reward: reward,
      priority: priority,
    );
  }

  // Deletes a task while preserving the public StudyNestState API.
  Future<void> deleteTask(String taskId) {
    return StudyNestMutationsState(this).deleteTask(taskId);
  }

  // Adds a new note while preserving the public StudyNestState API.
  Future<StudyNestActionResult> addNote({
    required String title,
    required String body,
    required String colorName,
    List<String> tags = const [],
    String folder = '',
    String noteType = 'note',
    String? contentJson,
  }) {
    return StudyNestMutationsState(this).addNote(
      title: title,
      body: body,
      colorName: colorName,
      tags: tags,
      folder: folder,
      noteType: noteType,
      contentJson: contentJson,
    );
  }

  // Updates an existing note while refreshing its modified timestamp.
  Future<void> updateNote({
    required String noteId,
    required String title,
    required String body,
    required String colorName,
    required List<String> tags,
    String? folder,
    String? contentJson,
  }) {
    return StudyNestMutationsState(this).updateNote(
      noteId: noteId,
      title: title,
      body: body,
      colorName: colorName,
      tags: tags,
      folder: folder,
      contentJson: contentJson,
    );
  }

  // Deletes a note while preserving the public StudyNestState API.
  Future<void> deleteNote(String noteId) {
    return StudyNestMutationsState(this).deleteNote(noteId);
  }

  // Adds a planner event while preserving the public StudyNestState API.
  Future<StudyNestActionResult> addPlannerEvent({
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    required String category,
  }) {
    return StudyNestMutationsState(this).addPlannerEvent(
      title: title,
      startsAt: startsAt,
      endsAt: endsAt,
      category: category,
    );
  }

  // Updates an existing planner block.
  Future<void> updatePlannerEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    required String category,
  }) {
    return StudyNestMutationsState(this).updatePlannerEvent(
      eventId: eventId,
      title: title,
      startsAt: startsAt,
      endsAt: endsAt,
      category: category,
    );
  }

  // Deletes a planner event while preserving the public StudyNestState API.
  Future<void> deletePlannerEvent(String eventId) {
    return StudyNestMutationsState(this).deletePlannerEvent(eventId);
  }

  // Updates the focus goal while preserving the public StudyNestState API.
  Future<StudyNestActionResult> setSessionGoal(String title, int reward) {
    return StudyNestMutationsState(this).setSessionGoal(title, reward);
  }

  // Completes today's focus goal while preserving the public StudyNestState API.
  Future<int> completeSessionGoal() {
    return StudyNestMutationsState(this).completeSessionGoal();
  }

  // Purchases a shop item while preserving the public StudyNestState API.
  Future<bool> buyShopItem(ShopItem item) {
    return StudyNestMutationsState(this).buyShopItem(item);
  }

  // Applies a theme while preserving the public StudyNestState API.
  Future<bool> applyTheme(String themeId) {
    return StudyNestMutationsState(this).applyTheme(themeId);
  }

  // Signs in with email and password, linking anonymous data into the account.
  Future<StudyNestActionResult> signInWithEmail(String email, String password) async {
    final resolution = await _syncService.signInWithEmail(_toSnapshot(), email, password);
    await _applySyncResolution(resolution);
    if (resolution.session.authStatus == StudyNestAuthStatus.error) {
      return StudyNestActionResult.blocked(resolution.session.message ?? 'Sign-in failed.');
    }
    return StudyNestActionResult.success('Signed in successfully.');
  }

  // Creates a new account with email and password.
  Future<StudyNestActionResult> signUpWithEmail(String email, String password) async {
    final resolution = await _syncService.signUpWithEmail(_toSnapshot(), email, password);
    await _applySyncResolution(resolution);
    if (resolution.session.authStatus == StudyNestAuthStatus.error) {
      return StudyNestActionResult.blocked(resolution.session.message ?? 'Sign-up failed.');
    }
    return StudyNestActionResult.success('Account created successfully.');
  }

  // Signs out the current user and falls back to anonymous state.
  Future<StudyNestActionResult> signOut() async {
    final resolution = await _syncService.signOut(_toSnapshot());
    await _applySyncResolution(resolution);
    return StudyNestActionResult.success('Signed out.');
  }

  // Sends a password reset email; returns an error message or null on success.
  Future<String?> sendPasswordResetEmail(String email) {
    return _syncService.sendPasswordResetEmail(email);
  }

  // Returns the signed-in user's email when available.
  String? get userEmail => _session.userEmail;

  // Returns the signed-in user's display name when available.
  String? get userDisplayName => _session.userDisplayName;

  // Returns whether the Firebase identity is still anonymous.
  bool get isAnonymousUser => _session.isAnonymous;

  // Returns the current cloud-auth status.
  StudyNestAuthStatus get authStatus => _session.authStatus;

  // Returns the current cloud-sync status.
  StudyNestSyncStatus get syncStatus => _session.syncStatus;

  // Saves the current state to local device storage when persistence is active.
  Future<void> _save() async {
    _updatedAt = DateTime.now();
    await _storage?.save(_toSnapshot());
    await _syncLatestSnapshot();
  }

  // Notifies listeners and saves after extension-owned state changes.
  Future<void> _commitChanges() async {
    _broadcastChange();
    await _save();
  }

  // Broadcasts a state change without re-saving the snapshot.
  void _broadcastChange() {
    notifyListeners();
  }

  // Converts the current app state into the local persistence snapshot.
  Map<String, dynamic> _toSnapshot() {
    return {
      'schemaVersion': 2,
      'updatedAt': _updatedAt.toIso8601String(),
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
      'habits': _habits.map((h) => h.toJson()).toList(),
    };
  }

  // Rebuilds app state from a storage snapshot without exposing storage details.
  static StudyNestState _fromSnapshot(
    StudyNestStorage storage,
    StudyNestSyncService syncService,
    Map<String, dynamic> snapshot,
  ) {
    return StudyNestState._(
      storage: storage,
      syncService: syncService,
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
      studySpaceStyleId: _normalizedStyleId(
        snapshot['studySpaceStyleId'] as String?,
      ),
      sessionGoal: snapshot['sessionGoal'] == null
          ? _defaultSessionGoal()
          : StudySessionGoal.fromJson(
              snapshot['sessionGoal'] as Map<String, dynamic>,
            ),
      updatedAt:
          DateTime.tryParse(snapshot['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      session: StudyNestSessionState.disabled(),
      habits: _decodeList(snapshot['habits'], StudyHabit.fromJson),
    );
  }

  // Creates a starter state that makes the app useful before user data exists.
  static StudyNestState _starterState(
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
    final decoded = (source as Map?)?.cast<String, dynamic>() ?? const {};
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

  // Normalizes saved room-style ids after the reference-to-detail rename.
  static String _normalizedStyleId(String? styleId) {
    if (styleId == 'reference') {
      return 'detail';
    }
    return styleId ?? 'detail';
  }

  // Migrates older snapshots forward before they are decoded into app state.
  static Map<String, dynamic>? _migrateSnapshot(
    Map<String, dynamic>? snapshot,
  ) {
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
}
