import AVFoundation
import Foundation

/// Plays a sequence of audio clips (verse segments) from one or two MP3 files.
/// Uses AVAudioEngine with a single AVAudioPlayerNode so the audio session
/// is never interrupted between clips — background/lock-screen playback works.
@objc class AudioQueuePlayer: NSObject {

  // MARK: - Types

  struct Clip {
    let fileURL: URL
    let startSec: Double
    let endSec: Double
    let speed: Double
  }

  // MARK: - Private state

  private let engine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()
  private let varispeed = AVAudioUnitTimePitch()
  private var files: [URL: AVAudioFile] = [:]

  private var clips: [Clip] = []
  private var currentIdx: Int = 0
  private var playing: Bool = false
  private var clipStartHostTime: Double = 0

  // MARK: - Callbacks to Flutter

  var onAdvance: ((_ idx: Int) -> Void)?
  var onFinished: (() -> Void)?

  // MARK: - Init

  override init() {
    super.init()
    engine.attach(playerNode)
    engine.attach(varispeed)
    engine.connect(playerNode, to: varispeed, format: nil)
    engine.connect(varispeed, to: engine.mainMixerNode, format: nil)
    setupAudioSession()
  }

  // MARK: - Audio Session

  private func setupAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(
        .playback,
        mode: .default,
        options: [.allowBluetooth, .allowBluetoothA2DP]
      )
      try session.setActive(true)
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleInterruption(_:)),
        name: AVAudioSession.interruptionNotification,
        object: session
      )
    } catch {
      print("[AQP] audio session setup error: \(error)")
    }
  }

  @objc private func handleInterruption(_ notification: Notification) {
    guard
      let info = notification.userInfo,
      let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: typeValue)
    else { return }

    if type == .began {
      pauseInternal()
    } else {
      if let optValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
        let opts = AVAudioSession.InterruptionOptions(rawValue: optValue)
        if opts.contains(.shouldResume) && playing {
          resumeInternal()
        }
      }
    }
  }

  // MARK: - Public API

  /// Load an audio file. Downloads to cache if URL is remote.
  func loadFile(url: URL, completion: @escaping (Error?) -> Void) {
    if url.isFileURL {
      openLocalFile(url: url, originalURL: url, completion: completion)
    } else {
      downloadAndCache(url: url, completion: completion)
    }
  }

  private func localCacheURL(for remoteURL: URL) -> URL {
    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("audio_cache", isDirectory: true)
    try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    // Use a stable filename derived from the URL path
    let name = remoteURL.path.replacingOccurrences(of: "/", with: "_")
    return cacheDir.appendingPathComponent(name)
  }

  private func downloadAndCache(url: URL, completion: @escaping (Error?) -> Void) {
    let localURL = localCacheURL(for: url)
    if FileManager.default.fileExists(atPath: localURL.path) {
      openLocalFile(url: localURL, originalURL: url, completion: completion)
      return
    }
    let task = URLSession.shared.downloadTask(with: url) { [weak self] tmpURL, _, error in
      guard let self = self else { return }
      if let error = error {
        DispatchQueue.main.async { completion(error) }
        return
      }
      guard let tmpURL = tmpURL else {
        DispatchQueue.main.async {
          completion(NSError(domain: "AQP", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "No downloaded file"]))
        }
        return
      }
      do {
        try FileManager.default.moveItem(at: tmpURL, to: localURL)
      } catch {
        // If move fails (e.g. already exists), try to use tmpURL directly
        self.openLocalFile(url: tmpURL, originalURL: url, completion: completion)
        return
      }
      self.openLocalFile(url: localURL, originalURL: url, completion: completion)
    }
    task.resume()
  }

  private func openLocalFile(url: URL, originalURL: URL, completion: @escaping (Error?) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let file = try AVAudioFile(forReading: url)
        DispatchQueue.main.async {
          self.files[originalURL] = file
          completion(nil)
        }
      } catch {
        DispatchQueue.main.async { completion(error) }
      }
    }
  }

  /// Set the clip queue. Call after all files are loaded.
  func loadClips(_ newClips: [Clip]) {
    playing = false
    stopInternal()
    clips = newClips
    currentIdx = 0
  }

  /// Start playing from currentIdx.
  func play() {
    guard !clips.isEmpty else { return }
    playing = true
    if !engine.isRunning {
      do { try engine.start() } catch {
        print("[AQP] engine start error: \(error)")
        return
      }
    }
    scheduleClip(at: currentIdx)
  }

  /// Pause playback.
  func pause() {
    playing = false
    pauseInternal()
  }

  /// Seek to clip index.
  func seekToClip(_ idx: Int) {
    guard idx >= 0 && idx < clips.count else { return }
    let wasPlaying = playing
    playerNode.stop()
    currentIdx = idx
    if wasPlaying { scheduleClip(at: idx) }
  }

  /// Position in seconds within the current clip.
  func currentPosition() -> Double {
    guard currentIdx < clips.count else { return 0 }
    let clip = clips[currentIdx]
    let elapsed = CACurrentMediaTime() - clipStartHostTime
    let pos = clip.startSec + elapsed * clip.speed
    return min(pos, clip.endSec)
  }

  func currentClipIndex() -> Int { currentIdx }

  func stop() {
    playing = false
    stopInternal()
    currentIdx = 0
  }

  // MARK: - Private

  private func pauseInternal() {
    playerNode.pause()
  }

  private func resumeInternal() {
    if !engine.isRunning {
      try? engine.start()
    }
    playerNode.play()
  }

  private func stopInternal() {
    playerNode.stop()
  }

  private func scheduleClip(at idx: Int) {
    guard idx < clips.count else {
      playing = false
      onFinished?()
      return
    }
    let clip = clips[idx]
    guard let file = files[clip.fileURL] else {
      print("[AQP] file not loaded: \(clip.fileURL)")
      return
    }

    let sampleRate = file.processingFormat.sampleRate
    let startFrame = AVAudioFramePosition(clip.startSec * sampleRate)
    let frameCount = AVAudioFrameCount((clip.endSec - clip.startSec) * sampleRate)

    currentIdx = idx
    clipStartHostTime = CACurrentMediaTime()

    // Apply per-clip speed via varispeed unit
    varispeed.rate = Float(clip.speed)

    playerNode.scheduleSegment(
      file,
      startingFrame: startFrame,
      frameCount: frameCount,
      at: nil,
      completionCallbackType: .dataPlayedBack
    ) { [weak self] _ in
      DispatchQueue.main.async {
        self?.onClipCompleted(idx: idx)
      }
    }

    if !playerNode.isPlaying {
      playerNode.play()
    }
  }

  private func onClipCompleted(idx: Int) {
    guard playing && idx == currentIdx else { return }
    let nextIdx = idx + 1
    if nextIdx >= clips.count {
      playing = false
      onFinished?()
    } else {
      onAdvance?(nextIdx)
      scheduleClip(at: nextIdx)
    }
  }
}
