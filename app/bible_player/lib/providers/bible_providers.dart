import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/verse_text.dart';
import '../models/verse_timing.dart';
import '../services/bible_data_service.dart';

// ── Bible version ────────────────────────────────────────────────────────────

/// Current Bible version ("KJV" or "CUV").
final bibleVersionProvider = StateProvider<String>((ref) => 'KJV');

// ── Book list ────────────────────────────────────────────────────────────────

/// Loads the book list for the current version.
final booksProvider = FutureProvider<List<Book>>((ref) {
  final version = ref.watch(bibleVersionProvider);
  return BibleDataService.instance.loadBooks(version);
});

/// OT books only.
final otBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  return ref.watch(booksProvider).whenData(
        (books) => books.where((b) => b.testament == 'OT').toList(),
      );
});

/// NT books only.
final ntBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  return ref.watch(booksProvider).whenData(
        (books) => books.where((b) => b.testament == 'NT').toList(),
      );
});

// ── Selected book / chapter ──────────────────────────────────────────────────

final selectedBookProvider = StateProvider<Book?>((ref) => null);
final selectedChapterProvider = StateProvider<int>((ref) => 1);

// ── Verse text & timing ─────────────────────────────────────────────────────

/// Verse text for the currently selected book+chapter.
final verseTextProvider = FutureProvider<List<VerseText>>((ref) {
  final version = ref.watch(bibleVersionProvider);
  final book = ref.watch(selectedBookProvider);
  final chapter = ref.watch(selectedChapterProvider);
  if (book == null) return Future.value([]);
  return BibleDataService.instance.loadVerseText(
    version: version,
    book: book,
    chapter: chapter,
  );
});

/// Verse timings (subtitles) for the currently selected book+chapter.
final verseTimingProvider = FutureProvider<List<VerseTiming>>((ref) {
  final version = ref.watch(bibleVersionProvider);
  final book = ref.watch(selectedBookProvider);
  final chapter = ref.watch(selectedChapterProvider);
  if (book == null) return Future.value([]);
  return BibleDataService.instance.loadVerseTimings(
    version: version,
    book: book,
    chapter: chapter,
  );
});
