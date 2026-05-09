import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

import 'package:bible_audio_player/models/chapter_data.dart';
import 'package:bible_audio_player/models/play_sequence.dart';
import 'package:bible_audio_player/models/verse_text.dart';
import 'package:bible_audio_player/models/verse_timing.dart';
import 'package:bible_audio_player/services/audio_player_service.dart';

import 'fake_just_audio.dart';

ChapterData _makeChapter(String version, int book, int chapter,
    List<(int, double, double)> timings) {
  return ChapterData(
    version: version,
    bookNumber: book,
    chapter: chapter,
    verses: timings
        .map((t) => VerseText(verse: t.$1, text: 'Verse ${t.$1}'))
        .toList(),
    timings: timings
        .map((t) =>
            VerseTiming(verse: t.$1, start: t.$2, end: t.$3, text: 'Verse ${t.$1}'))
        .toList(),
    audioPath: 'https://audio.bblearn.uk/audio/$version/mark/$chapter.mp3',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    JustAudioPlatform.instance = FakeJustAudioPlatform();
    // Mock audio_session channel so it doesn't hang waiting for native
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_session'),
      (call) async {
        if (call.method == 'getConfiguration') return null;
        if (call.method == 'setConfiguration') return null;
        return null;
      },
    );
  });

  group('AudioPlayerService.onQueueFinished', () {
    test('is NOT called when autoPlay=false (restore on startup)', () async {
      final svc = AudioPlayerService();
      int callCount = 0;
      svc.onQueueFinished = () => callCount++;

      final kjv = _makeChapter('KJV', 41, 1, [(1, 0.0, 5.0), (2, 5.0, 10.0)]);
      final cuv = _makeChapter('CUV', 41, 1, [(1, 0.0, 4.0), (2, 4.0, 8.0)]);

      await svc.loadChapter(
        chapterDataByVersion: {'KJV': kjv, 'CUV': cuv},
        sequence: PresetSequences.enCn,
        bookNumber: 41,
        chapter: 1,
        autoPlay: false,
      );

      await Future.delayed(const Duration(milliseconds: 200));

      expect(callCount, 0,
          reason: 'onQueueFinished must NOT fire when autoPlay=false');

      svc.dispose();
    });

    test('queue is not empty after loadChapter with valid data', () async {
      final svc = AudioPlayerService();

      final kjv = _makeChapter('KJV', 41, 1, [(1, 0.0, 5.0), (2, 5.0, 10.0)]);
      final cuv = _makeChapter('CUV', 41, 1, [(1, 0.0, 4.0), (2, 4.0, 8.0)]);

      await svc.loadChapter(
        chapterDataByVersion: {'KJV': kjv, 'CUV': cuv},
        sequence: PresetSequences.enCn,
        bookNumber: 41,
        chapter: 1,
        autoPlay: false,
      );

      expect(svc.queue, isNotNull);
      expect(svc.queue!.isEmpty, isFalse,
          reason: 'Queue must not be empty with valid chapter data');
      expect(svc.queue!.items.where((i) => !i.isPause).length, 4,
          reason: 'EN-CN with 2 verses = 4 audio items');

      svc.dispose();
    });

    test('chapterFinished state is false after autoPlay=false load', () async {
      final svc = AudioPlayerService();

      final kjv = _makeChapter('KJV', 41, 1, [(1, 0.0, 5.0)]);
      final cuv = _makeChapter('CUV', 41, 1, [(1, 0.0, 4.0)]);

      await svc.loadChapter(
        chapterDataByVersion: {'KJV': kjv, 'CUV': cuv},
        sequence: PresetSequences.enCn,
        bookNumber: 41,
        chapter: 1,
        autoPlay: false,
      );

      await Future.delayed(const Duration(milliseconds: 200));

      expect(svc.state.chapterFinished, isFalse,
          reason: 'chapterFinished must be false after autoPlay=false load');
      expect(svc.state.isPlaying, isFalse);

      svc.dispose();
    });

    test('stepSpeeds are applied to queue items', () async {
      final svc = AudioPlayerService();

      final kjv = _makeChapter('KJV', 41, 1, [(1, 0.0, 5.0)]);
      final cuv = _makeChapter('CUV', 41, 1, [(1, 0.0, 4.0)]);

      await svc.loadChapter(
        chapterDataByVersion: {'KJV': kjv, 'CUV': cuv},
        sequence: PresetSequences.enCn,
        stepSpeeds: {'KJV': 1.5, 'CUV': 0.8},
        bookNumber: 41,
        chapter: 1,
        autoPlay: false,
      );

      final audioItems = svc.queue!.items.where((i) => !i.isPause).toList();
      expect(audioItems[0].speed, closeTo(1.5, 0.001),
          reason: 'KJV step 0 should be 1.5x');
      expect(audioItems[1].speed, closeTo(0.8, 0.001),
          reason: 'CUV step 1 should be 0.8x');

      svc.dispose();
    });
  });
}
