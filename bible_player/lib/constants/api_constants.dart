/// Central place for asset / API URL configuration.
class ApiConstants {
  ApiConstants._();

  /// Base URL where audio MP3s are hosted.
  static const String audioBaseUrl =
      'https://audio.bblearn.uk/audio';

  /// Builds the audio URL for a given version, book and chapter.
  static String audioUrl(String version, String bookId, int chapter) =>
      '$audioBaseUrl/$version/$bookId/$chapter.mp3';
}
