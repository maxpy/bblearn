import 'package:flutter_test/flutter_test.dart';
import 'package:bible_audio_player/services/srt_parser.dart';

void main() {
  group('SrtParser', () {
    const parser = SrtParser();

    test('should parse valid SRT content', () {
      const srt = '''
1
00:00:00,000 --> 00:00:05,500
In the beginning God created the heavens and the earth.

2
00:00:05,500 --> 00:00:10,200
And the earth was without form, and void.

3
00:00:10,200 --> 00:00:15,800
And God said, Let there be light: and there was light.
''';

      final verses = parser.parse(srt);

      expect(verses.length, 3);
      expect(verses[0].verseNumber, 1);
      expect(verses[0].text,
          'In the beginning God created the heavens and the earth.');
      expect(verses[0].startTime, Duration.zero);
      expect(verses[0].endTime, const Duration(seconds: 5, milliseconds: 500));

      expect(verses[1].verseNumber, 2);
      expect(verses[1].startTime,
          const Duration(seconds: 5, milliseconds: 500));

      expect(verses[2].verseNumber, 3);
      expect(verses[2].text,
          'And God said, Let there be light: and there was light.');
    });

    test('should handle empty content', () {
      final verses = parser.parse('');
      expect(verses, isEmpty);
    });

    test('should handle multi-line verse text', () {
      const srt = '''
1
00:00:00,000 --> 00:00:05,000
First line of verse
Second line of verse
''';

      final verses = parser.parse(srt);

      expect(verses.length, 1);
      expect(verses[0].text, 'First line of verse Second line of verse');
    });

    test('should parse hours correctly', () {
      const srt = '''
1
01:30:00,000 --> 01:35:00,000
A verse at 1 hour 30 minutes.
''';

      final verses = parser.parse(srt);

      expect(verses[0].startTime, const Duration(hours: 1, minutes: 30));
      expect(verses[0].endTime,
          const Duration(hours: 1, minutes: 35));
    });
  });
}
