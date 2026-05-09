/// Data models for verse text and audio timing information.
///
/// Used to synchronize displayed text with audio playback.
library;

/// A single verse's text content.
class VerseText {
  /// The verse number within its chapter.
  final int verse;

  /// The text content of this verse.
  final String text;

  /// Creates a [VerseText] instance.
  const VerseText({
    required this.verse,
    required this.text,
  });

  @override
  String toString() => 'VerseText($verse)';
}

/// Timing information for a single verse within an audio track.
class VerseTiming {
  /// The verse number within its chapter.
  final int verse;

  /// Start time in seconds from the beginning of the audio.
  final double start;

  /// End time in seconds from the beginning of the audio.
  final double end;

  /// The text content of this verse.
  final String text;

  /// Creates a [VerseTiming] instance.
  const VerseTiming({
    required this.verse,
    required this.start,
    required this.end,
    required this.text,
  });

  /// Duration of this verse's audio segment in seconds.
  double get duration => end - start;

  @override
  String toString() => 'VerseTiming($verse: ${start}s-${end}s)';
}

/// Complete chapter data including verse timings and audio path.
class ChapterData {
  /// The Bible version identifier (e.g. 'en_kjv', 'zh_cuv').
  final String version;

  /// The canonical book number (1-66).
  final int bookNumber;

  /// The chapter number within the book.
  final int chapter;

  /// Ordered list of verse timings for this chapter.
  final List<VerseTiming> verses;

  /// File path to the audio file for this chapter.
  final String audioPath;

  /// Creates a [ChapterData] instance.
  const ChapterData({
    required this.version,
    required this.bookNumber,
    required this.chapter,
    required this.verses,
    required this.audioPath,
  });

  /// Returns the [VerseTiming] for a specific verse number, or `null`.
  VerseTiming? getVerse(int verseNumber) {
    for (final v in verses) {
      if (v.verse == verseNumber) return v;
    }
    return null;
  }

  /// Total number of verses in this chapter.
  int get verseCount => verses.length;

  @override
  String toString() =>
      'ChapterData($version, book $bookNumber, ch $chapter, $verseCount verses)';
}
