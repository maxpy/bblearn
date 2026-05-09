class AppConstants {
  AppConstants._();

  static const String appTitle = 'Bible Audio Player';
  static const String baseAudioUrl = 'https://audio.bible.org';
  static const String baseSrtUrl = 'https://srt.bible.org';
  static const Duration seekStepDuration = Duration(seconds: 10);
  static const double minPlaybackSpeed = 0.5;
  static const double maxPlaybackSpeed = 2.0;
  static const double playbackSpeedStep = 0.25;
}
