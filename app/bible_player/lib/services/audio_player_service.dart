import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';

import '../models/chapter_data.dart';
import '../models/play_sequence.dart';
import 'play_queue.dart';

/// Current playback state exposed to the UI.
class PlaybackState {
  final bool isPlaying;
  final bool isLoading;
  final int currentVerse;
  final String currentVersion;
  final int currentBookNumber;
  final int currentChapter;
  final Duration position;
  final Duration totalDuration;
  final bool chapterFinished;

  const PlaybackState({
    this.isPlaying = false,
    this.isLoading = false,
    this.currentVerse = 1,
    this.currentVersion = 'KJV',
    this.currentBookNumber = 1,
    this.currentChapter = 1,
    this.position = Duration.zero,
    this.totalDuration = Duration.zero,
    this.chapterFinished = false,
  });

  PlaybackState copyWith({
    bool? isPlaying,
    bool? isLoading,
    int? currentVerse,
    String? currentVersion,
    int? currentBookNumber,
    int? currentChapter,
    Duration? position,
    Duration? totalDuration,
    bool? chapterFinished,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      currentVerse: currentVerse ?? this.currentVerse,
      currentVersion: currentVersion ?? this.currentVersion,
      currentBookNumber: currentBookNumber ?? this.currentBookNumber,
      currentChapter: currentChapter ?? this.currentChapter,
      position: position ?? this.position,
      totalDuration: totalDuration ?? this.totalDuration,
      chapterFinished: chapterFinished ?? this.chapterFinished,
    );
  }
}

/// Service that manages audio playback using just_audio.
class AudioPlayerService {
  late final AudioPlayer _player;
  PlayQueue? _queue;
  PlaybackState _state = const PlaybackState();
  final _stateController = StreamController<PlaybackState>.broadcast();
  Timer? _positionTimer;
  Timer? _pauseTimer;
  bool _disposed = false;
  // Guards against double-firing completion on web
  bool _completionFired = false;
  // Previous position for freeze detection on web
  Duration _prevPosition = Duration.zero;
  int _frozenCount = 0;

  /// Stream of playback state changes.
  Stream<PlaybackState> get stateStream => _stateController.stream;

  /// Current playback state.
  PlaybackState get state => _state;

  /// The current play queue.
  PlayQueue? get queue => _queue;

  /// Callback invoked when the entire queue finishes playing.
  void Function()? onQueueFinished;

