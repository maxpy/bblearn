import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import '../services/bible_data_service.dart';
import '../services/srt_parser.dart';
import '../constants/bible_data.dart';
import '../models/book.dart';

/// Provides the [AudioService] singleton.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provides the [SrtParser].
final srtParserProvider = Provider<SrtParser>((ref) {
  return const SrtParser();
});

/// Provides the [BibleDataService].
final bibleDataServiceProvider = Provider<BibleDataService>((ref) {
  final service = BibleDataService(srtParser: ref.watch(srtParserProvider));
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provides the list of all Bible books.
final allBooksProvider = Provider<List<Book>>((ref) {
  return BibleData.allBooks;
});

/// Provides old testament books.
final oldTestamentProvider = Provider<List<Book>>((ref) {
  return BibleData.oldTestament;
});

/// Provides new testament books.
final newTestamentProvider = Provider<List<Book>>((ref) {
  return BibleData.newTestament;
});

/// Finds a book by ID.
final bookByIdProvider = Provider.family<Book?, String>((ref, id) {
  return BibleData.findById(id);
});
