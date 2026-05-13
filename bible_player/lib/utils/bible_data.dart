import '../models/bible_book.dart';

class BibleData {
  BibleData._();

  static const List<BibleBook> books = [
    // Old Testament (39 books)
    BibleBook(number: 1, nameEn: 'Genesis', nameZh: '创世记', chapters: 50, testament: Testament.ot),
    BibleBook(number: 2, nameEn: 'Exodus', nameZh: '出埃及记', chapters: 40, testament: Testament.ot),
    BibleBook(number: 3, nameEn: 'Leviticus', nameZh: '利未记', chapters: 27, testament: Testament.ot),
    BibleBook(number: 4, nameEn: 'Numbers', nameZh: '民数记', chapters: 36, testament: Testament.ot),
    BibleBook(number: 5, nameEn: 'Deuteronomy', nameZh: '申命记', chapters: 34, testament: Testament.ot),
    BibleBook(number: 6, nameEn: 'Joshua', nameZh: '约书亚记', chapters: 24, testament: Testament.ot),
    BibleBook(number: 7, nameEn: 'Judges', nameZh: '士师记', chapters: 21, testament: Testament.ot),
    BibleBook(number: 8, nameEn: 'Ruth', nameZh: '路得记', chapters: 4, testament: Testament.ot),
    BibleBook(number: 9, nameEn: '1 Samuel', nameZh: '撒母耳记上', chapters: 31, testament: Testament.ot),
    BibleBook(number: 10, nameEn: '2 Samuel', nameZh: '撒母耳记下', chapters: 24, testament: Testament.ot),
    BibleBook(number: 11, nameEn: '1 Kings', nameZh: '列王纪上', chapters: 22, testament: Testament.ot),
    BibleBook(number: 12, nameEn: '2 Kings', nameZh: '列王纪下', chapters: 25, testament: Testament.ot),
    BibleBook(number: 13, nameEn: '1 Chronicles', nameZh: '历代志上', chapters: 29, testament: Testament.ot),
    BibleBook(number: 14, nameEn: '2 Chronicles', nameZh: '历代志下', chapters: 36, testament: Testament.ot),
    BibleBook(number: 15, nameEn: 'Ezra', nameZh: '以斯拉记', chapters: 10, testament: Testament.ot),
    BibleBook(number: 16, nameEn: 'Nehemiah', nameZh: '尼希米记', chapters: 13, testament: Testament.ot),
    BibleBook(number: 17, nameEn: 'Esther', nameZh: '以斯帖记', chapters: 10, testament: Testament.ot),
    BibleBook(number: 18, nameEn: 'Job', nameZh: '约伯记', chapters: 42, testament: Testament.ot),
    BibleBook(number: 19, nameEn: 'Psalms', nameZh: '诗篇', chapters: 150, testament: Testament.ot),
    BibleBook(number: 20, nameEn: 'Proverbs', nameZh: '箴言', chapters: 31, testament: Testament.ot),
    BibleBook(number: 21, nameEn: 'Ecclesiastes', nameZh: '传道书', chapters: 12, testament: Testament.ot),
    BibleBook(number: 22, nameEn: 'Song of Solomon', nameZh: '雅歌', chapters: 8, testament: Testament.ot),
    BibleBook(number: 23, nameEn: 'Isaiah', nameZh: '以赛亚书', chapters: 66, testament: Testament.ot),
    BibleBook(number: 24, nameEn: 'Jeremiah', nameZh: '耶利米书', chapters: 52, testament: Testament.ot),
    BibleBook(number: 25, nameEn: 'Lamentations', nameZh: '耶利米哀歌', chapters: 5, testament: Testament.ot),
    BibleBook(number: 26, nameEn: 'Ezekiel', nameZh: '以西结书', chapters: 48, testament: Testament.ot),
    BibleBook(number: 27, nameEn: 'Daniel', nameZh: '但以理书', chapters: 12, testament: Testament.ot),
    BibleBook(number: 28, nameEn: 'Hosea', nameZh: '何西阿书', chapters: 14, testament: Testament.ot),
    BibleBook(number: 29, nameEn: 'Joel', nameZh: '约珥书', chapters: 3, testament: Testament.ot),
    BibleBook(number: 30, nameEn: 'Amos', nameZh: '阿摩司书', chapters: 9, testament: Testament.ot),
    BibleBook(number: 31, nameEn: 'Obadiah', nameZh: '俄巴底亚书', chapters: 1, testament: Testament.ot),
    BibleBook(number: 32, nameEn: 'Jonah', nameZh: '约拿书', chapters: 4, testament: Testament.ot),
    BibleBook(number: 33, nameEn: 'Micah', nameZh: '弥迦书', chapters: 7, testament: Testament.ot),
    BibleBook(number: 34, nameEn: 'Nahum', nameZh: '那鸿书', chapters: 3, testament: Testament.ot),
    BibleBook(number: 35, nameEn: 'Habakkuk', nameZh: '哈巴谷书', chapters: 3, testament: Testament.ot),
    BibleBook(number: 36, nameEn: 'Zephaniah', nameZh: '西番雅书', chapters: 3, testament: Testament.ot),
    BibleBook(number: 37, nameEn: 'Haggai', nameZh: '哈该书', chapters: 2, testament: Testament.ot),
    BibleBook(number: 38, nameEn: 'Zechariah', nameZh: '撒迦利亚书', chapters: 14, testament: Testament.ot),
    BibleBook(number: 39, nameEn: 'Malachi', nameZh: '玛拉基书', chapters: 4, testament: Testament.ot),
    // New Testament (27 books)
    BibleBook(number: 40, nameEn: 'Matthew', nameZh: '马太福音', chapters: 28, testament: Testament.nt),
    BibleBook(number: 41, nameEn: 'Mark', nameZh: '马可福音', chapters: 16, testament: Testament.nt),
    BibleBook(number: 42, nameEn: 'Luke', nameZh: '路加福音', chapters: 24, testament: Testament.nt),
    BibleBook(number: 43, nameEn: 'John', nameZh: '约翰福音', chapters: 21, testament: Testament.nt),
    BibleBook(number: 44, nameEn: 'Acts', nameZh: '使徒行传', chapters: 28, testament: Testament.nt),
    BibleBook(number: 45, nameEn: 'Romans', nameZh: '罗马书', chapters: 16, testament: Testament.nt),
    BibleBook(number: 46, nameEn: '1 Corinthians', nameZh: '哥林多前书', chapters: 16, testament: Testament.nt),
    BibleBook(number: 47, nameEn: '2 Corinthians', nameZh: '哥林多后书', chapters: 13, testament: Testament.nt),
    BibleBook(number: 48, nameEn: 'Galatians', nameZh: '加拉太书', chapters: 6, testament: Testament.nt),
    BibleBook(number: 49, nameEn: 'Ephesians', nameZh: '以弗所书', chapters: 6, testament: Testament.nt),
    BibleBook(number: 50, nameEn: 'Philippians', nameZh: '腓立比书', chapters: 4, testament: Testament.nt),
    BibleBook(number: 51, nameEn: 'Colossians', nameZh: '歌罗西书', chapters: 4, testament: Testament.nt),
    BibleBook(number: 52, nameEn: '1 Thessalonians', nameZh: '帖撒罗尼迦前书', chapters: 5, testament: Testament.nt),
    BibleBook(number: 53, nameEn: '2 Thessalonians', nameZh: '帖撒罗尼迦后书', chapters: 3, testament: Testament.nt),
    BibleBook(number: 54, nameEn: '1 Timothy', nameZh: '提摩太前书', chapters: 6, testament: Testament.nt),
    BibleBook(number: 55, nameEn: '2 Timothy', nameZh: '提摩太后书', chapters: 4, testament: Testament.nt),
    BibleBook(number: 56, nameEn: 'Titus', nameZh: '提多书', chapters: 3, testament: Testament.nt),
    BibleBook(number: 57, nameEn: 'Philemon', nameZh: '腓利门书', chapters: 1, testament: Testament.nt),
    BibleBook(number: 58, nameEn: 'Hebrews', nameZh: '希伯来书', chapters: 13, testament: Testament.nt),
    BibleBook(number: 59, nameEn: 'James', nameZh: '雅各书', chapters: 5, testament: Testament.nt),
    BibleBook(number: 60, nameEn: '1 Peter', nameZh: '彼得前书', chapters: 5, testament: Testament.nt),
    BibleBook(number: 61, nameEn: '2 Peter', nameZh: '彼得后书', chapters: 3, testament: Testament.nt),
    BibleBook(number: 62, nameEn: '1 John', nameZh: '约翰一书', chapters: 5, testament: Testament.nt),
    BibleBook(number: 63, nameEn: '2 John', nameZh: '约翰二书', chapters: 1, testament: Testament.nt),
    BibleBook(number: 64, nameEn: '3 John', nameZh: '约翰三书', chapters: 1, testament: Testament.nt),
    BibleBook(number: 65, nameEn: 'Jude', nameZh: '犹大书', chapters: 1, testament: Testament.nt),
    BibleBook(number: 66, nameEn: 'Revelation', nameZh: '启示录', chapters: 22, testament: Testament.nt),
  ];

  /// Get a book by its canonical number (1-66).
  static BibleBook getBook(int number) {
    return books.firstWhere(
      (b) => b.number == number,
      orElse: () => throw ArgumentError('Invalid book number: $number'),
    );
  }

  /// Get all books in a given testament.
  static List<BibleBook> getBooksByTestament(Testament testament) {
    return books.where((b) => b.testament == testament).toList();
  }

  /// Total number of chapters across all 66 books.
  static int get totalChapters {
    return books.fold<int>(0, (sum, b) => sum + b.chapters);
  }

  /// Get the localized name of a book by number.
  static String getBookName(int number, String language) {
    final book = getBook(number);
    return language == 'zh' ? book.nameZh : book.nameEn;
  }
}
