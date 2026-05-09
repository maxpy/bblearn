import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bible_book.dart';
import '../models/chapter_data.dart';
import '../models/play_sequence.dart';
import '../services/db_service.dart';
import '../services/audio_player_service.dart';
import '../services/prefs_service.dart';

/// Provides the singleton [AudioPlayerService].
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Streams the current [PlaybackState] from the audio player.
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  return ref.watch(audioPlayerServiceProvider).stateStream;
});

/// The currently selected play sequence.
final currentSequenceProvider =
    NotifierProvider<CurrentSequenceNotifier, PlaySequence>(
  CurrentSequenceNotifier.new,
);

class CurrentSequenceNotifier extends Notifier<PlaySequence> {
  @override
  PlaySequence build() {
    final name = PrefsService.instance.loadSequenceName();
    return PresetSequences.byName(name) ?? PresetSequences.enCn;
  }

  void setSequence(PlaySequence sequence) {
    PrefsService.instance.saveSequenceName(sequence.name);
    state = sequence;
  }
}

/// Per-step speed multipliers (index → multiplier, default 1.0).
final stepSpeedsProvider =
    NotifierProvider<StepSpeedsNotifier, Map<String, double>>(
  StepSpeedsNotifier.new,
);

class StepSpeedsNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() => PrefsService.instance.loadStepSpeeds();

  void setSpeed(String version, double speed) {
    state = {...state, version: speed};
    PrefsService.instance.saveStepSpeeds(state);
  }

  void reset() {
    state = {};
    PrefsService.instance.saveStepSpeeds({});
  }
}



class BilingualPlayerState {
  final bool isLoading;
  final String? error;
  final Map<String, ChapterData> chapterData; // version → ChapterData
  final int bookNumber;
  final int chapter;

  const BilingualPlayerState({
    this.isLoading = false,
    this.error,
    this.chapterData = const {},
    this.bookNumber = 0,
    this.chapter = 0,
  });

  BilingualPlayerState copyWith({
    bool? isLoading,
    String? error,
    Map<String, ChapterData>? chapterData,
    int? bookNumber,
    int? chapter,
  }) {
    return BilingualPlayerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      chapterData: chapterData ?? this.chapterData,
      bookNumber: bookNumber ?? this.bookNumber,
      chapter: chapter ?? this.chapter,
    );
  }
}

/// Manages loading chapter data and driving [AudioPlayerService].
class BilingualPlayerNotifier extends Notifier<BilingualPlayerState> {
  bool _advancing = false;

  @override
  BilingualPlayerState build() {
    _advancing = false;
    // Register callback on AudioPlayerService for queue-finished events
    final svc = ref.read(audioPlayerServiceProvider);
    svc.onQueueFinished = _advanceToNextChapter;
    ref.onDispose(() => svc.onQueueFinished = null);

    // Restore last position (bookNumber/chapter only, no auto-play)
    return BilingualPlayerState(
      bookNumber: PrefsService.instance.loadLastBook(),
      chapter: PrefsService.instance.loadLastChapter(),
    );
  }

  void _advanceToNextChapter() {
    if (_advancing) return;
    _advancing = true;
    final book = BibleBook.allBooks.firstWhere(
      (b) => b.number == state.bookNumber,
      orElse: () => BibleBook.allBooks.first,
    );
    final nextChapter = state.chapter + 1;
    if (nextChapter <= book.chapters) {
      loadChapter(book: book, chapter: nextChapter);
    } else {
      final nextBookIdx =
          BibleBook.allBooks.indexWhere((b) => b.number == book.number) + 1;
      if (nextBookIdx < BibleBook.allBooks.length) {
        loadChapter(book: BibleBook.allBooks[nextBookIdx], chapter: 1);
      } else {
        _advancing = false;
      }
    }
  }

  Future<void> loadChapter({
    required BibleBook book,
    required int chapter,
    int? startVerse,
    bool autoPlay = true,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      bookNumber: book.number,
      chapter: chapter,
    );

    try {
      final sequence = ref.read(currentSequenceProvider);
      final stepSpeeds = ref.read(stepSpeedsProvider);
      final versions =
          sequence.steps.map((s) => s.version).toSet().toList();

      final chapterData = await DbService.instance.loadChapterAllVersions(
        versions: versions,
        book: book,
        chapter: chapter,
      );

      state = state.copyWith(isLoading: false, chapterData: chapterData);
      PrefsService.instance.saveLastPosition(book.number, chapter);

      await ref.read(audioPlayerServiceProvider).loadChapter(
            chapterDataByVersion: chapterData,
            sequence: sequence,
            stepSpeeds: stepSpeeds.isEmpty ? null : stepSpeeds,
            bookNumber: book.number,
            chapter: chapter,
            startVerse: startVerse,
            autoPlay: autoPlay,
          );
      _advancing = false;
    } catch (e) {
      _advancing = false;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final bilingualPlayerProvider =
    NotifierProvider<BilingualPlayerNotifier, BilingualPlayerState>(
  BilingualPlayerNotifier.new,
);
