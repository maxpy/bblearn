import 'package:flutter_test/flutter_test.dart';
import 'package:bible_audio_player/models/book.dart';

void main() {
  group('Book', () {
    test('should create a book with correct properties', () {
      const book = Book(
        id: 'gen',
        name: 'Genesis',
        chapters: 50,
        testament: Testament.old,
      );

      expect(book.id, 'gen');
      expect(book.name, 'Genesis');
      expect(book.chapters, 50);
      expect(book.testament, Testament.old);
    });

    test('should support equality comparison', () {
      const book1 = Book(
        id: 'gen',
        name: 'Genesis',
        chapters: 50,
        testament: Testament.old,
      );
      const book2 = Book(
        id: 'gen',
        name: 'Genesis',
        chapters: 50,
        testament: Testament.old,
      );

      expect(book1, equals(book2));
    });
  });
}
