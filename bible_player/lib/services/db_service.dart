import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bible_book.dart';
import '../models/chapter_data.dart';
import '../models/verse_text.dart';
import '../models/verse_timing.dart';

/// Loads Bible data from SQLite (mobile) or Cloudflare KV Worker API (web).
class DbService {
  static const _kvApiBase = 'https://api.bblearn.uk/bible';
  static DbService? _instance;
  static DbService get instance => _instance!;

  Database? _db;
  final Map<String, ChapterData> _cache = {};

  DbService._();

  static Future<DbService> init() async {
    final svc = DbService._();
    if (!kIsWeb) await svc._openDb();
    _instance = svc;
    return svc;
  }

  Future<void> _openDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'bible.db');
    debugPrint('[DbService] dbPath: $dbPath');

    final dbFile = File(dbPath);
    if (!dbFile.existsSync()) {
      debugPrint('[DbService] copying asset db...');
      final assetData = await rootBundle.load('assets/data/bible.db');
      final bytes = assetData.buffer.asUint8List();
      debugPrint('[DbService] asset size: ${bytes.length} bytes');
      await dbFile.writeAsBytes(bytes, flush: true);
      debugPrint('[DbService] wrote db to $dbPath');
    } else {
      debugPrint('[DbService] db already exists, size: ${dbFile.lengthSync()}');
    }

    _db = await openDatabase(dbPath, readOnly: true);
    final count = Sqflite.firstIntValue(
        await _db!.rawQuery('SELECT COUNT(*) FROM verses'));
    debugPrint('[DbService] opened db, verses: $count');
  }

  /// Load [ChapterData] for a specific version, book, and chapter.
  Future<ChapterData> loadChapter({
    required String version,
    required BibleBook book,
    required int chapter,
  }) async {
    final key = '$version:${book.number}:$chapter';
    if (_cache.containsKey(key)) return _cache[key]!;

    ChapterData data;
    if (kIsWeb) {
      data = await _loadFromKv(version: version, book: book, chapter: chapter);
    } else {
      data = await _loadFromDb(version: version, book: book, chapter: chapter);
    }

    _cache[key] = data;
    return data;
  }

  Future<ChapterData> _loadFromKv({
    required String version,
    required BibleBook book,
    required int chapter,
  }) async {
    final url = '$_kvApiBase/$version/${book.number}/$chapter';
    debugPrint('[DbService] KV fetch: $url');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('[DbService] KV API error ${response.statusCode}: $url');
    }
    final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
    debugPrint('[DbService] KV $version ${book.number}:$chapter → ${rows.length} verses');

    final timings = rows
        .map((r) => VerseTiming(
              verse: r['verse'] as int,
              start: (r['start'] as num).toDouble(),
              end: (r['end'] as num).toDouble(),
              text: r['text'] as String,
            ))
        .toList();

    final verses = rows
        .map((r) => VerseText(
              verse: r['verse'] as int,
              text: r['text'] as String,
            ))
        .toList();

    return ChapterData(
      version: version,
      bookNumber: book.number,
      chapter: chapter,
      verses: verses,
      timings: timings,
      audioPath: _audioUrl(version, book, chapter),
    );
  }

  Future<ChapterData> _loadFromDb({
    required String version,
    required BibleBook book,
    required int chapter,
  }) async {
    final rows = await _db!.query(
      'verses',
      where: 'version = ? AND book = ? AND chapter = ?',
      whereArgs: [version, book.number, chapter],
      orderBy: 'verse ASC',
    );

    debugPrint('[DbService] $version ${book.number}:$chapter → ${rows.length} verses');

    final timings = rows
        .map((r) => VerseTiming(
              verse: r['verse'] as int,
              start: (r['start'] as num).toDouble(),
              end: (r['end'] as num).toDouble(),
              text: r['text'] as String,
            ))
        .toList();

    final verses = rows
        .map((r) => VerseText(
              verse: r['verse'] as int,
              text: r['text'] as String,
            ))
        .toList();

    return ChapterData(
      version: version,
      bookNumber: book.number,
      chapter: chapter,
      verses: verses,
      timings: timings,
      audioPath: _audioUrl(version, book, chapter),
    );
  }

  /// Load chapter data for multiple versions simultaneously.
  Future<Map<String, ChapterData>> loadChapterAllVersions({
    required List<String> versions,
    required BibleBook book,
    required int chapter,
  }) async {
    final futures = versions
        .map((v) => loadChapter(version: v, book: book, chapter: chapter));
    final results = await Future.wait(futures);
    return {for (int i = 0; i < versions.length; i++) versions[i]: results[i]};
  }

  String _audioUrl(String version, BibleBook book, int chapter) {
    const base = 'https://audio.bblearn.uk/audio';
    final bookName = book.nameEn.toLowerCase().replaceAll(' ', '_');
    return '$base/$version/$bookName/$chapter.mp3';
  }

  void clearCache() => _cache.clear();
}
