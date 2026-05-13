import '../models/book.dart';

/// Static data for all 66 books of the Bible.
class BibleData {
  BibleData._();

  static const List<Book> oldTestament = [
    Book(id: 'gen', name: 'Genesis', chapters: 50, testament: Testament.old),
    Book(id: 'exo', name: 'Exodus', chapters: 40, testament: Testament.old),
    Book(id: 'lev', name: 'Leviticus', chapters: 27, testament: Testament.old),
    Book(id: 'num', name: 'Numbers', chapters: 36, testament: Testament.old),
    Book(id: 'deu', name: 'Deuteronomy', chapters: 34, testament: Testament.old),
    Book(id: 'jos', name: 'Joshua', chapters: 24, testament: Testament.old),
    Book(id: 'jdg', name: 'Judges', chapters: 21, testament: Testament.old),
    Book(id: 'rut', name: 'Ruth', chapters: 4, testament: Testament.old),
    Book(id: '1sa', name: '1 Samuel', chapters: 31, testament: Testament.old),
    Book(id: '2sa', name: '2 Samuel', chapters: 24, testament: Testament.old),
    Book(id: '1ki', name: '1 Kings', chapters: 22, testament: Testament.old),
    Book(id: '2ki', name: '2 Kings', chapters: 25, testament: Testament.old),
    Book(id: '1ch', name: '1 Chronicles', chapters: 29, testament: Testament.old),
    Book(id: '2ch', name: '2 Chronicles', chapters: 36, testament: Testament.old),
    Book(id: 'ezr', name: 'Ezra', chapters: 10, testament: Testament.old),
    Book(id: 'neh', name: 'Nehemiah', chapters: 13, testament: Testament.old),
    Book(id: 'est', name: 'Esther', chapters: 10, testament: Testament.old),
    Book(id: 'job', name: 'Job', chapters: 42, testament: Testament.old),
    Book(id: 'psa', name: 'Psalms', chapters: 150, testament: Testament.old),
    Book(id: 'pro', name: 'Proverbs', chapters: 31, testament: Testament.old),
    Book(id: 'ecc', name: 'Ecclesiastes', chapters: 12, testament: Testament.old),
    Book(id: 'sng', name: 'Song of Solomon', chapters: 8, testament: Testament.old),
    Book(id: 'isa', name: 'Isaiah', chapters: 66, testament: Testament.old),
    Book(id: 'jer', name: 'Jeremiah', chapters: 52, testament: Testament.old),
    Book(id: 'lam', name: 'Lamentations', chapters: 5, testament: Testament.old),
    Book(id: 'ezk', name: 'Ezekiel', chapters: 48, testament: Testament.old),
    Book(id: 'dan', name: 'Daniel', chapters: 12, testament: Testament.old),
    Book(id: 'hos', name: 'Hosea', chapters: 14, testament: Testament.old),
    Book(id: 'jol', name: 'Joel', chapters: 3, testament: Testament.old),
    Book(id: 'amo', name: 'Amos', chapters: 9, testament: Testament.old),
    Book(id: 'oba', name: 'Obadiah', chapters: 1, testament: Testament.old),
    Book(id: 'jon', name: 'Jonah', chapters: 4, testament: Testament.old),
    Book(id: 'mic', name: 'Micah', chapters: 7, testament: Testament.old),
    Book(id: 'nam', name: 'Nahum', chapters: 3, testament: Testament.old),
    Book(id: 'hab', name: 'Habakkuk', chapters: 3, testament: Testament.old),
    Book(id: 'zep', name: 'Zephaniah', chapters: 3, testament: Testament.old),
    Book(id: 'hag', name: 'Haggai', chapters: 2, testament: Testament.old),
    Book(id: 'zec', name: 'Zechariah', chapters: 14, testament: Testament.old),
    Book(id: 'mal', name: 'Malachi', chapters: 4, testament: Testament.old),
  ];

  static const List<Book> newTestament = [
    Book(id: 'mat', name: 'Matthew', chapters: 28, testament: Testament.new_),
    Book(id: 'mrk', name: 'Mark', chapters: 16, testament: Testament.new_),
    Book(id: 'luk', name: 'Luke', chapters: 24, testament: Testament.new_),
    Book(id: 'jhn', name: 'John', chapters: 21, testament: Testament.new_),
    Book(id: 'act', name: 'Acts', chapters: 28, testament: Testament.new_),
    Book(id: 'rom', name: 'Romans', chapters: 16, testament: Testament.new_),
    Book(id: '1co', name: '1 Corinthians', chapters: 16, testament: Testament.new_),
    Book(id: '2co', name: '2 Corinthians', chapters: 13, testament: Testament.new_),
    Book(id: 'gal', name: 'Galatians', chapters: 6, testament: Testament.new_),
    Book(id: 'eph', name: 'Ephesians', chapters: 6, testament: Testament.new_),
    Book(id: 'php', name: 'Philippians', chapters: 4, testament: Testament.new_),
    Book(id: 'col', name: 'Colossians', chapters: 4, testament: Testament.new_),
    Book(id: '1th', name: '1 Thessalonians', chapters: 5, testament: Testament.new_),
    Book(id: '2th', name: '2 Thessalonians', chapters: 3, testament: Testament.new_),
    Book(id: '1ti', name: '1 Timothy', chapters: 6, testament: Testament.new_),
    Book(id: '2ti', name: '2 Timothy', chapters: 4, testament: Testament.new_),
    Book(id: 'tit', name: 'Titus', chapters: 3, testament: Testament.new_),
    Book(id: 'phm', name: 'Philemon', chapters: 1, testament: Testament.new_),
    Book(id: 'heb', name: 'Hebrews', chapters: 13, testament: Testament.new_),
    Book(id: 'jas', name: 'James', chapters: 5, testament: Testament.new_),
    Book(id: '1pe', name: '1 Peter', chapters: 5, testament: Testament.new_),
    Book(id: '2pe', name: '2 Peter', chapters: 3, testament: Testament.new_),
    Book(id: '1jn', name: '1 John', chapters: 5, testament: Testament.new_),
    Book(id: '2jn', name: '2 John', chapters: 1, testament: Testament.new_),
    Book(id: '3jn', name: '3 John', chapters: 1, testament: Testament.new_),
    Book(id: 'jud', name: 'Jude', chapters: 1, testament: Testament.new_),
    Book(id: 'rev', name: 'Revelation', chapters: 22, testament: Testament.new_),
  ];

  static const List<Book> allBooks = [...oldTestament, ...newTestament];

  /// Find a book by its ID.
  static Book? findById(String id) {
    try {
      return allBooks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
