import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/bible_book.dart';
import '../models/chapter_data.dart';
import '../models/verse_text.dart';
import '../models/verse_timing.dart';
import '../utils/asset_paths.dart';
import 'srt_parser.dart';

/// Loads Bible text and timing data from bundled assets (mobile) or
/// remote SRT files (web).
class AssetService {
  AssetService._();
  static final instance = AssetService._();

  final Map<String, ChapterData> _cache = {};
  static const _srtParser = SrtParser();

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

    List<VerseTiming> timings;
    List<VerseText> verses;

    if (kIsWeb) {
      // On web: fetch SRT from audio server (avoids bundling 200MB of JSON)
      timings = await _loadTimingsFromSrt(version, book, chapter);
      verses = timings
          .map((t) => VerseText(verse: t.verse, text: t.text))
          .toList();
    } else {
      final subtitlePath = AssetPaths.subtitle(version, book, chapter);
      final textPath = AssetPaths.text(version, book, chapter);
      timings = await _loadTimings(subtitlePath);
      verses = await _loadVerseTexts(textPath);
    }

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

  /// Fetch SRT from audio server and convert to [VerseTiming] list.
  Future<List<VerseTiming>> _loadTimingsFromSrt(
      String version, BibleBook book, int chapter) async {
    final srtUrl = AssetPaths.srtUrl(version, book, chapter);
    try {
      final response = await http.get(Uri.parse(srtUrl));
      if (response.statusCode != 200) return [];
      final timedVerses = _srtParser.parse(response.body);
      return timedVerses
          .map((tv) => VerseTiming(
                verse: tv.verseNumber,
                start: tv.startTime.inMilliseconds / 1000.0,
                end: tv.endTime.inMilliseconds / 1000.0,
                // Strip leading "[N] " prefix that SRT files include
                text: tv.text.replaceFirst(RegExp(r'^\[\d+\]\s*'), ''),
              ))
          .toList();
    } catch (_) {
      return [];
    }
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
