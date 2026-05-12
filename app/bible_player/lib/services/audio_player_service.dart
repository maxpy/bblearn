import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
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

/// iOS: uses native AVAudioEngine via platform channel.
/// Web: falls back to just_audio with ConcatenatingAudioSource.
class AudioPlayerService {
  static const _methodChannel = MethodChannel('com.bibleaudio/audio_player');
  static const _eventChannel = EventChannel('com.bibleaudio/audio_events');

  PlayQueue? _queue;
  List<PlayQueueItem> _items = [];
  int _currentIdx = 0;

  PlaybackState _state = const PlaybackState();
  final _stateController = StreamController<PlaybackState>.broadcast();
  StreamSubscription? _eventSub;
  Timer? _positionTimer;
  bool _disposed = false;

  // Web fallback — see _webPlayers map below
  bool _webSourceLoaded = false;

  Stream<PlaybackState> get stateStream => _stateController.stream;
  PlaybackState get state => _state;
  PlayQueue? get queue => _queue;
  void Function()? onQueueFinished;

  AudioPlayerService() {
    if (!kIsWeb) {
      _eventSub = _eventChannel.receiveBroadcastStream().listen(_onNativeEvent);
    }
  }

  void _onNativeEvent(dynamic event) {
    if (_disposed) return;
    final map = event as Map;
    final type = map['type'] as String;
    if (type == 'advance') {
      final idx = map['idx'] as int;
      _currentIdx = idx;
      if (idx < _items.length) {
        final item = _items[idx];
        _updateState(_state.copyWith(
          currentVerse: item.verse,
          currentVersion: item.version,
        ));
      }
    } else if (type == 'finished') {
      _onQueueFinished();
    }
  }

  // MARK: - Public API

  Future<void> loadChapter({
    required Map<String, ChapterData> chapterDataByVersion,
    required PlaySequence sequence,
    Map<String, double>? stepSpeeds,
    required int bookNumber,
    required int chapter,
    int? startVerse,
    bool autoPlay = true,
  }) async {
    final queue = PlayQueue.build(
      chapterDataByVersion: chapterDataByVersion,
      sequence: sequence,
      stepSpeeds: stepSpeeds,
      startVerse: startVerse,
    );

    _queue = queue;
    _items = queue.items.where((i) => !i.isPause).toList();
    _currentIdx = 0;

    if (startVerse != null) {
      for (int i = 0; i < _items.length; i++) {
        if (_items[i].verse >= startVerse) {
          _currentIdx = i;
          break;
        }
      }
    }

    _updateState(_state.copyWith(
      isLoading: true,
      currentBookNumber: bookNumber,
      currentChapter: chapter,
      currentVerse: _items.isEmpty ? 1 : _items[_currentIdx].verse,
      currentVersion: _items.isEmpty ? 'CUV' : _items[_currentIdx].version,
      chapterFinished: false,
    ));

    if (kIsWeb) {
      if (_items.isEmpty) {
        _updateState(_state.copyWith(isLoading: false));
        return;
      }
      try {
        await _loadChapterWeb(queue);
      } catch (e) {
        // ignore: avoid_print
        print('[APS] _loadChapterWeb error: $e');
        _updateState(_state.copyWith(isLoading: false));
        return;
      }
      // On web, don't autoPlay here — setAudioSource needs a user gesture on Safari.
      // The play button will call play() which triggers lazy source loading.
      _updateState(_state.copyWith(isLoading: false));
      return;
    }

    final urls = _items.map((i) => i.audioPath).toSet().toList();
    try {
      await _methodChannel.invokeMethod('loadFiles', {'urls': urls});
    } catch (e) {
      // ignore: avoid_print
      print('[APS] loadFiles error: $e');
      _updateState(_state.copyWith(isLoading: false));
      return;
    }

    final clips = _items.map((item) => {
      'url': item.audioPath,
      'start': item.startTime,
      'end': item.endTime,
      'speed': item.speed,
    }).toList();

    try {
      await _methodChannel.invokeMethod('loadClips', {'clips': clips});
    } catch (e) {
      // ignore: avoid_print
      print('[APS] loadClips error: $e');
    }

    if (_currentIdx > 0) {
      await _methodChannel.invokeMethod('seekToClip', {'idx': _currentIdx});
    }

    _updateState(_state.copyWith(isLoading: false));

    if (autoPlay) await play();
  }

