import 'verse_text.dart';
import 'verse_timing.dart';

/// Holds all loaded data for a single chapter in a specific version.
///
/// Combines text, timing, and audio path for convenient access
/// during playback queue construction.
class ChapterData {
  /// The Bible version identifier (e.g. 'KJV', 'CUV').
  final String version;

  /// The book number (1-66).
  final int bookNumber;

  /// The chapter number.
  final int chapter;

  /// Verse text content for this chapter.
  final List<VerseText> verses;

  /// Verse timing/subtitle data for this chapter.
  final List<VerseTiming> timings;

  /// Asset path to the audio file.
  final String audioPath;

  const ChapterData({
    required this.version,
    required this.bookNumber,
    required this.chapter,
    required this.verses,
    required this.timings,
    required this.audioPath,
  });

  /// Returns the timing for a specific verse number, or null if not found.
  VerseTiming? timingForVerse(int verseNumber) {
    try {
      return timings.firstWhere((t) => t.verse == verseNumber);
    } catch (_) {
      return null;
    }
  }

  /// Returns the text for a specific verse number, or null if not found.
  VerseText? textForVerse(int verseNumber) {
    try {
      return verses.firstWhere((v) => v.verse == verseNumber);
    } catch (_) {
      return null;
    }
  }

  /// The total number of verses in this chapter.
  int get verseCount => verses.length;
}
