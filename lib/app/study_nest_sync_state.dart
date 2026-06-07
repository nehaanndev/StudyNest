part of 'study_nest_state.dart';

extension StudyNestSyncState on StudyNestState {
  // Reports whether a local change is still waiting for a cloud upload.
  bool get hasPendingSync {
    return _session.hasPendingSync;
  }

  // Returns the last successful cloud sync timestamp when available.
  DateTime? get lastSyncedAt {
    return _session.lastSyncedAt;
  }

  // Returns the latest auth or sync message intended for the interface.
  String? get sessionMessage {
    return _session.message;
  }

  // Reports whether this build currently has Firebase cloud support configured.
  bool get cloudSyncEnabled {
    return _session.cloudEnabled;
  }

  // Returns the current user's Firebase UID when available.
  String? get userId => _session.userId;

  // Starts Firebase auth and subscribes to retry signals for offline sync.
  Future<void> _initializeCloudSync() async {
    _retrySubscription?.cancel();
    _retrySubscription = _syncService.retryEvents.listen((_) {
      unawaited(_syncLatestSnapshot());
    });
    final resolution = await _syncService.initialize(_toSnapshot());
    await _applySyncResolution(resolution);
  }

  // Links the anonymous Firebase account to Google and keeps the same data.
  Future<StudyNestActionResult> linkAnonymousAccountWithGoogle() async {
    final resolution = await _syncService.linkWithGoogle(_toSnapshot());
    await _applySyncResolution(resolution);
    if (resolution.session.authStatus == StudyNestAuthStatus.error) {
      return StudyNestActionResult.blocked(
        resolution.session.message ?? 'Google sign-in failed.',
      );
    }
    return StudyNestActionResult.success(
      resolution.session.message ?? 'Google account linked.',
    );
  }

  // Pushes the latest local snapshot into the configured sync service.
  Future<void> _syncLatestSnapshot() async {
    final resolution = await _syncService.sync(_toSnapshot());
    await _applySyncResolution(resolution);
  }

  // Applies returned sync state and optionally replaces local data from cloud.
  Future<void> _applySyncResolution(StudyNestSyncResolution resolution) async {
    var changed = false;
    if (resolution.snapshot != null) {
      _applySnapshot(resolution.snapshot!);
      await _storage?.save(_toSnapshot());
      changed = true;
    }
    if (_session != resolution.session) {
      _session = resolution.session;
      changed = true;
    }
    if (changed) {
      _broadcastChange();
    }
  }

  // Replaces all domain fields from a resolved snapshot without changing storage.
  void _applySnapshot(Map<String, dynamic> snapshot) {
    final migrated = StudyNestState._migrateSnapshot(snapshot)!;
    _tasks = StudyNestState._decodeList(migrated['tasks'], StudyTask.fromJson);
    _notes = StudyNestState._decodeList(migrated['notes'], StudyNote.fromJson);
    _events = StudyNestState._decodeList(
      migrated['events'],
      PlannerEvent.fromJson,
    );
    _coinLedger = StudyNestState._decodeList(
      migrated['coinLedger'],
      CoinTransaction.fromJson,
    );
    _ownedShopItemIds = (migrated['ownedShopItemIds'] as List<dynamic>? ?? [])
        .cast<String>();
    _ownedDecorItemIds =
        (migrated['ownedDecorItemIds'] as List<dynamic>? ??
                StudyNestState._defaultOwnedDecorItemIds())
            .cast<String>();
    _appliedDecorItemIds =
        (migrated['appliedDecorItemIds'] as List<dynamic>? ??
                StudyNestState._defaultAppliedDecorItemIds())
            .cast<String>();
    _decorPositions = StudyNestState._decodeDecorPositions(
      migrated['decorPositions'],
    );
    _selectedThemeId = migrated['selectedThemeId'] as String? ?? 'cozyCafe';
    _studySpaceStyleId = StudyNestState._normalizedStyleId(
      migrated['studySpaceStyleId'] as String?,
    );
    _sessionGoal = migrated['sessionGoal'] == null
        ? StudyNestState._defaultSessionGoal()
        : StudySessionGoal.fromJson(
            migrated['sessionGoal'] as Map<String, dynamic>,
          );
    _updatedAt =
        DateTime.tryParse(migrated['updatedAt'] as String? ?? '') ??
        DateTime.now();
  }
}
