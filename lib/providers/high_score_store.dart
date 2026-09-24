import 'package:shared_preferences/shared_preferences.dart';

/// Persists the best score. The Android app stores this under `HIGH_SCORE`.
abstract class HighScoreStore {
  Future<int> read();

  Future<void> save(int score);
}

class SharedPrefsHighScoreStore implements HighScoreStore {
  static const String key = 'HIGH_SCORE';

  @override
  Future<int> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  @override
  Future<void> save(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, score);
  }
}

/// In-memory store for tests.
class MemoryHighScoreStore implements HighScoreStore {
  MemoryHighScoreStore([this.value = 0]);

  int value;

  @override
  Future<int> read() async => value;

  @override
  Future<void> save(int score) async {
    value = score;
  }
}
