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

  // Returns the active theme's owned decor for the inventory section.
  List<StudyDecorItem> get ownedActiveThemeDecorItems {
    final ownedItems = sortedDecorShelf(
      activeThemeDecorItems.where((item) => ownsDecorItem(item.id)),
    );
    return List.unmodifiable(ownedItems);
  }

  // Groups the active theme's decor into ordered shop shelves by rarity.
  Map<DecorRarity, List<StudyDecorItem>> get decorShelvesByRarity {
    final shelves = <DecorRarity, List<StudyDecorItem>>{};
    for (final rarity in decorRarityOrder) {
      final shelfItems = sortedDecorShelf(
        activeThemeDecorItems.where((item) => item.rarity == rarity),
      );
      if (shelfItems.isNotEmpty) {
        shelves[rarity] = List.unmodifiable(shelfItems);
      }
    }
    return Map.unmodifiable(shelves);
  }

  // Counts owned decor for the active theme's collection progress.
  int get activeThemeOwnedDecorCount {
    return activeThemeDecorItems.where((item) => ownsDecorItem(item.id)).length;
  }

  // Counts all decor available in the active theme's pack.
  int get activeThemeTotalDecorCount {
    return activeThemeDecorItems.length;
  }

  // Counts owned active-theme decor of one rarity for progress chips.
  int activeThemeOwnedDecorCountForRarity(DecorRarity rarity) {
    return activeThemeDecorItems.where((item) {
      return item.rarity == rarity && ownsDecorItem(item.id);
    }).length;
  }

  // Counts active-theme decor of one rarity for progress chips.
  int activeThemeTotalDecorCountForRarity(DecorRarity rarity) {
    return activeThemeDecorItems.where((item) => item.rarity == rarity).length;
  }

  // Counts decor items the user owns across every theme pack.
  int get ownedDecorCount {
    return studyDecorItems.where((item) => ownsDecorItem(item.id)).length;
  }

  // Counts how many catalog items exist for collection progress displays.
  int get totalDecorCount {
    return studyDecorItems.length;
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
        .where((itemId) => !_defaultOwnedDecorItemIds().contains(itemId))
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
        id: _newId('coins'),
        label: 'Decor: ${item.title}',
        amount: -item.cost,
        createdAt: now,
        sourceId: item.id,
      ),
      ..._coinLedger,
    ];
    await _commitChanges();
    return StudyNestActionResult.success('${item.title} added to your room.');
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

  // Saves a normalized study-space position clamped to the item's zone.
  Future<void> setDecorPosition(String decorItemId, Offset position) async {
    if (!ownsDecorItem(decorItemId)) {
      return;
    }
    final zone = decorItemOrNull(decorItemId)?.zone ?? DecorZone.free;
    _decorPositions = {
      ..._decorPositions,
      decorItemId: zone.clampPosition(position),
    };
    await _commitChanges();
  }
}
