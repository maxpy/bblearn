import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/timed_verse.dart';
import 'app_providers.dart';

/// State for the audio player.
class AudioPlayerState {
  final String? currentBookId;
  final int? currentChapter;
  final Duration position;
  final Duration? duration;
  final bool isPlaying;
  final bool isLoading;
  final double speed;
  final List<TimedVerse> verses;
  final String? error;

  const AudioPlayerState({
    this.currentBookId,
    this.currentChapter,
    this.position = Duration.zero,
    this.duration,
    this.isPlaying = false,
    this.isLoading = false,
    this.speed = 1.0,
    this.verses = const [],
    this.error,
  });

  AudioPlayerState copyWith({
    String? currentBookId,
    int? currentChapter,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isLoading,
    double? speed,
    List<TimedVerse>? verses,
    String? error,
  }) {
    return AudioPlayerState(
      currentBookId: currentBookId ?? this.currentBookId,
      currentChapter: currentChapter ?? this.currentChapter,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      speed: speed ?? this.speed,
      verses: verses ?? this.verses,
      error: error,
    );
  }

  /// Returns the currently active verse based on playback position.
  TimedVerse? get activeVerse {
    for (final verse in verses) {
      if (verse.isActiveAt(position)) return verse;
    }
    return null;
  }
}

/// Notifier that manages audio playback state.
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final Ref _ref;

  AudioPlayerNotifier(this._ref) : super(const AudioPlayerState()) {
    _listenToAudioStreams();
  }

  void _listenToAudioStreams() {
    final audioService = _ref.read(audioServiceProvider);

    audioService.positionStream.listen((pos) {
      if (mounted) state = state.copyWith(position: pos);
    });

    audioService.durationStream.listen((dur) {
      if (mounted) state = state.copyWith(duration: dur);
    });

    audioService.playerStateStream.listen((playerState) {
      if (mounted) {
        state = state.copyWith(
          isPlaying: playerState.playing,
          isLoading:
              playerState.processingState == ProcessingState.loading ||
              playerState.processingState == ProcessingState.buffering,
        );
      }
    });
  }

  /// Load and play audio for a book chapter.
  Future<void> loadChapter(String bookId, int chapter) async {
    state = state.copyWith(
      isLoading: true,
      currentBookId: bookId,
      currentChapter: chapter,
      error: null,
    );

    try {
      final dataService = _ref.read(bibleDataServiceProvider);
      final audioService = _ref.read(audioServiceProvider);

      // Fetch verses and load audio in parallel
      final results = await Future.wait([
        dataService.fetchVerses(bookId, chapter),
        audioService.load(dataService.getAudioUrl(bookId, chapter)),
      ]);

      final verses = results[0] as List<TimedVerse>;

      state = state.copyWith(
        verses: verses,
        isLoading: false,
      );

      await audioService.play();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load chapter: $e',
      );
    }
  }

  Future<void> play() => _ref.read(audioServiceProvider).play();
  Future<void> pause() => _ref.read(audioServiceProvider).pause();

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) =>
      _ref.read(audioServiceProvider).seek(position);

  Future<void> seekForward() =>
      seek(state.position + const Duration(seconds: 10));

  Future<void> seekBackward() {
    final newPos = state.position - const Duration(seconds: 10);
    return seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  Future<void> setSpeed(double speed) async {
    await _ref.read(audioServiceProvider).setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  /// Seek to a specific verse's start time.
  Future<void> seekToVerse(int verseNumber) async {
    final verse = state.verses.where((v) => v.verseNumber == verseNumber);
    if (verse.isNotEmpty) {
      await seek(verse.first.startTime);
    }
  }
}

/// Provider for the audio player state.
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier(ref);
});
