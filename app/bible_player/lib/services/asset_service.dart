import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/bible_book.dart';
import '../models/chapter_data.dart';
import '../models/verse_text.dart';
import '../models/verse_timing.dart';
import '../utils/asset_paths.dart';

/// Loads Bible text and timing data from bundled assets.
class AssetService {
  AssetService._();
  static final instance = AssetService._();

  final Map<String, ChapterData> _cache = {};

  String _key(String version, int bookNumber, int chapter) =>
      '$version:$bookNumber:$chapter';

  /// Load [ChapterData] for a specific version, book, and chapter.
  Future<ChapterData> loadChapter({
    required String version,
    required BibleBook book,
    required int chapter,
  }) async {
    final key = _key(version, book.number, chapter);
    if (_cache.containsKey(key)) return _cache[key]!;

    final audioPath = AssetPaths.audioUrl(version, book, chapter);
    final subtitlePath = AssetPaths.subtitle(version, book, chapter);
    final textPath = AssetPaths.text(version, book, chapter);

    final timings = await _loadTimings(subtitlePath);
    final verses = await _loadVerseTexts(textPath);

    final data = ChapterData(
      version: version,
      bookNumber: book.number,
      chapter: chapter,
      verses: verses,
      timings: timings,
      audioPath: audioPath,
    );

    _cache[key] = data;
    return data;
  }

  /// Load chapter data for multiple versions simultaneously.
  Future<Map<String, ChapterData>> loadChapterAllVersions({
    required List<String> versions,
    required BibleBook book,
    required int chapter,
  }) async {
    final futures = versions.map(
      (v) => loadChapter(version: v, book: book, chapter: chapter),
    );
    final results = await Future.wait(futures);
    return {for (int i = 0; i < versions.length; i++) versions[i]: results[i]};
  }

  Future<List<VerseTiming>> _loadTimings(String path) async {
    try {
      final jsonStr = await rootBundle.loadString(path);
      final Map<String, dynamic> json =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> verses = json['verses'] as List<dynamic>;
      return verses
          .map((e) => VerseTiming.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VerseText>> _loadVerseTexts(String path) async {
    try {
      final jsonStr = await rootBundle.loadString(path);
      final Map<String, dynamic> json =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> verses = json['verses'] as List<dynamic>;
      return verses
          .map((e) => VerseText.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void clearCache() => _cache.clear();
}
