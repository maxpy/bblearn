import Flutter
import Foundation
import AVFoundation

/// Flutter plugin that exposes AudioQueuePlayer via a MethodChannel.
///
/// Channel name: com.bibleaudio/audio_player
///
/// Methods (host → Flutter events via EventChannel):
///   loadFiles(urls: [String]) → void
///   loadClips(clips: [[String: Any]]) → void
///   play() → void
///   pause() → void
///   stop() → void
///   seekToClip(idx: Int) → void
///   getPosition() → Double
///   getCurrentClipIndex() → Int
///
/// Events (Flutter ← native via EventChannel "com.bibleaudio/audio_events"):
///   {"type": "advance", "idx": Int}
///   {"type": "finished"}
@objc class AudioPlayerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  private let player = AudioQueuePlayer()
  private var eventSink: FlutterEventSink?

  static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "com.bibleaudio/audio_player",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "com.bibleaudio/audio_events",
      binaryMessenger: registrar.messenger()
    )
    let instance = AudioPlayerPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  override init() {
    super.init()
    player.onAdvance = { [weak self] idx in
      self?.eventSink?(["type": "advance", "idx": idx])
    }
    player.onFinished = { [weak self] in
      self?.eventSink?(["type": "finished"])
    }
  }

  // MARK: - FlutterPlugin

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "loadFiles":
      guard let args = call.arguments as? [String: Any],
            let urlStrings = args["urls"] as? [String] else {
        result(FlutterError(code: "BAD_ARGS", message: "urls required", details: nil))
        return
      }
      let urls = urlStrings.compactMap { URL(string: $0) }
      let group = DispatchGroup()
      var loadError: Error?
      for url in urls {
        group.enter()
        player.loadFile(url: url) { error in
          if let e = error { loadError = e }
          group.leave()
        }
      }
      group.notify(queue: .main) {
        if let e = loadError {
          result(FlutterError(code: "LOAD_ERROR", message: e.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }

    case "loadClips":
      guard let args = call.arguments as? [String: Any],
            let rawClips = args["clips"] as? [[String: Any]] else {
        result(FlutterError(code: "BAD_ARGS", message: "clips required", details: nil))
        return
      }
      let clips: [AudioQueuePlayer.Clip] = rawClips.compactMap { d in
        guard
          let urlStr = d["url"] as? String,
          let url = URL(string: urlStr),
          let start = d["start"] as? Double,
          let end = d["end"] as? Double,
          let speed = d["speed"] as? Double
        else { return nil }
        return AudioQueuePlayer.Clip(fileURL: url, startSec: start, endSec: end, speed: speed)
      }
      player.loadClips(clips)
      result(nil)

    case "play":
      player.play()
      result(nil)

    case "pause":
      player.pause()
      result(nil)

    case "stop":
      player.stop()
      result(nil)

    case "seekToClip":
      guard let args = call.arguments as? [String: Any],
            let idx = args["idx"] as? Int else {
        result(FlutterError(code: "BAD_ARGS", message: "idx required", details: nil))
        return
      }
      player.seekToClip(idx)
      result(nil)

    case "getPosition":
      result(player.currentPosition())

    case "getCurrentClipIndex":
      result(player.currentClipIndex())

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
