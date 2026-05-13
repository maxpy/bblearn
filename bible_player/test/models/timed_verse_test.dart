import 'package:flutter_test/flutter_test.dart';
import 'package:bible_audio_player/models/timed_verse.dart';

void main() {
  group('TimedVerse', () {
    const verse = TimedVerse(
      verseNumber: 1,
      text: 'In the beginning God created the heavens and the earth.',
      startTime: Duration(seconds: 0),
      endTime: Duration(seconds: 5),
    );

    test('isActiveAt returns true when position is within range', () {
      expect(verse.isActiveAt(const Duration(seconds: 0)), isTrue);
      expect(verse.isActiveAt(const Duration(seconds: 3)), isTrue);
      expect(verse.isActiveAt(const Duration(milliseconds: 4999)), isTrue);
    });

    test('isActiveAt returns false when position is outside range', () {
      expect(verse.isActiveAt(const Duration(seconds: 5)), isFalse);
      expect(verse.isActiveAt(const Duration(seconds: 10)), isFalse);
    });

    test('supports equality', () {
      const verse2 = TimedVerse(
        verseNumber: 1,
        text: 'In the beginning God created the heavens and the earth.',
        startTime: Duration(seconds: 0),
        endTime: Duration(seconds: 5),
      );
      expect(verse, equals(verse2));
    });
  });
}
