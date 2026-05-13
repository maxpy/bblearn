import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/timed_verse.dart';
import 'srt_parser.dart';

/// Service for fetching Bible audio and subtitle data.
class BibleDataService {
  final http.Client _client;
  final SrtParser _srtParser;

  BibleDataService({http.Client? client, SrtParser? srtParser})
      : _client = client ?? http.Client(),
        _srtParser = srtParser ?? const SrtParser();

  /// Get the audio URL for a specific book and chapter.
  String getAudioUrl(String bookId, int chapter, {String version = 'KJV'}) {
    return ApiConstants.audioUrl(version, bookId, chapter);
  }

  /// Fetch and parse SRT subtitles for a specific book and chapter.
  Future<List<TimedVerse>> fetchVerses(String bookId, int chapter,
      {String version = 'KJV'}) async {
    final url = ApiConstants.srtUrl(version, bookId, chapter);
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return _srtParser.parse(response.body);
    } else {
      throw Exception(
        'Failed to load subtitles for $bookId chapter $chapter '
        '(status: ${response.statusCode})',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