  Future<void> play() async {
    if (_items.isEmpty) return;
    // ignore: avoid_print
    print('[APS] play() called, items=${_items.length}, webSourceLoaded=$_webSourceLoaded');
    _updateState(_state.copyWith(isPlaying: true));

    if (kIsWeb) {
      try {
        if (!_webSourceLoaded) {
          await _webPlayerSetSource();
          _startWebClipTimer();
        }
        _webPlayAndAdvance(); // fire-and-forget chain
      } catch (e) {
        // ignore: avoid_print
        print('[APS] web play() error (likely autoplay policy): $e');
        _updateState(_state.copyWith(isPlaying: false));
      }
      _startPositionTracking();
      return;
    }

    await _methodChannel.invokeMethod('play');
    _startPositionTracking();
  }

  Future<void> pause() async {
    _updateState(_state.copyWith(isPlaying: false));
    _stopPositionTracking();

    if (kIsWeb) {
      await _webPlayer?.pause();
      return;
    }

    await _methodChannel.invokeMethod('pause');
  }

  /// Update per-version speeds without reloading files.
  /// Rebuilds clips with new speeds and seeks back to current verse.
  Future<void> updateSpeeds({
    required PlaySequence sequence,
    required Map<String, double> stepSpeeds,
  }) async {
    if (_queue == null || _items.isEmpty) return;

    // Rebuild items with updated speeds
    final updatedItems = _items.map((item) {
      final speed = stepSpeeds[item.version] ?? 1.0;
      return item.copyWithSpeed(speed);
    }).toList();
    _items = updatedItems;

    if (kIsWeb) {
      // Web: no easy way to update speed mid-play; just update state
      return;
    }

    final wasPlaying = _state.isPlaying;
    final currentVerse = _state.currentVerse;

    final clips = _items.map((item) => {
      'url': item.audioPath,
      'start': item.startTime,
      'end': item.endTime,
      'speed': item.speed,
    }).toList();

    await _methodChannel.invokeMethod('loadClips', {'clips': clips});

    // Seek back to current verse
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].verse >= currentVerse) {
        _currentIdx = i;
        await _methodChannel.invokeMethod('seekToClip', {'idx': i});
        break;
      }
    }

    if (wasPlaying) await play();
  }

  Future<void> togglePlayPause() async {
    if (_state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekToVerse(int verse) async {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].verse == verse) {
        _currentIdx = i;
        if (kIsWeb) {
          if (_webSourceLoaded) {
            final wasPlaying = _state.isPlaying;
            _updateState(_state.copyWith(isPlaying: false)); // stop current chain
            _webPlayerStateSub?.cancel();
            await _webPlayer?.pause();
            await _webPrepareClip(i);
            if (wasPlaying) {
              _updateState(_state.copyWith(isPlaying: true));
              _webPlayAndAdvance();
            }
          } else {
            _currentIdx = i;
            _updateState(_state.copyWith(
              currentVerse: _items[i].verse,
              currentVersion: _items[i].version,
            ));
          }
        } else {
          _updateState(_state.copyWith(
            currentVerse: _items[i].verse,
            currentVersion: _items[i].version,
          ));
          await _methodChannel.invokeMethod('seekToClip', {'idx': i});
        }
        return;
      }
    }
  }

  Future<void> nextVerse() async {
    final verses = _items.map((i) => i.verse).toSet().toList()..sort();
    final currentVerse = _state.currentVerse;
    final idx = verses.indexOf(currentVerse);
    if (idx >= 0 && idx < verses.length - 1) {
      await seekToVerse(verses[idx + 1]);
    }
  }

  Future<void> previousVerse() async {
    final verses = _items.map((i) => i.verse).toSet().toList()..sort();
    final currentVerse = _state.currentVerse;
    final idx = verses.indexOf(currentVerse);
    if (idx > 0) {
      await seekToVerse(verses[idx - 1]);
    }
  }

  void _onQueueFinished() {
    _stopPositionTracking();
    _updateState(_state.copyWith(
      isPlaying: false,
      chapterFinished: true,
    ));
    onQueueFinished?.call();
  }

  void _startPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (_disposed) return;
      if (kIsWeb) {
        _updateState(_state.copyWith(position: _webPlayer?.position ?? Duration.zero));
        return;
      }
      try {
        final pos = await _methodChannel.invokeMethod<double>('getPosition') ?? 0.0;
        final idx = await _methodChannel.invokeMethod<int>('getCurrentClipIndex') ?? _currentIdx;
        _currentIdx = idx;
        if (idx < _items.length) {
          final item = _items[idx];
          _updateState(_state.copyWith(
            position: Duration(milliseconds: (pos * 1000).round()),
            currentVerse: item.verse,
            currentVersion: item.version,
          ));
        }
      } catch (_) {}
    });
  }

  void _stopPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _updateState(PlaybackState newState) {
    _state = newState;
    if (!_disposed) _stateController.add(newState);
  }

  void dispose() {
    _disposed = true;
    _stopPositionTracking();
    _webClipTimer?.cancel();
    _webPlayerStateSub?.cancel();
    _eventSub?.cancel();
    _stateController.close();
    _webPlayer?.dispose();
    for (final p in _webPlayers.values) {
      p.dispose();
    }
    _webPlayers.clear();
    if (!kIsWeb) {
      _methodChannel.invokeMethod('stop');
    }
  }

  // MARK: - Web fallback
  //
  // One AudioPlayer per unique MP3 URL (cached in _webPlayers).
  // Uses seek() + positionStream to clip verses precisely, avoiding
  // ClippingAudioSource which has MP3 frame-alignment seek errors on web.

  final Map<String, AudioPlayer> _webPlayers = {};
  AudioPlayer? _webPlayer;       // current active player
  Timer? _webClipTimer;
  StreamSubscription? _webPlayerStateSub;
  double _webClipEnd = 0.0;      // endTime of the currently playing clip (seconds)

  Future<void> _loadChapterWeb(PlayQueue queue) async {
    _webClipTimer?.cancel();
    _webPlayerStateSub?.cancel();
    for (final p in _webPlayers.values) {
      await p.dispose();
    }
    _webPlayers.clear();
    _webPlayer = null;
    _webSourceLoaded = false;
  }

  /// Called lazily on first play() — requires a user gesture on Safari.
  Future<void> _webPlayerSetSource() async {
    await _webPrepareClip(_currentIdx);
    _webSourceLoaded = true;
  }

  /// Ensure the AudioPlayer for [idx]'s URL is loaded and seeked to startTime.
  Future<void> _webPrepareClip(int idx) async {
    if (idx >= _items.length) {
      _onQueueFinished();
      return;
    }
    final item = _items[idx];
    final url = item.audioPath;
    // ignore: avoid_print
    print('[APS] _webLoadClip idx=$idx verse=${item.verse} url=$url');

    AudioPlayer player;
    if (_webPlayers.containsKey(url)) {
      player = _webPlayers[url]!;
    } else {
      player = AudioPlayer();
      final uri = url.startsWith('http')
          ? Uri.parse(url)
          : Uri(scheme: 'asset', path: url);
      await player.setAudioSource(AudioSource.uri(uri));
      _webPlayers[url] = player;
    }

    _webPlayer = player;
    _webClipEnd = item.endTime;
    final startMs = (item.startTime * 1000).round();
    // ignore: avoid_print
    print('[APS] seek idx=$idx start=${item.startTime.toStringAsFixed(3)}s end=${item.endTime.toStringAsFixed(3)}s');
    await player.seek(Duration(milliseconds: startMs));

    _currentIdx = idx;
    _updateState(_state.copyWith(
      currentVerse: item.verse,
      currentVersion: item.version,
    ));
  }

  /// Play current clip and advance when position reaches endTime.
  void _webPlayAndAdvance() {
    if (_disposed || !_state.isPlaying) return;
    _webPlayerStateSub?.cancel();

    final endMs = (_webClipEnd * 1000).round();

    _webPlayerStateSub = _webPlayer!.positionStream.listen((pos) async {
      if (pos.inMilliseconds >= endMs) {
        _webPlayerStateSub?.cancel();
        // ignore: avoid_print
        print('[APS] clip done at pos=${pos.inMilliseconds}ms endMs=$endMs');
        await _webPlayer!.pause();
        if (_disposed || !_state.isPlaying) return;
        final next = _currentIdx + 1;
        if (next >= _items.length) {
          _onQueueFinished();
          return;
        }
        await _webPrepareClip(next);
        _webPlayAndAdvance();
      }
    });

    _webPlayer!.play().catchError((_) {});
  }

  void _startWebClipTimer() {
    // No-op: verse tracking is handled in _webPrepareClip
  }
}
