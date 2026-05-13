import 'package:just_audio/just_audio.dart';

/// Wraps [AudioPlayer] to provide Bible audio playback.
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;

  /// Load audio from a URL.
  Future<Duration?> load(String url) async {
    return _player.setUrl(url);
  }

  /// Play the loaded audio.
  Future<void> play() => _player.play();

  /// Pause playback.
  Future<void> pause() => _player.pause();

  /// Seek to a specific position.
  Future<void> seek(Duration position) => _player.seek(position);

  /// Set playback speed.
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// Stop and release resources.
  Future<void> dispose() => _player.dispose();
}
