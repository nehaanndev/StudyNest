/// Returns an empty, account-safe snapshot when data cannot be attributed.
///
/// This intentionally has no starter examples: it is used only while switching
/// identities, where showing no data is safer than exposing another user's data.
Map<String, dynamic> emptyStudyNestSnapshot() {
  final now = DateTime.now().toIso8601String();
  return {
    'schemaVersion': 2,
    'updatedAt': now,
    'tasks': <dynamic>[],
    'notes': <dynamic>[],
    'events': <dynamic>[],
    'coinLedger': <dynamic>[],
    'ownedShopItemIds': <dynamic>[],
    'ownedDecorItemIds': <dynamic>['decor.cozyCafe.mug'],
    'appliedDecorItemIds': <dynamic>['decor.cozyCafe.mug'],
    'decorPositions': <String, dynamic>{},
    'selectedThemeId': 'cozyCafe',
    'studySpaceStyleId': 'detail',
    'sessionGoal': {
      'title': 'Finish one focused study block',
      'reward': 25,
      'completedAt': null,
      'updatedAt': now,
    },
    'habits': <dynamic>[],
    'hasCompletedWelcome': false,
    'lastDestinationId': 'home',
  };
}

/// Adds the authenticated Firebase UID to a snapshot before it is persisted.
Map<String, dynamic> withStudyNestSnapshotOwner(
  Map<String, dynamic> snapshot,
  String userId,
) {
  return {...snapshot, 'ownerUserId': userId};
}

/// Returns local data only when it belongs to the active authenticated user.
Map<String, dynamic> safeStudyNestLocalSnapshot(
  Map<String, dynamic> localSnapshot,
  String currentUserId,
  bool allowCrossUserLocalSnapshot,
) {
  final ownerUserId = localSnapshot['ownerUserId'] as String?;
  if (ownerUserId == currentUserId || allowCrossUserLocalSnapshot) {
    return localSnapshot;
  }
  return emptyStudyNestSnapshot();
}

/// Reports whether the remote snapshot has a more recent canonical timestamp.
bool isRemoteStudyNestSnapshotNewer({
  required Map<String, dynamic> localSnapshot,
  required Map<String, dynamic>? remoteSnapshot,
}) {
  if (remoteSnapshot == null) {
    return false;
  }
  final remoteUpdatedAt = DateTime.tryParse(
    remoteSnapshot['updatedAt'] as String? ?? '',
  );
  final localUpdatedAt = DateTime.tryParse(
    localSnapshot['updatedAt'] as String? ?? '',
  );
  if (remoteUpdatedAt == null) {
    return false;
  }
  if (localUpdatedAt == null) {
    return true;
  }
  return remoteUpdatedAt.isAfter(localUpdatedAt);
}

/// Merges an intentional anonymous-to-account transfer without dropping either side.
Map<String, dynamic> mergeStudyNestSnapshots(
  Map<String, dynamic> localSnapshot,
  Map<String, dynamic> remoteSnapshot,
) {
  final localIsNewer = isRemoteStudyNestSnapshotNewer(
    localSnapshot: remoteSnapshot,
    remoteSnapshot: localSnapshot,
  );
  final preferred = localIsNewer ? localSnapshot : remoteSnapshot;
  final secondary = localIsNewer ? remoteSnapshot : localSnapshot;
  return {
    ...secondary,
    ...preferred,
    for (final key in const [
      'tasks',
      'notes',
      'events',
      'coinLedger',
      'habits',
    ])
      key: _mergeRecords(localSnapshot[key], remoteSnapshot[key]),
    for (final key in const [
      'ownedShopItemIds',
      'ownedDecorItemIds',
      'appliedDecorItemIds',
    ])
      key: _mergeStrings(localSnapshot[key], remoteSnapshot[key]),
  };
}

/// Combines record lists by id, retaining the newer version of duplicate records.
List<dynamic> _mergeRecords(Object? localValue, Object? remoteValue) {
  final merged = <String, Map<String, dynamic>>{};
  for (final record in [..._asMaps(remoteValue), ..._asMaps(localValue)]) {
    final id = record['id'] as String?;
    if (id == null) {
      continue;
    }
    final existing = merged[id];
    if (existing == null || _recordIsNewer(record, existing)) {
      merged[id] = record;
    }
  }
  return merged.values.toList();
}

/// Converts a JSON list into maps while discarding malformed entries.
List<Map<String, dynamic>> _asMaps(Object? value) {
  return (value as List<dynamic>? ?? const [])
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

/// Reports whether one record's updated or created timestamp is more recent.
bool _recordIsNewer(
  Map<String, dynamic> candidate,
  Map<String, dynamic> current,
) {
  final candidateTime = _recordTime(candidate);
  final currentTime = _recordTime(current);
  return candidateTime != null &&
      (currentTime == null || candidateTime.isAfter(currentTime));
}

/// Gets the best available timestamp from a persisted domain record.
DateTime? _recordTime(Map<String, dynamic> record) {
  return DateTime.tryParse(
    record['updatedAt'] as String? ?? record['createdAt'] as String? ?? '',
  );
}

/// Returns a de-duplicated union of two persisted string lists.
List<String> _mergeStrings(Object? localValue, Object? remoteValue) {
  return {..._asStrings(remoteValue), ..._asStrings(localValue)}.toList();
}

/// Converts a JSON list into strings while discarding malformed entries.
List<String> _asStrings(Object? value) {
  return (value as List<dynamic>? ?? const []).whereType<String>().toList();
}
