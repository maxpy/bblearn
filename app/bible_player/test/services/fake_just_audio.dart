import 'dart:async';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

/// A fake [JustAudioPlatform] that never touches native channels.
/// Set [JustAudioPlatform.instance = FakeJustAudioPlatform()] before
/// creating any [AudioPlayer] in tests.
class FakeJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return FakeAudioPlayerPlatform(request.id);
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
      DisposePlayerRequest request) async {
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
      DisposeAllPlayersRequest request) async {
    return DisposeAllPlayersResponse();
  }
}

class FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  final _eventController =
      StreamController<PlaybackEventMessage>.broadcast();

  FakeAudioPlayerPlatform(super.id);

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _eventController.stream;

  PlaybackEventMessage _readyEvent() => PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updateTime: DateTime.now(),
        updatePosition: Duration.zero,
        bufferedPosition: const Duration(seconds: 10),
        duration: const Duration(seconds: 10),
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: null,
      );

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    // Emit ready state so AudioPlayer stops waiting on processingStateStream
    Future.microtask(() => _eventController.add(_readyEvent()));
    return LoadResponse(duration: const Duration(seconds: 10));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();

  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
          SetSkipSilenceRequest request) async =>
      SetSkipSilenceResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
          SetShuffleModeRequest request) async =>
      SetShuffleModeResponse();

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
          SetShuffleOrderRequest request) async =>
      SetShuffleOrderResponse();

  @override
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
          SetAndroidAudioAttributesRequest request) async =>
      SetAndroidAudioAttributesResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _eventController.close();
    return DisposeResponse();
  }

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
          ConcatenatingInsertAllRequest request) async =>
      ConcatenatingInsertAllResponse();

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
          ConcatenatingRemoveRangeRequest request) async =>
      ConcatenatingRemoveRangeResponse();

  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
          ConcatenatingMoveRequest request) async =>
      ConcatenatingMoveResponse();
}
