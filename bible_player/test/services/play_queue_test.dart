import 'package:flutter_test/flutter_test.dart';
import 'package:bible_audio_player/models/chapter_data.dart';
import 'package:bible_audio_player/models/play_sequence.dart';
import 'package:bible_audio_player/models/verse_text.dart';
import 'package:bible_audio_player/models/verse_timing.dart';
import 'package:bible_audio_player/services/play_queue.dart';

ChapterData _makeChapter(String version, List<(int, double, double)> timings) {
  return ChapterData(
    version: version,
    bookNumber: 1,
    chapter: 1,
    verses: timings
        .map((t) => VerseText(verse: t.$1, text: 'Verse ${t.$1}'))
        .toList(),
    timings: timings
        .map((t) => VerseTiming(verse: t.$1, start: t.$2, end: t.$3, text: 'Verse ${t.$1}'))
        .toList(),
    audioPath: 'assets/audio/$version/gen1.mp3',
  );
}

void main() {
  // KJV: 3 verses, CUV: 3 verses
  final kjv = _makeChapter('KJV', [(1, 0.0, 5.0), (2, 5.0, 10.0), (3, 10.0, 15.0)]);
  final cuv = _makeChapter('CUV', [(1, 0.0, 4.0), (2, 4.0, 8.0), (3, 8.0, 12.0)]);

  group('PlayQueue.build — EN only', () {
    test('produces one item per verse', () {
      final q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv},
        sequence: PresetSequences.en,
      );
      final audio = q.items.where((i) => !i.isPause).toList();
      expect(audio.length, 3);
      expect(audio.map((i) => i.version).toSet(), {'KJV'});
      expect(audio.map((i) => i.verse).toList(), [1, 2, 3]);
    });

    test('audio items have correct start/end times', () {
      final q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv},
        sequence: PresetSequences.en,
      );
      final audio = q.items.where((i) => !i.isPause).toList();
      expect(audio[0].startTime, 0.0);
      expect(audio[0].endTime, 5.0);
      expect(audio[1].startTime, 5.0);
      expect(audio[1].endTime, 10.0);
    });
  });

  group('PlayQueue.build — EN→CN sequence', () {
    test('alternates KJV then CUV for each verse', () {
      final q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv, 'CUV': cuv},
        sequence: PresetSequences.enCn,
      );
      final audio = q.items.where((i) => !i.isPause).toList();

      // 3 verses × 2 steps = 6 audio items
      expect(audio.length, 6);

      // Verse 1: KJV then CUV
      expect(audio[0].verse, 1);
      expect(audio[0].version, 'KJV');
      expect(audio[1].verse, 1);
      expect(audio[1].version, 'CUV');

      // Verse 2: KJV then CUV
      expect(audio[2].verse, 2);
      expect(audio[2].version, 'KJV');
      expect(audio[3].verse, 2);
      expect(audio[3].version, 'CUV');

      // Verse 3: KJV then CUV
      expect(audio[4].verse, 3);
      expect(audio[4].version, 'KJV');
      expect(audio[5].verse, 3);
      expect(audio[5].version, 'CUV');
    });

    test('CUV items use CUV audio path and timings', () {
      final q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv, 'CUV': cuv},
        sequence: PresetSequences.enCn,
      );
      final cuvItems = q.items.where((i) => !i.isPause && i.version == 'CUV').toList();
      expect(cuvItems.length, 3);
      expect(cuvItems[0].audioPath, contains('CUV'));
      expect(cuvItems[0].startTime, 0.0);
      expect(cuvItems[0].endTime, 4.0);
    });

    test('inserts step gap between KJV and CUV within same verse', () {
      final seq = PlaySequence(
        name: 'EN→CN',
        steps: [PlayStep(version: 'KJV', speed: 1.0), PlayStep(version: 'CUV', speed: 1.0)],
        gapBetweenSteps: 0.5,
        gapBetweenVerses: 0.0,
      );
      final q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv, 'CUV': cuv},
        sequence: seq,
      );
      // Pattern per verse: KJV, pause(0.5s), CUV
      // Verse 1 items: index 0=KJV, 1=pause, 2=CUV
      expect(q.items[0].version, 'KJV');
      expect(q.items[1].isPause, isTrue);
      expect(q.items[1].pauseDuration, 0.5);
      expect(q.items[2].version, 'CUV');
    });

    test('inserts verse gap after each verse (except last)', () {
      final seq = PlaySequence(
        name: 'EN→CN',
        steps: [PlayStep(version: 'KJV', speed: 1.0), PlayStep(version: 'CUV', speed: 1.0)],
        gapBetweenSteps: 0.0,
        gapBetweenVerses: 1.0,
      );
      final q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv, 'CUV': cuv},
        sequence: seq,
      );
      // Pattern: KJV1, CUV1, pause(1s), KJV2, CUV2, pause(1s), KJV3, CUV3
      final pauses = q.items.where((i) => i.isPause).toList();
      expect(pauses.length, 2); // not after last verse
      expect(pauses[0].pauseDuration, 1.0);
    });
  });

  group('PlayQueue.build — CN→EN sequence', () {
    test('plays CUV before KJV', () {
      final q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv, 'CUV': cuv},
        sequence: PresetSequences.cnEn,
      );
      final audio = q.items.where((i) => !i.isPause).toList();
      expect(audio[0].version, 'CUV');
      expect(audio[1].version, 'KJV');
    });
  });

  group('PlayQueue navigation', () {
    late PlayQueue q;

    setUp(() {
      q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv, 'CUV': cuv},
        sequence: PresetSequences.enCn,
      );
    });

    test('starts at index 0', () {
      expect(q.currentIndex, 0);
      expect(q.current?.version, 'KJV');
      expect(q.current?.verse, 1);
    });

    test('nextItem advances by one', () {
      q.nextItem();
      expect(q.currentIndex, 1);
    });

    test('nextVerse skips to first item of next verse', () {
      q.nextVerse();
      expect(q.current?.verse, 2);
      expect(q.current?.version, 'KJV');
    });

    test('previousVerse goes back to first item of previous verse', () {
      q.nextVerse(); // verse 2
      q.previousVerse(); // back to verse 1
      expect(q.current?.verse, 1);
      expect(q.current?.version, 'KJV');
    });

    test('seekToVerse jumps to correct verse', () {
      q.seekToVerse(3);
      expect(q.current?.verse, 3);
      expect(q.current?.version, 'KJV');
    });

    test('hasNext is false at last item', () {
      while (q.hasNext) q.nextItem();
      expect(q.hasNext, isFalse);
    });

    test('verseNumbers returns all unique verses', () {
      expect(q.verseNumbers, [1, 2, 3]);
    });
  });

  group('PlayQueue edge cases', () {
    test('empty sequence returns empty queue', () {
      final q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv},
        sequence: const PlaySequence(
          name: 'empty',
          steps: [],
          gapBetweenSteps: 0,
          gapBetweenVerses: 0,
        ),
      );
      expect(q.isEmpty, isTrue);
    });

    test('missing version in chapterDataByVersion skips that step', () {
      // Only KJV provided, but sequence asks for KJV+CUV
      final q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv},
        sequence: PresetSequences.enCn,
      );
      final audio = q.items.where((i) => !i.isPause).toList();
      // Only KJV items, CUV skipped
      expect(audio.every((i) => i.version == 'KJV'), isTrue);
      expect(audio.length, 3);
    });

    test('startVerse and endVerse limit the range', () {
      final q = PlayQueue.build(
        chapterDataByVersion: {'KJV': kjv},
        sequence: PresetSequences.en,
        startVerse: 2,
        endVerse: 3,
      );
      final audio = q.items.where((i) => !i.isPause).toList();
      expect(audio.map((i) => i.verse).toList(), [2, 3]);
    });
  });
}
