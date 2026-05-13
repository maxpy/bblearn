import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user preferences (play sequence, step speeds, last position).
class PrefsService {
  static const _keySequence = 'play_sequence_name';
  static const _keyStepSpeeds = 'step_speeds';
  static const _keyLastBook = 'last_book';
  static const _keyLastChapter = 'last_chapter';

  static PrefsService? _instance;
  static PrefsService get instance => _instance!;

  final SharedPreferences _prefs;
  PrefsService._(this._prefs);

  static Future<PrefsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = PrefsService._(prefs);
    return _instance!;
  }

  /// Save the selected sequence name.
  Future<void> saveSequenceName(String name) =>
      _prefs.setString(_keySequence, name);

  /// Load the saved sequence name, or null if not set.
  String? loadSequenceName() => _prefs.getString(_keySequence);

  /// Save per-version speeds as JSON: {"KJV": 1.2, "CUV": 0.8}
  Future<void> saveStepSpeeds(Map<String, double> speeds) =>
      _prefs.setString(_keyStepSpeeds, jsonEncode(speeds));

  /// Load per-version speeds.
  Map<String, double> loadStepSpeeds() {
    final raw = _prefs.getString(_keyStepSpeeds);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  /// Save last played book/chapter.
  Future<void> saveLastPosition(int bookNumber, int chapter) async {
    await _prefs.setInt(_keyLastBook, bookNumber);
    await _prefs.setInt(_keyLastChapter, chapter);
  }

  /// Load last played book number (default 41 = Mark).
  int loadLastBook() => _prefs.getInt(_keyLastBook) ?? 41;

  /// Load last played chapter (default 1).
  int loadLastChapter() => _prefs.getInt(_keyLastChapter) ?? 1;
}
