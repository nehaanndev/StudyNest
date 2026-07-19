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
    if (resolution.snapshot == null && resolution.session.userId != null) {
      final cachedSnapshot = await _storage?.loadForOwner(
        resolution.session.userId!,
      );
      if (cachedSnapshot != null) {
        logStudyNestAuthDebug(
          'Hydrating exact-owner local cache after auth initialization',
          userId: resolution.session.userId,
          ownerUserId: cachedSnapshot['ownerUserId'] as String?,
          source: 'local_cache',
        );
        await _applySyncResolution(
          StudyNestSyncResolution(
            session: resolution.session,
            snapshot: cachedSnapshot,
          ),
        );
      }
    }
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
    final nextUserId = resolution.session.userId;
    if (_session.userId != null &&
        nextUserId != null &&
        _session.userId != nextUserId) {
      logStudyNestAuthDebug(
        'Clearing app state for Firebase UID change',
        userId: nextUserId,
        ownerUserId: _session.userId,
      );
      _applySnapshot(emptyStudyNestSnapshot());
      changed = true;
    }
    if (_session != resolution.session) {
      _session = resolution.session;
      changed = true;
    }
    if (resolution.snapshot != null) {
      _applySnapshot(resolution.snapshot!);
      await _storage?.save(_toSnapshot());
      changed = true;
    }
    if (changed) {
      _broadcastChange();
    }
  }

  // Replaces all domain fields from a resolved snapshot without changing storage.
  void _applySnapshot(Map<String, dynamic> snapshot) {
    final migrated = _migrateSnapshot(snapshot)!;
    _tasks = _decodeList(migrated['tasks'], StudyTask.fromJson);
    _notes = _decodeList(migrated['notes'], StudyNote.fromJson);
    _events = _decodeList(migrated['events'], PlannerEvent.fromJson);
    _coinLedger = _decodeList(migrated['coinLedger'], CoinTransaction.fromJson);
    _ownedShopItemIds = (migrated['ownedShopItemIds'] as List<dynamic>? ?? [])
        .cast<String>();
    _ownedDecorItemIds =
        (migrated['ownedDecorItemIds'] as List<dynamic>? ??
                _defaultOwnedDecorItemIds())
            .cast<String>();
    _appliedDecorItemIds =
        (migrated['appliedDecorItemIds'] as List<dynamic>? ??
                _defaultAppliedDecorItemIds())
            .cast<String>();
    _decorPositions = _decodeDecorPositions(migrated['decorPositions']);
    _selectedThemeId = migrated['selectedThemeId'] as String? ?? 'cozyCafe';
    _studySpaceStyleId = _normalizedStyleId(
      migrated['studySpaceStyleId'] as String?,
    );
    _sessionGoal = migrated['sessionGoal'] == null
        ? _defaultSessionGoal()
        : StudySessionGoal.fromJson(
            migrated['sessionGoal'] as Map<String, dynamic>,
          );
    _habits = _decodeList(migrated['habits'], StudyHabit.fromJson);
    _updatedAt =
        DateTime.tryParse(migrated['updatedAt'] as String? ?? '') ??
        DateTime.now();
    _hasCompletedWelcome = migrated['hasCompletedWelcome'] as bool? ?? true;
    _lastDestinationId = migrated['lastDestinationId'] as String? ?? 'home';
  }
}
