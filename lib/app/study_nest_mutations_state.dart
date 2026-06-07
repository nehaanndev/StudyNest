part of 'study_nest_state.dart';

extension StudyNestMutationsState on StudyNestState {
  // Adds a new habit and saves the changed state.
  Future<void> addHabit({required String name, required String emoji}) async {
    _habits = [
      ..._habits,
      StudyHabit(
        id: _newId('habit'),
        name: name,
        emoji: emoji,
        streak: 0,
        completions: [],
      ),
    ];
    await _commitChanges();
  }

  // Toggles a habit completion for a given day and recalculates streak.
  Future<void> toggleHabitDay(String habitId, DateTime day) async {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;
    final habit = _habits[idx];
    final dayStr = day.toIso8601String().split('T').first;
    final already = habit.completions.any((c) => c.startsWith(dayStr));
    final newCompletions = already
        ? habit.completions.where((c) => !c.startsWith(dayStr)).toList()
        : [...habit.completions, dayStr];
    var streak = 0;
    var check = DateTime.now();
    while (newCompletions.any(
      (c) => c.startsWith(check.toIso8601String().split('T').first),
    )) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    _habits[idx] = habit.copyWith(completions: newCompletions, streak: streak);
    await _commitChanges();
  }

  // Deletes a habit and saves the changed state.
  Future<void> deleteHabit(String habitId) async {
    _habits = _habits.where((h) => h.id != habitId).toList();
    await _commitChanges();
  }

  // Adds a new task and saves the changed state.
  Future<StudyNestActionResult> addTask({
    required String title,
    required String details,
    required DateTime dueAt,
    required int reward,
    String priority = 'Medium',
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
        id: _newId('task'),
        title: title.trim(),
        details: details.trim(),
        dueAt: dueAt,
        reward: reward,
        completedAt: null,
        rewardCollected: false,
        priority: priority,
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

    await _commitChanges();
    return awardedCoins;
  }

  // Updates editable task fields without resetting completion or coin history.
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String details,
    required DateTime dueAt,
    required int reward,
    String? priority,
  }) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) {
      return;
    }
    _tasks[taskIndex] = _tasks[taskIndex].copyWith(
      title: title.trim(),
      details: details.trim(),
      dueAt: dueAt,
      reward: reward,
      priority: priority,
    );
    await _commitChanges();
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
    List<String> tags = const [],
    String folder = '',
    String noteType = 'note',
    String? contentJson,
  }) async {
    if (StudyNestAnonymousLimits.shouldEnforce(_session) &&
        _notes.length >= StudyNestAnonymousLimits.maxNotes) {
      return StudyNestActionResult.blocked(
        StudyNestAnonymousLimits.notesMessage(),
        requiresLoginUpgrade: true,
      );
    }
    final now = DateTime.now();
    _notes = [
      StudyNote(
        id: _newId('note'),
        title: title.trim(),
        body: body.trim(),
        colorName: colorName,
        tags: _normalizedTags(tags),
        folder: folder,
        noteType: noteType,
        contentJson: contentJson,
        updatedAt: now,
        createdAt: now,
      ),
      ..._notes,
    ];
    await _commitChanges();
    return StudyNestActionResult.success('Note saved.');
  }

  // Updates note content, color, tags, folder, type, and modified timestamp.
  Future<void> updateNote({
    required String noteId,
    required String title,
    required String body,
    required String colorName,
    required List<String> tags,
    String? folder,
    String? contentJson,
  }) async {
    final noteIndex = _notes.indexWhere((note) => note.id == noteId);
    if (noteIndex == -1) {
      return;
    }
    _notes[noteIndex] = _notes[noteIndex].copyWith(
      title: title.trim(),
      body: body.trim(),
      colorName: colorName,
      tags: _normalizedTags(tags),
      folder: folder,
      contentJson: contentJson,
      updatedAt: DateTime.now(),
    );
    await _commitChanges();
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
        id: _newId('event'),
        title: title.trim(),
        startsAt: startsAt,
        endsAt: endsAt,
        category: category,
      ),
    ];
    await _commitChanges();
    return StudyNestActionResult.success('Planner block created.');
  }

  // Updates an existing planned schedule block.
  Future<void> updatePlannerEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    required String category,
  }) async {
    final eventIndex = _events.indexWhere((event) => event.id == eventId);
    if (eventIndex == -1) {
      return;
    }
    _events[eventIndex] = _events[eventIndex].copyWith(
      title: title.trim(),
      startsAt: startsAt,
      endsAt: endsAt,
      category: category,
    );
    await _commitChanges();
  }

  // Deletes a planned schedule block by id.
  Future<void> deletePlannerEvent(String eventId) async {
    _events = _events.where((event) => event.id != eventId).toList();
    await _commitChanges();
  }

  // Normalizes custom note tags for storage and filtering.
  List<String> _normalizedTags(List<String> tags) {
    final normalized =
        tags
            .map((tag) => tag.trim().toLowerCase())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return normalized;
  }

  // Updates the current study session goal and resets today's completion.
  Future<StudyNestActionResult> setSessionGoal(String title, int reward) async {
    final defaultGoal = _defaultSessionGoal();
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
        id: _newId('coins'),
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
        id: _newId('coins'),
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
