part of 'study_nest_state.dart';

extension StudyNestMutationsState on StudyNestState {
  // Adds a new task and saves the changed state.
  Future<StudyNestActionResult> addTask({
    required String title,
    required String details,
    required DateTime dueAt,
    required int reward,
  }) async {
    if (StudyNestAnonymousLimits.shouldEnforce(_session) &&
        _tasks.length >= StudyNestAnonymousLimits.maxTasks) {
      return StudyNestActionResult.blocked(
        StudyNestAnonymousLimits.tasksMessage(),
        requiresLoginUpgrade: true,
      );
    }
    _tasks = [
      StudyTask(
        id: StudyNestState._newId('task'),
        title: title.trim(),
        details: details.trim(),
        dueAt: dueAt,
        reward: reward,
        completedAt: null,
        rewardCollected: false,
      ),
      ..._tasks,
    ];
    await _commitChanges();
    return StudyNestActionResult.success('Task created.');
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
            id: StudyNestState._newId('coins'),
            label: 'Completed: ${task.title}',
            amount: awardedCoins,
            createdAt: now,
            sourceId: task.id,
          ),
          ..._coinLedger,
        ];
      }
    }

    await _commitChanges();
    return awardedCoins;
  }

  // Deletes a task without changing previously earned coin history.
  Future<void> deleteTask(String taskId) async {
    _tasks = _tasks.where((task) => task.id != taskId).toList();
    await _commitChanges();
  }

  // Adds a new note and saves the changed state.
  Future<StudyNestActionResult> addNote({
    required String title,
    required String body,
    required String colorName,
  }) async {
    if (StudyNestAnonymousLimits.shouldEnforce(_session) &&
        _notes.length >= StudyNestAnonymousLimits.maxNotes) {
      return StudyNestActionResult.blocked(
        StudyNestAnonymousLimits.notesMessage(),
        requiresLoginUpgrade: true,
      );
    }
    _notes = [
      StudyNote(
        id: StudyNestState._newId('note'),
        title: title.trim(),
        body: body.trim(),
        colorName: colorName,
        updatedAt: DateTime.now(),
      ),
      ..._notes,
    ];
    await _commitChanges();
    return StudyNestActionResult.success('Note saved.');
  }

  // Deletes a note by id and saves the changed state.
  Future<void> deleteNote(String noteId) async {
    _notes = _notes.where((note) => note.id != noteId).toList();
    await _commitChanges();
  }

  // Adds a new planned schedule block to the calendar.
  Future<StudyNestActionResult> addPlannerEvent({
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    required String category,
  }) async {
    if (StudyNestAnonymousLimits.shouldEnforce(_session) &&
        _events.length >= StudyNestAnonymousLimits.maxEvents) {
      return StudyNestActionResult.blocked(
        StudyNestAnonymousLimits.eventsMessage(),
        requiresLoginUpgrade: true,
      );
    }
    _events = [
      ..._events,
      PlannerEvent(
        id: StudyNestState._newId('event'),
        title: title.trim(),
        startsAt: startsAt,
        endsAt: endsAt,
        category: category,
      ),
    ];
    await _commitChanges();
    return StudyNestActionResult.success('Planner block created.');
  }

  // Deletes a planned schedule block by id.
  Future<void> deletePlannerEvent(String eventId) async {
    _events = _events.where((event) => event.id != eventId).toList();
    await _commitChanges();
  }

  // Updates the current study session goal and resets today's completion.
  Future<StudyNestActionResult> setSessionGoal(String title, int reward) async {
    final defaultGoal = StudyNestState._defaultSessionGoal();
    final alreadyCustomized =
        _sessionGoal.title != defaultGoal.title ||
        _sessionGoal.reward != defaultGoal.reward;
    if (StudyNestAnonymousLimits.shouldEnforce(_session) && alreadyCustomized) {
      return StudyNestActionResult.blocked(
        StudyNestAnonymousLimits.sessionGoalMessage(),
        requiresLoginUpgrade: true,
      );
    }
    _sessionGoal = StudySessionGoal(
      title: title.trim(),
      reward: reward,
      completedAt: null,
      updatedAt: DateTime.now(),
    );
    await _commitChanges();
    return StudyNestActionResult.success('Focus goal updated.');
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
        id: StudyNestState._newId('coins'),
        label: 'Study goal: ${_sessionGoal.title}',
        amount: _sessionGoal.reward,
        createdAt: now,
        sourceId: 'session.${now.year}.${now.month}.${now.day}',
      ),
      ..._coinLedger,
    ];
    await _commitChanges();
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
        id: StudyNestState._newId('coins'),
        label: 'Bought: ${item.title}',
        amount: -item.cost,
        createdAt: now,
        sourceId: item.id,
      ),
      ..._coinLedger,
    ];
    await _commitChanges();
    return true;
  }

  // Applies an unlocked theme to the app.
  Future<bool> applyTheme(String themeId) async {
    if (!ownsTheme(themeId)) {
      return false;
    }
    _selectedThemeId = themeId;
    await _commitChanges();
    return true;
  }
}
