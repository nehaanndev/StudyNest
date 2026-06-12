import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'study_nest_auth_debug.dart';

abstract class StudyNestStorage {
  // Loads the persisted StudyNest snapshot, or null when no local data exists.
  Future<Map<String, dynamic>?> load();

  // Loads a snapshot only when its cached owner exactly matches the user id.
  Future<Map<String, dynamic>?> loadForOwner(String ownerUserId);

  // Saves the complete StudyNest snapshot to the storage backend.
  Future<void> save(Map<String, dynamic> snapshot);

  // Clears locally cached StudyNest snapshots for auth boundary changes.
  Future<void> clear();
}

class SharedPreferencesStudyNestStorage implements StudyNestStorage {
  const SharedPreferencesStudyNestStorage(this._preferences);

  static const storageKey = 'studynest_state_v2';
  static const legacyStorageKey = 'studynest_state_v1';

  final SharedPreferences _preferences;

  // Creates the local phone storage adapter backed by SharedPreferences.
  static Future<SharedPreferencesStudyNestStorage> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesStudyNestStorage(preferences);
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    final encoded =
        _preferences.getString(storageKey) ??
        _preferences.getString(legacyStorageKey);
    logStudyNestAuthDebug(
      'Loading unscoped local cache',
      cacheKey: storageKey,
      source: 'shared_preferences',
    );
    if (encoded == null) {
      return null;
    }
    return jsonDecode(encoded) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>?> loadForOwner(String ownerUserId) async {
    final key = _userStorageKey(ownerUserId);
    logStudyNestAuthDebug(
      'Loading scoped local cache',
      userId: ownerUserId,
      cacheKey: key,
      source: 'shared_preferences',
    );
    final encoded = _preferences.getString(key);
    if (encoded == null) {
      return null;
    }
    final snapshot = jsonDecode(encoded) as Map<String, dynamic>;
    final snapshotOwner = snapshot['ownerUserId'] as String?;
    if (snapshotOwner != ownerUserId) {
      logStudyNestAuthDebug(
        'Ignoring local cache with mismatched owner',
        userId: ownerUserId,
        ownerUserId: snapshotOwner,
        cacheKey: key,
      );
      return null;
    }
    return snapshot;
  }

  @override
  Future<void> save(Map<String, dynamic> snapshot) async {
    final ownerUserId = snapshot['ownerUserId'] as String?;
    final encoded = jsonEncode(snapshot);
    if (ownerUserId != null && ownerUserId.isNotEmpty) {
      final key = _userStorageKey(ownerUserId);
      logStudyNestAuthDebug(
        'Saving scoped local cache',
        userId: ownerUserId,
        ownerUserId: ownerUserId,
        cacheKey: key,
        source: 'shared_preferences',
      );
      await _preferences.setString(key, encoded);
      await _preferences.remove(storageKey);
      await _preferences.remove(legacyStorageKey);
      return;
    }
    logStudyNestAuthDebug(
      'Saving unscoped local cache',
      cacheKey: storageKey,
      source: 'shared_preferences',
    );
    await _preferences.setString(storageKey, encoded);
  }

  @override
  Future<void> clear() async {
    final keys = _preferences.getKeys().where((key) {
      return key == storageKey ||
          key == legacyStorageKey ||
          key.startsWith('$storageKey.');
    }).toList();
    for (final key in keys) {
      logStudyNestAuthDebug('Clearing local cache', cacheKey: key);
      await _preferences.remove(key);
    }
  }

  // Returns the cache key dedicated to a single Firebase Auth user id.
  static String _userStorageKey(String ownerUserId) {
    return '$storageKey.$ownerUserId';
  }
}

class InMemoryStudyNestStorage implements StudyNestStorage {
  InMemoryStudyNestStorage({Map<String, dynamic>? snapshot})
    : _snapshot = snapshot == null ? null : _copySnapshot(snapshot);

  Map<String, dynamic>? _snapshot;

  // Returns a copy of the current in-memory snapshot for storage tests.
  Map<String, dynamic>? get snapshot {
    final storedSnapshot = _snapshot;
    if (storedSnapshot == null) {
      return null;
    }
    return _copySnapshot(storedSnapshot);
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    return snapshot;
  }

  @override
  Future<Map<String, dynamic>?> loadForOwner(String ownerUserId) async {
    final storedSnapshot = snapshot;
    if (storedSnapshot?['ownerUserId'] != ownerUserId) {
      return null;
    }
    return storedSnapshot;
  }

  @override
  Future<void> save(Map<String, dynamic> snapshot) async {
    _snapshot = _copySnapshot(snapshot);
  }

  @override
  Future<void> clear() async {
    _snapshot = null;
  }

  // Creates a deep JSON-safe snapshot copy so tests cannot mutate storage.
  static Map<String, dynamic> _copySnapshot(Map<String, dynamic> snapshot) {
    return jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
  }
}
