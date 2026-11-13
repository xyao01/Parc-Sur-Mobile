import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small key → text storage that survives the app being closed (l2-mob-04).
abstract interface class LocalStore {
  String? read(String key);
  Future<void> write(String key, String? value);
}

class SharedPreferencesStore implements LocalStore {
  SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }
}

/// In memory, for tests and before `main` provides the real one.
class MemoryStore implements LocalStore {
  final Map<String, String> values = {};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

/// Overridden in `main` with [SharedPreferencesStore].
final localStoreProvider = Provider<LocalStore>((ref) => MemoryStore());
