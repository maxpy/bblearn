import '../models/bible_book.dart';

/// Builds asset paths and network URLs for Bible audio and text files.
///
/// Subtitle/text assets:
///   assets/audio/{version}/{OT|NT}/{NN_BookName}/{NN_BookName_CCC}.subtitle.json
///   assets/text/{version}/{OT|NT}/{NN_BookName}/{NN_BookName_CCC}.txt.json
///
/// Audio (network):
///   https://audio.bblearn.uk/audio/{version}/{book_lower}/{chapter}.mp3
class AssetPaths {
  AssetPaths._();

  static const String _audioBaseUrl = 'https://audio.bblearn.uk/audio';
  static const String _srtBaseUrl = 'https://audio.bblearn.uk/srt';

  static String _testament(int bookNumber) =>
      bookNumber <= 39 ? 'OT' : 'NT';

  static String _pad(int n) => n.toString().padLeft(2, '0');
  static String _padChapter(int n) => n.toString().padLeft(3, '0');

  // Join words with no separator, each word capitalized: "Song of Solomon" → "SongOfSolomon"
  static String _bookName(BibleBook book) => book.nameEn
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();

  static String _kjvBookDir(BibleBook book) =>
      '${_pad(book.number)}_${_bookName(book)}';

  static String _cuvBookDir(BibleBook book) =>
      '${_pad(book.number)}_${book.nameZh}';

  static String _bookDir(String version, BibleBook book) =>
      _kjvBookDir(book); // CUV dirs now renamed to English names too

  static String _baseName(String version, BibleBook book, int chapter) {
    final dir = _bookDir(version, book);
    return '${dir}_${_padChapter(chapter)}';
  }

  /// Asset path for the subtitle/timing JSON (bundled in app).
  static String subtitle(String version, BibleBook book, int chapter) {
    final testament = _testament(book.number);
    final bookDir = _bookDir(version, book);
    final base = _baseName(version, book, chapter);
    return 'audio/$version/$testament/$bookDir/$base.subtitle.json';
  }

  /// Asset path for the verse text JSON (bundled in app).
  static String text(String version, BibleBook book, int chapter) {
    final testament = _testament(book.number);
    final bookDir = _bookDir(version, book);
    final base = _baseName(version, book, chapter);
    return 'text/$version/$testament/$bookDir/$base.txt.json';
  }

  /// Network URL for the audio MP3.
  ///
  /// Uses the server convention: /audio/{version}/{bookName_lower}/{chapter}.mp3
  /// e.g. https://audio.bblearn.uk/audio/KJV/genesis/1.mp3
  static String audioUrl(String version, BibleBook book, int chapter) {
    final bookName = book.nameEn.toLowerCase().replaceAll(' ', '_');
    return '$_audioBaseUrl/$version/$bookName/$chapter.mp3';
  }

  /// Network URL for the SRT subtitle file (web only).
  ///
  /// e.g. https://audio.bblearn.uk/srt/KJV/mark/1.srt
  static String srtUrl(String version, BibleBook book, int chapter) {
    final bookName = book.nameEn.toLowerCase().replaceAll(' ', '_');
    return '$_srtBaseUrl/$version/$bookName/$chapter.srt';
  }
}
