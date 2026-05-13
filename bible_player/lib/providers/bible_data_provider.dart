import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bible_book.dart';
import '../services/bible_data_service.dart';

/// Provides a singleton [BibleDataService] instance.
final bibleDataServiceProvider = Provider<BibleDataService>((ref) {
  return BibleDataService();
});

/// Provides the complete list of all 66 Bible books.
final allBooksProvider = Provider<List<BibleBook>>((ref) {
  return BibleBook.allBooks;
});

/// Provides only Old Testament books.
final oldTestamentBooksProvider = Provider<List<BibleBook>>((ref) {
  return BibleBook.oldTestament;
});

/// Provides only New Testament books.
final newTestamentBooksProvider = Provider<List<BibleBook>>((ref) {
  return BibleBook.newTestament;
});
