import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible_audio_player/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Helper: set starting position via SharedPreferences before app launch
  Future<void> setStartPosition(int bookNumber, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_book', bookNumber);
    await prefs.setInt('last_chapter', chapter);
  }

  // Helper: wait for real-time condition with periodic pump
  Future<bool> waitFor(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 30),
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    bool result = false;
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(interval);
        await tester.pump();
        if (condition()) { result = true; break; }
      }
    });
    return result;
  }

  group('Playback integration tests', () {
    testWidgets('app launches and player screen visible', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 5));
      try { await tester.pumpAndSettle(const Duration(seconds: 3)); } catch (_) {}

      expect(find.bySemanticsLabel('play'), findsOneWidget,
          reason: 'Play button should be visible after app loads');
    });

    testWidgets('play button starts playback', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 5));
      try { await tester.pumpAndSettle(const Duration(seconds: 3)); } catch (_) {}

      final playBtn = find.bySemanticsLabel('play');
      if (!tester.any(playBtn)) fail('Play button not found');
      await tester.tap(playBtn);
      await tester.pump(const Duration(seconds: 2));

      expect(find.bySemanticsLabel('pause'), findsOneWidget,
          reason: 'After tapping play, button should show pause');
    });

    testWidgets('verse advances after playing', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 5));
      try { await tester.pumpAndSettle(const Duration(seconds: 3)); } catch (_) {}

      final verseFinder = find.byKey(const ValueKey('current_verse_label'));
      final verseBefore = tester.any(verseFinder)
          ? (tester.widget(verseFinder) as Text).data ?? '' : '';

      final playBtn = find.bySemanticsLabel('play');
      if (tester.any(playBtn)) await tester.tap(playBtn);

      String verseAfter = verseBefore;
      await tester.runAsync(() async {
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (DateTime.now().isBefore(deadline)) {
          await Future.delayed(const Duration(milliseconds: 500));
          await tester.pump();
          if (tester.any(verseFinder)) {
            final v = (tester.widget(verseFinder) as Text).data ?? '';
            if (v != verseBefore && v.isNotEmpty) { verseAfter = v; break; }
          }
        }
      });

      final pauseBtn = find.bySemanticsLabel('pause');
      if (tester.any(pauseBtn)) await tester.tap(pauseBtn);

      expect(verseAfter, isNot(equals(verseBefore)),
          reason: 'Verse should advance after playing CN+EN');
    });

    testWidgets('CN then EN sequence plays', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 5));
      try { await tester.pumpAndSettle(const Duration(seconds: 3)); } catch (_) {}

      final versionFinder = find.byKey(const ValueKey('current_version_label'));
      final playBtn = find.bySemanticsLabel('play');
      if (tester.any(playBtn)) await tester.tap(playBtn);

      final versions = <String>{};
      await tester.runAsync(() async {
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (DateTime.now().isBefore(deadline)) {
          await Future.delayed(const Duration(milliseconds: 300));
          await tester.pump();
          if (tester.any(versionFinder)) {
            final v = (tester.widget(versionFinder) as Text).data ?? '';
            if (v.isNotEmpty) versions.add(v);
          }
          if (versions.containsAll(['CUV', 'KJV'])) break;
        }
      });

      final pauseBtn = find.bySemanticsLabel('pause');
      if (tester.any(pauseBtn)) await tester.tap(pauseBtn);

      expect(versions, containsAll(['CUV', 'KJV']),
          reason: 'Both CUV and KJV should play. Got: $versions');
    });

    /// Play from near the end of Obadiah 1 (last chapter of book 31),
    /// wait for chapter to finish, then verify auto-advance to Jonah 1.
    testWidgets('chapter finishes and auto-advances to next chapter',
        (tester) async {
      // Start at Obadiah 1 (book 31, chapter 1 — only 21 verses)
      await setStartPosition(31, 1);

      app.main();
      await tester.pump(const Duration(seconds: 5));
      try { await tester.pumpAndSettle(const Duration(seconds: 3)); } catch (_) {}

      // Verify we're on Obadiah 1
      final titleFinder = find.byKey(const ValueKey('chapter_title'));
      expect(tester.any(titleFinder), isTrue, reason: 'Chapter title should be visible');
      final titleBefore = (tester.widget(titleFinder) as Text).data ?? '';
      expect(titleBefore, contains('Obadiah'), reason: 'Should start on Obadiah');

      // Tap the last verse (v.20 or v.21) to seek near the end
      // Use nextVerse button repeatedly to get close to the end
      final nextVerseBtn = find.byTooltip('下一节');
      if (tester.any(nextVerseBtn)) {
        // Tap 18 times to get from v.1 to v.19
        for (int i = 0; i < 18; i++) {
          await tester.tap(nextVerseBtn);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      // Now play from near the end
      final playBtn = find.bySemanticsLabel('play');
      if (tester.any(playBtn)) await tester.tap(playBtn);

      // Wait up to 90s for chapter to finish and auto-advance to Jonah
      final advanced = await waitFor(
        tester,
        () {
          if (!tester.any(titleFinder)) return false;
          final title = (tester.widget(titleFinder) as Text).data ?? '';
          return title.contains('Jonah');
        },
        timeout: const Duration(seconds: 90),
      );

      // Pause if still playing
      final pauseBtn = find.bySemanticsLabel('pause');
      if (tester.any(pauseBtn)) await tester.tap(pauseBtn);

      final titleAfter = tester.any(titleFinder)
          ? (tester.widget(titleFinder) as Text).data ?? '' : '';

      expect(advanced, isTrue,
          reason: 'Should auto-advance to Jonah after Obadiah finishes. '
              'Current title: $titleAfter');
      expect(titleAfter, contains('Jonah'),
          reason: 'Title should show Jonah 1 after auto-advance');
    });

    /// Play a full short chapter (Obadiah 1, 21 verses) from start to finish.
    testWidgets('plays full chapter from start to finish', (tester) async {
      await setStartPosition(31, 1);

      app.main();
      await tester.pump(const Duration(seconds: 5));
      try { await tester.pumpAndSettle(const Duration(seconds: 3)); } catch (_) {}

      final titleFinder = find.byKey(const ValueKey('chapter_title'));
      final verseFinder = find.byKey(const ValueKey('current_verse_label'));

      // Confirm starting on Obadiah 1
      expect(tester.any(titleFinder), isTrue);
      expect((tester.widget(titleFinder) as Text).data ?? '', contains('Obadiah'));

      // Play from start
      final playBtn = find.bySemanticsLabel('play');
      if (tester.any(playBtn)) await tester.tap(playBtn);

      // Track verse progression
      final versesPlayed = <String>{};
      String finalTitle = '';

      await tester.runAsync(() async {
        final deadline = DateTime.now().add(const Duration(minutes: 10));
        while (DateTime.now().isBefore(deadline)) {
          await Future.delayed(const Duration(milliseconds: 500));
          await tester.pump();

          if (tester.any(verseFinder)) {
            final v = (tester.widget(verseFinder) as Text).data ?? '';
            if (v.isNotEmpty) versesPlayed.add(v);
          }
          if (tester.any(titleFinder)) {
            finalTitle = (tester.widget(titleFinder) as Text).data ?? '';
          }

          // Stop once we've advanced to Jonah (chapter finished + auto-advanced)
          if (finalTitle.contains('Jonah')) break;
        }
      });

      final pauseBtn = find.bySemanticsLabel('pause');
      if (tester.any(pauseBtn)) await tester.tap(pauseBtn);

      // Should have played multiple verses
      expect(versesPlayed.length, greaterThan(5),
          reason: 'Should have played multiple verses. Got: $versesPlayed');

      // Should have auto-advanced to Jonah
      expect(finalTitle, contains('Jonah'),
          reason: 'Should auto-advance to Jonah after Obadiah finishes. '
              'Final title: $finalTitle');
    });
  });
}
