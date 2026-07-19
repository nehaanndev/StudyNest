import 'dart:async';
import 'package:flutter/material.dart';

import '../models/study_models.dart';
import '../theme/study_theme.dart';
import 'study_nest_action_result.dart';
import 'study_nest_anonymous_limits.dart';
import 'study_nest_auth_debug.dart';
import 'study_nest_auth_snapshot.dart';
import 'study_nest_catalog.dart';
import 'study_nest_session.dart';
import 'study_nest_storage.dart';
import 'study_nest_sync_service.dart';

part 'study_nest_space_state.dart';
part 'study_nest_mutations_state.dart';
part 'study_nest_sync_state.dart';
part 'study_nest_snapshot_helpers.dart';

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
    required bool hasCompletedWelcome,
    required String lastDestinationId,
    String? ownerUserId,
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
       _hasCompletedWelcome = hasCompletedWelcome,
       _lastDestinationId = lastDestinationId,
       _ownerUserId = ownerUserId,
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
  bool _hasCompletedWelcome;
  String _lastDestinationId;
  String? _ownerUserId;
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
        (storage == null && StudyNestFirebaseSync.isAvailable
            ? FirebaseStudyNestSyncService()
            : const DisabledStudyNestSyncService());
    try {
      final shouldLoadLocalFirst =
          activeSyncService is DisabledStudyNestSyncService;
      final storedState = shouldLoadLocalFirst
          ? _migrateSnapshot(await activeStorage.load())
          : null;
      if (!shouldLoadLocalFirst) {
        logStudyNestAuthDebug(
          'Deferring local cache load until Firebase UID is known',
        );
      }
      if (storedState == null) {
        final state = _starterState(activeStorage, activeSyncService);
        if (shouldLoadLocalFirst) {
          await state._save();
        }
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
  Future<StudyNestActionResult> signInWithEmail(
    String email,
    String password,
  ) async {
    final resolution = await _syncService.signInWithEmail(
      _toSnapshot(),
      email,
      password,
    );
    await _applySyncResolution(resolution);
    if (resolution.session.authStatus == StudyNestAuthStatus.error) {
      return StudyNestActionResult.blocked(
        resolution.session.message ?? 'Sign-in failed.',
      );
    }
    return StudyNestActionResult.success('Signed in successfully.');
  }

  // Creates a new account with email and password.
  Future<StudyNestActionResult> signUpWithEmail(
    String email,
    String password,
  ) async {
    final resolution = await _syncService.signUpWithEmail(
      _toSnapshot(),
      email,
      password,
    );
    await _applySyncResolution(resolution);
    if (resolution.session.authStatus == StudyNestAuthStatus.error) {
      return StudyNestActionResult.blocked(
        resolution.session.message ?? 'Sign-up failed.',
      );
    }
    return StudyNestActionResult.success('Account created successfully.');
  }

  // Signs out the current user and falls back to anonymous state.
  Future<StudyNestActionResult> signOut() async {
    await _syncLatestSnapshot();
    await _storage?.clear();
    logStudyNestAuthDebug('Clearing app state for logout');
    _applySnapshot(emptyStudyNestSnapshot());
    _session = StudyNestSessionState.disabled();
    _broadcastChange();
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

  // Reports whether this device has already completed the initial welcome flow.
  bool get hasCompletedWelcome => _hasCompletedWelcome;

  // Returns the most recently selected top-level destination.
  String get lastDestinationId => _lastDestinationId;

  // Returns the current cloud-sync status.
  StudyNestSyncStatus get syncStatus => _session.syncStatus;

  // Persists completion of the first-run welcome choice before opening the app.
  Future<void> completeWelcome() async {
    if (_hasCompletedWelcome) {
      return;
    }
    _hasCompletedWelcome = true;
    await _commitChanges();
  }

  // Persists a valid top-level destination for the next app launch.
  Future<void> setLastDestination(String destinationId) async {
    if (destinationId.isEmpty || destinationId == _lastDestinationId) {
      return;
    }
    _lastDestinationId = destinationId;
    await _commitChanges();
  }

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
      'ownerUserId': _session.userId,
      'updatedAt': _updatedAt.toIso8601String(),
      'hasCompletedWelcome': _hasCompletedWelcome,
      'lastDestinationId': _lastDestinationId,
      if (_ownerUserId != null) 'ownerUserId': _ownerUserId,
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
      hasCompletedWelcome: snapshot['hasCompletedWelcome'] as bool? ?? true,
      lastDestinationId: snapshot['lastDestinationId'] as String? ?? 'home',
      ownerUserId: snapshot['ownerUserId'] as String?,
      habits: _decodeList(snapshot['habits'], StudyHabit.fromJson),
    );
  }
}
