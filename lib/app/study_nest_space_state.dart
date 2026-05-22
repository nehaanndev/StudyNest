part of 'study_nest_state.dart';

extension StudyNestSpaceState on StudyNestState {
  // Returns the selected study-space detail style.
  String get studySpaceStyleId {
    return _studySpaceStyleId;
  }

  // Returns decor that is owned, applied, and relevant to the active theme.
  List<StudyDecorItem> get appliedDecorItems {
    final appliedItems = studyDecorItems.where((item) {
      return item.themeId == selectedTheme.id &&
          _appliedDecorItemIds.contains(item.id) &&
          ownsDecorItem(item.id);
    }).toList();
    return List.unmodifiable(appliedItems);
  }

  // Returns all decor available for the currently selected theme.
  List<StudyDecorItem> get activeThemeDecorItems {
    final matchingItems = studyDecorItems.where((item) {
      return item.themeId == selectedTheme.id;
    }).toList();
    return List.unmodifiable(matchingItems);
  }

  // Returns saved normalized positions for all decor items.
  Map<String, Offset> get decorPositions {
    return Map.unmodifiable(_decorPositions);
  }

  // Returns a saved or starter normalized position for one decor item.
  Offset decorPositionFor(String decorItemId) {
    return _decorPositions[decorItemId] ?? defaultDecorPositionFor(decorItemId);
  }

  // Reports whether the user owns a decor item.
  bool ownsDecorItem(String decorItemId) {
    return _ownedDecorItemIds.contains(decorItemId);
  }

  // Reports whether a decor item is currently applied in the study space.
  bool isDecorItemApplied(String decorItemId) {
    return _appliedDecorItemIds.contains(decorItemId) &&
        ownsDecorItem(decorItemId);
  }

  // Updates the study-space visual detail style.
  Future<void> setStudySpaceStyle(String styleId) async {
    final validStyle = studySpaceLookOptions.any((option) {
      return option.id == styleId;
    });
    if (!validStyle || _studySpaceStyleId == styleId) {
      return;
    }
    _studySpaceStyleId = styleId;
    await _commitChanges();
  }

  // Purchases a decor item and applies it immediately when affordable.
  Future<StudyNestActionResult> buyDecorItem(StudyDecorItem item) async {
    if (ownsDecorItem(item.id) || coinBalance < item.cost) {
      return StudyNestActionResult.blocked('Purchase skipped.');
    }
    final purchasedDecorCount = _ownedDecorItemIds
        .where(
          (itemId) =>
              !StudyNestState._defaultOwnedDecorItemIds().contains(itemId),
        )
        .length;
    if (StudyNestAnonymousLimits.shouldEnforce(_session) &&
        purchasedDecorCount >= StudyNestAnonymousLimits.maxDecorPurchases) {
      return StudyNestActionResult.blocked(
        StudyNestAnonymousLimits.decorMessage(),
        requiresLoginUpgrade: true,
      );
    }

    final now = DateTime.now();
    _ownedDecorItemIds = [..._ownedDecorItemIds, item.id];
    _appliedDecorItemIds = {..._appliedDecorItemIds, item.id}.toList();
    _coinLedger = [
      CoinTransaction(
        id: StudyNestState._newId('coins'),
        label: 'Decor: ${item.title}',
        amount: -item.cost,
        createdAt: now,
        sourceId: item.id,
      ),
      ..._coinLedger,
    ];
    await _commitChanges();
    return StudyNestActionResult.success('Decor applied.');
  }

  // Toggles an owned decor item on or off in the study space.
  Future<bool> toggleDecorItem(String decorItemId) async {
    if (!ownsDecorItem(decorItemId)) {
      return false;
    }
    if (_appliedDecorItemIds.contains(decorItemId)) {
      _appliedDecorItemIds = _appliedDecorItemIds
          .where((itemId) => itemId != decorItemId)
          .toList();
    } else {
      _appliedDecorItemIds = [..._appliedDecorItemIds, decorItemId];
    }
    await _commitChanges();
    return true;
  }

  // Saves a normalized study-space position for a draggable decor item.
  Future<void> setDecorPosition(String decorItemId, Offset position) async {
    if (!ownsDecorItem(decorItemId)) {
      return;
    }
    _decorPositions = {
      ..._decorPositions,
      decorItemId: Offset(
        position.dx.clamp(0.08, 0.92).toDouble(),
        position.dy.clamp(0.12, 0.88).toDouble(),
      ),
    };
    await _commitChanges();
  }
}