  AudioPlayerService({AudioPlayer? player}) {
    _player = player ?? AudioPlayer();
    if (!kIsWeb) {
      _player.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed &&
            !_completionFired) {
          _completionFired = true;
          _onItemCompleted();
        }
      });
    }
  }

  bool _autoPlayEnabled = true;

  /// Load a chapter and build the play queue.
  Future<void> loadChapter({
    required Map<String, ChapterData> chapterDataByVersion,
    required PlaySequence sequence,
    Map<int, double>? stepSpeeds,
    required int bookNumber,
    required int chapter,
    int? startVerse,
    bool autoPlay = true,
  }) async {
    _autoPlayEnabled = autoPlay;
    _updateState(_state.copyWith(
      isLoading: true,
      currentBookNumber: bookNumber,
      currentChapter: chapter,
      chapterFinished: false,
    ));

    _queue = PlayQueue.build(
      chapterDataByVersion: chapterDataByVersion,
      sequence: sequence,
      stepSpeeds: stepSpeeds,
    );

    if (startVerse != null && startVerse > 1) {
      _queue!.seekToVerse(startVerse);
    }

    _updateState(_state.copyWith(isLoading: false));

    if (autoPlay) {
      await _playCurrentItem();
    } else {
      await _playCurrentItem(autoPlay: false);
    }
  }

  /// Play / resume playback.
  Future<void> play() async {
    if (_queue == null || _queue!.isEmpty) return;
    _autoPlayEnabled = true;
    _updateState(_state.copyWith(isPlaying: true));
    await _player.play();
    _startPositionTracking();
  }

  /// Pause playback.
  Future<void> pause() async {
    await _player.pause();
    _pauseTimer?.cancel();
    _updateState(_state.copyWith(isPlaying: false));
    _stopPositionTracking();
  }

  /// Toggle play / pause.
  Future<void> togglePlayPause() async {
    if (_state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Skip to the next verse.
  Future<void> nextVerse() async {
    if (_queue == null) return;
    _pauseTimer?.cancel();
    final item = _queue!.nextVerse();
    if (item != null) {
      await _playCurrentItem();
    } else {
      await _onQueueFinished();
    }
  }

  /// Go to the previous verse.
  Future<void> previousVerse() async {
    if (_queue == null) return;
    _pauseTimer?.cancel();
    final item = _queue!.previousVerse();
    if (item != null) {
      await _playCurrentItem();
    }
  }

  /// Seek to a specific verse.
  Future<void> seekToVerse(int verse) async {
    if (_queue == null) return;
    _pauseTimer?.cancel();
    final item = _queue!.seekToVerse(verse);
    if (item != null) {
      await _playCurrentItem();
    }
  }

  /// Set playback speed.
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Play the current item in the queue.
  Future<void> _playCurrentItem({bool autoPlay = true}) async {
    final item = _queue?.current;
    if (item == null) {
      await _onQueueFinished();
      return;
    }

    if (item.isPause) {
      if (!autoPlay) return;
      // Handle pause items: wait for the duration then advance
      _completionFired = false;
      _prevPosition = Duration.zero;
      _frozenCount = 0;
      _updateState(_state.copyWith(
        isPlaying: true,
        currentVerse: item.verse,
      ));
      _pauseTimer?.cancel();
      _pauseTimer = Timer(
        Duration(milliseconds: (item.pauseDuration * 1000).round()),
        () {
          _onItemCompleted();
        },
      );
      return;
    }

    // Audio item
    _updateState(_state.copyWith(
      isLoading: true,
      currentVerse: item.verse,
      currentVersion: item.version,
    ));

    try {
      _stopPositionTracking();

      final uri = item.audioPath.startsWith('http')
          ? Uri.parse(item.audioPath)
          : Uri(scheme: 'asset', path: item.audioPath);

      _completionFired = false;
      _prevPosition = Duration.zero;
      _frozenCount = 0;

      final duration = await _player.setAudioSource(
        ClippingAudioSource(
          child: AudioSource.uri(uri),
          start: Duration(milliseconds: (item.startTime * 1000).round()),
          end: Duration(milliseconds: (item.endTime * 1000).round()),
        ),
      );

      await _player.setSpeed(item.speed);

      if (autoPlay) {
        _updateState(_state.copyWith(
          isLoading: false,
          isPlaying: true,
          totalDuration: duration ?? Duration.zero,
          position: Duration.zero,
        ));
        await _player.play();
        _startPositionTracking();
      } else {
        _updateState(_state.copyWith(
          isLoading: false,
          isPlaying: false,
          totalDuration: duration ?? Duration.zero,
          position: Duration.zero,
        ));
      }
    } catch (e) {
      _updateState(_state.copyWith(isLoading: false));
      if (autoPlay) _onItemCompleted();
    }
  }

  /// Called when the current item finishes.
  void _onItemCompleted() {
    if (_disposed || _queue == null) return;
    final next = _queue!.nextItem();
    if (next != null) {
      _playCurrentItem();
    } else {
      _onQueueFinished();
    }
  }

  /// Called when the entire queue is finished.
  Future<void> _onQueueFinished() async {
    _stopPositionTracking();
    _updateState(_state.copyWith(
      isPlaying: false,
      position: Duration.zero,
      chapterFinished: true,
    ));
    if (_autoPlayEnabled) {
      onQueueFinished?.call();
    }
  }

  /// Start periodic position updates.
  void _startPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_disposed) return;
      final pos = _player.position;
      _updateState(_state.copyWith(position: pos));

      // On web, ClippingAudioSource doesn't fire ProcessingState.completed
      // reliably. Detect completion by position freezing at the end of the clip.
      if (kIsWeb && !_completionFired) {
        final item = _queue?.current;
        if (item != null && !item.isPause) {
          final clipMs = ((item.endTime - item.startTime) * 1000).round();
          // Position freezes when clip ends; require >80% through to avoid
          // false triggers at the very start (position=0 before play starts)
          if (pos == _prevPosition &&
              pos.inMilliseconds > (clipMs * 0.8).round()) {
            _frozenCount++;
            if (_frozenCount >= 2) {
              _completionFired = true;
              _onItemCompleted();
            }
          } else {
            _frozenCount = 0;
          }
          _prevPosition = pos;
        }
      }
    });
  }

  /// Stop periodic position updates.
  void _stopPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  /// Update state and notify listeners.
  void _updateState(PlaybackState newState) {
    _state = newState;
    if (!_disposed) {
      _stateController.add(newState);
    }
  }

  /// Release resources.
  void dispose() {
    _disposed = true;
    _positionTimer?.cancel();
    _pauseTimer?.cancel();
    _stateController.close();
    _player.dispose();
  }
}
