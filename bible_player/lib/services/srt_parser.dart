import '../models/timed_verse.dart';

/// Parses SRT subtitle content into a list of [TimedVerse] objects.
class SrtParser {
  const SrtParser();

  /// Parse SRT text content and return a list of timed verses.
  List<TimedVerse> parse(String srtContent) {
    final lines = srtContent.trim().split('\n');
    final verses = <TimedVerse>[];
    int i = 0;

    while (i < lines.length) {
      // Skip blank lines
      if (lines[i].trim().isEmpty) {
        i++;
        continue;
      }

      // Parse sequence number (verse number)
      final seqLine = lines[i].trim();
      final verseNumber = int.tryParse(seqLine);
      if (verseNumber == null) {
        i++;
        continue;
      }
      i++;

      // Parse timestamp line: "00:00:01,000 --> 00:00:05,500"
      if (i >= lines.length) break;
      final timeLine = lines[i].trim();
      final times = _parseTimeLine(timeLine);
      if (times == null) {
        i++;
        continue;
      }
      i++;

      // Collect text lines until blank line or end
      final textLines = <String>[];
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        textLines.add(lines[i].trim());
        i++;
      }

      verses.add(TimedVerse(
        verseNumber: verseNumber,
        text: textLines.join(' '),
        startTime: times.$1,
        endTime: times.$2,
      ));
    }

    return verses;
  }

  /// Parse a timestamp line like "00:01:23,456 --> 00:02:34,567"
  (Duration, Duration)? _parseTimeLine(String line) {
    final parts = line.split('-->');
    if (parts.length != 2) return null;

    final start = _parseDuration(parts[0].trim());
    final end = _parseDuration(parts[1].trim());
    if (start == null || end == null) return null;

    return (start, end);
  }

  /// Parse a duration string like "00:01:23,456" or "00:01:23.456"
  Duration? _parseDuration(String str) {
    final normalized = str.replaceAll(',', '.');
    final regex = RegExp(r'(\d+):(\d+):(\d+)\.(\d+)');
    final match = regex.firstMatch(normalized);
    if (match == null) return null;

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final millis = int.parse(match.group(4)!.padRight(3, '0').substring(0, 3));

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: millis,
    );
  }
}
