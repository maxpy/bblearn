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
///
/// Uses ConcatenatingAudioSource so the native AVQueuePlayer handles all
/// item transitions. This allows playback to continue when the screen is
/// locked without relying on Dart timers or stream callbacks.
class AudioPlayerService {
  late final AudioPlayer _player;
  PlayQueue? _queue;

  /// Maps concatenating source index → PlayQueueItem.
  List<PlayQueueItem> _indexMap = [];

  PlaybackState _state = const PlaybackState();
  final _stateController = StreamController<PlaybackState>.broadcast();
  Timer? _positionTimer;
  bool _disposed = false;
  bool _autoPlayEnabled = true;

  // Web-only completion detection via position freeze.
  Duration _prevPosition = Duration.zero;
  int _frozenCount = 0;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _currentIndexSub;

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

    _playerStateSub = _player.playerStateStream.listen((ps) {
      // ignore: avoid_print
      print('[APS] state=${ps.processingState} playing=${ps.playing}');
      if (ps.processingState == ProcessingState.completed) {
        _onQueueFinished();
      }
    });

    _currentIndexSub = _player.currentIndexStream.listen((index) {
      if (index == null || index >= _indexMap.length) return;
      final item = _indexMap[index];
      if (item.isPause) return;
      // Update UI state for the new item.
      _updateState(_state.copyWith(
        currentVerse: item.verse,
        currentVersion: item.version,
        position: Duration.zero,
      ));
      // Apply per-item speed via microtask to avoid rxdart re-entrancy error.
      Future.microtask(() {
        if (!_disposed) _player.setSpeed(item.speed);
      });
    });
  }

  /// Load a chapter and build the play queue.
  Future<void> loadChapter({
    required Map<String, ChapterData> chapterDataByVersion,
    required PlaySequence sequence,
    Map<String, double>? stepSpeeds,
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

    await _player.stop();
    _stopPositionTracking();

    _queue = PlayQueue.build(
      chapterDataByVersion: chapterDataByVersion,
      sequence: sequence,
      stepSpeeds: stepSpeeds,
    );

    // Build ConcatenatingAudioSource from queue items.
    final sources = <AudioSource>[];
    _indexMap = [];

    for (final item in _queue!.items) {
      if (item.isPause) {
        // SilenceAudioSource is not supported on iOS native layer — skip gaps.
        // The natural silence at the end of each audio clip provides the gap.
        if (kIsWeb) {
          final pauseMs = (item.pauseDuration * 1000).round().clamp(100, 10000);
          sources.add(SilenceAudioSource(
            duration: Duration(milliseconds: pauseMs),
          ));
          _indexMap.add(item);
        }
        continue;
      }
      final uri = item.audioPath.startsWith('http')
          ? Uri.parse(item.audioPath)
          : Uri(scheme: 'asset', path: item.audioPath);
      sources.add(ClippingAudioSource(
        child: AudioSource.uri(uri),
        start: Duration(milliseconds: (item.startTime * 1000).round()),
        // Add 150ms padding to end to prevent AVQueuePlayer from cutting off
        // the last word early when transitioning to the next item.
        end: Duration(milliseconds: (item.endTime * 1000).round() + 150),
      ));
      _indexMap.add(item);
    }

    // Find start index.
    int startIndex = 0;
    if (startVerse != null && startVerse > 1) {
      for (int i = 0; i < _indexMap.length; i++) {
        if (!_indexMap[i].isPause && _indexMap[i].verse == startVerse) {
          startIndex = i;
          break;
        }
      }
    }

    // Set initial verse/version from first non-pause item at or after startIndex.
    for (int i = startIndex; i < _indexMap.length; i++) {
      if (!_indexMap[i].isPause) {
        _updateState(_state.copyWith(
          isLoading: false,
          currentVerse: _indexMap[i].verse,
          currentVersion: _indexMap[i].version,
        ));
        break;
      }
    }

    if (sources.isEmpty) {
      _updateState(_state.copyWith(isLoading: false));
      return;
    }

    try {
      // ignore: avoid_print
      print('[APS] loading ${sources.length} sources, startIndex=$startIndex');
      final duration = await _player.setAudioSource(
        ConcatenatingAudioSource(
          children: sources,
        ),
        initialIndex: startIndex,
        initialPosition: Duration.zero,
      );

      // Set initial speed.
      if (startIndex < _indexMap.length) {
        await _player.setSpeed(_indexMap[startIndex].speed);
      }

      _updateState(_state.copyWith(
        isLoading: false,
        isPlaying: false,
        totalDuration: duration ?? Duration.zero,
        position: Duration.zero,
      ));

      if (autoPlay) {
        await play();
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[APS] loadChapter error: $e\n$st');
      _updateState(_state.copyWith(isLoading: false));
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
    _stopPositionTracking();
    _updateState(_state.copyWith(isPlaying: false));
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
    final currentVerse = _state.currentVerse;
    // Find the next verse index after current.
    final currentIdx = _player.currentIndex ?? 0;
    for (int i = currentIdx + 1; i < _indexMap.length; i++) {
      final item = _indexMap[i];
      if (!item.isPause && item.verse > currentVerse) {
        await _player.seek(Duration.zero, index: i);
        return;
      }
    }
    await _onQueueFinished();
  }

  /// Go to the previous verse.
  Future<void> previousVerse() async {
    final currentVerse = _state.currentVerse;
    final currentIdx = _player.currentIndex ?? 0;
    // Find the first index of the previous verse.
    for (int i = currentIdx - 1; i >= 0; i--) {
      final item = _indexMap[i];
      if (!item.isPause && item.verse < currentVerse) {
        await _player.seek(Duration.zero, index: i);
        return;
      }
    }
    // Already at first verse — seek to beginning.
    await _player.seek(Duration.zero, index: 0);
  }

  /// Seek to a specific verse.
  Future<void> seekToVerse(int verse) async {
    for (int i = 0; i < _indexMap.length; i++) {
      if (!_indexMap[i].isPause && _indexMap[i].verse == verse) {
        await _player.seek(Duration.zero, index: i);
        return;
      }
    }
  }

  /// Set playback speed.
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
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
      // reliably. Detect completion by position freezing at the end of clip.
      if (kIsWeb) {
        final idx = _player.currentIndex;
        if (idx != null && idx < _indexMap.length) {
          final item = _indexMap[idx];
          if (!item.isPause) {
            final clipMs = ((item.endTime - item.startTime) * 1000).round();
            if (pos == _prevPosition &&
                pos.inMilliseconds > (clipMs * 0.8).round()) {
              _frozenCount++;
              if (_frozenCount >= 2) {
                _frozenCount = 0;
                // Advance to next item on web.
                final nextIdx = (idx + 1);
                if (nextIdx < _indexMap.length) {
                  _player.seek(Duration.zero, index: nextIdx);
                } else {
                  _onQueueFinished();
                }
              }
            } else {
              _frozenCount = 0;
            }
            _prevPosition = pos;
          }
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
    _playerStateSub?.cancel();
    _currentIndexSub?.cancel();
    _stateController.close();
    _player.dispose();
  }
}
