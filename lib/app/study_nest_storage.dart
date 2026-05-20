import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class StudyNestStorage {
  // Loads the persisted StudyNest snapshot, or null when no local data exists.
  Future<Map<String, dynamic>?> load();

  // Saves the complete StudyNest snapshot to the storage backend.
  Future<void> save(Map<String, dynamic> snapshot);
}

class SharedPreferencesStudyNestStorage implements StudyNestStorage {
  const SharedPreferencesStudyNestStorage(this._preferences);

  static const storageKey = 'studynest_state_v1';

  final SharedPreferences _preferences;

  // Creates the local phone storage adapter backed by SharedPreferences.
  static Future<SharedPreferencesStudyNestStorage> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesStudyNestStorage(preferences);
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    final encoded = _preferences.getString(storageKey);
    if (encoded == null) {
      return null;
    }
    return jsonDecode(encoded) as Map<String, dynamic>;
  }

  @override
  Future<void> save(Map<String, dynamic> snapshot) async {
    await _preferences.setString(storageKey, jsonEncode(snapshot));
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
  Future<void> save(Map<String, dynamic> snapshot) async {
    _snapshot = _copySnapshot(snapshot);
  }

  // Creates a deep JSON-safe snapshot copy so tests cannot mutate storage.
  static Map<String, dynamic> _copySnapshot(Map<String, dynamic> snapshot) {
    return jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
  }
}
