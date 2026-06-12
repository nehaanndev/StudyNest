// Returns a local snapshot only when it is safe for the current auth user.
Map<String, dynamic> safeStudyNestLocalSnapshot(
  Map<String, dynamic> localSnapshot,
  String currentUid,
  bool allowCrossUserLocalSnapshot,
) {
  final ownerUserId = localSnapshot['ownerUserId'] as String?;
  if (ownerUserId == currentUid || allowCrossUserLocalSnapshot) {
    return localSnapshot;
  }
  return emptyStudyNestSnapshot();
}

// Compares two StudyNest snapshots using the canonical updatedAt field.
bool isRemoteStudyNestSnapshotNewer({
  required Map<String, dynamic> localSnapshot,
  required Map<String, dynamic>? remoteSnapshot,
}) {
  if (remoteSnapshot == null) return false;
  final remoteUpdatedAt = DateTime.tryParse(
    remoteSnapshot['updatedAt'] as String? ?? '',
  );
  final localUpdatedAt = DateTime.tryParse(
    localSnapshot['updatedAt'] as String? ?? '',
  );
  if (remoteUpdatedAt == null) return false;
  if (localUpdatedAt == null) return true;
  return remoteUpdatedAt.isAfter(localUpdatedAt);
}

// Creates an empty StudyNest snapshot for accounts without cloud data.
Map<String, dynamic> emptyStudyNestSnapshot() {
  final now = DateTime.now().toIso8601String();
  return {
    'schemaVersion': 2,
    'updatedAt': now,
    'tasks': const [],
    'notes': const [],
    'events': const [],
    'coinLedger': const [],
    'ownedShopItemIds': const [],
    'ownedDecorItemIds': const ['decor.cozyCafe.mug'],
    'appliedDecorItemIds': const ['decor.cozyCafe.mug'],
    'decorPositions': const {},
    'selectedThemeId': 'cozyCafe',
    'studySpaceStyleId': 'detail',
    'sessionGoal': {
      'title': 'Finish one focused study block',
      'reward': 25,
      'completedAt': null,
      'updatedAt': now,
    },
    'habits': const [],
  };
}

// Merges anonymous study data into an existing account snapshot by record id.
Map<String, dynamic> mergeStudyNestSnapshots(
  Map<String, dynamic> localSnapshot,
  Map<String, dynamic> remoteSnapshot,
) {
  final merged = {...remoteSnapshot};
  for (final key in ['tasks', 'notes', 'events', 'coinLedger', 'habits']) {
    merged[key] = _mergeRecordLists(localSnapshot[key], remoteSnapshot[key]);
  }
  merged['ownedShopItemIds'] = _mergeStringLists(
    localSnapshot['ownedShopItemIds'],
    remoteSnapshot['ownedShopItemIds'],
  );
  merged['ownedDecorItemIds'] = _mergeStringLists(
    localSnapshot['ownedDecorItemIds'],
    remoteSnapshot['ownedDecorItemIds'],
  );
  merged['appliedDecorItemIds'] = _mergeStringLists(
    localSnapshot['appliedDecorItemIds'],
    remoteSnapshot['appliedDecorItemIds'],
  );
  merged['decorPositions'] = {
    ...(remoteSnapshot['decorPositions'] as Map? ?? const {}),
    ...(localSnapshot['decorPositions'] as Map? ?? const {}),
  };
  for (final key in ['selectedThemeId', 'studySpaceStyleId', 'sessionGoal']) {
    if (localSnapshot[key] != null) merged[key] = localSnapshot[key];
  }
  merged['updatedAt'] = DateTime.now().toIso8601String();
  return merged;
}

// Combines JSON records by id while keeping local anonymous records available.
List<dynamic> _mergeRecordLists(Object? localSource, Object? remoteSource) {
  final records = <String, dynamic>{};
  for (final item in (remoteSource as List<dynamic>? ?? const [])) {
    final record = (item as Map).cast<String, dynamic>();
    final id = record['id'] as String?;
    if (id != null) records[id] = record;
  }
  for (final item in (localSource as List<dynamic>? ?? const [])) {
    final record = (item as Map).cast<String, dynamic>();
    final id = record['id'] as String?;
    if (id != null) records[id] = record;
  }
  return records.values.toList();
}

// Combines two string id lists without duplicates.
List<String> _mergeStringLists(Object? localSource, Object? remoteSource) {
  return {
    ...(remoteSource as List<dynamic>? ?? const []).cast<String>(),
    ...(localSource as List<dynamic>? ?? const []).cast<String>(),
  }.toList();
}
