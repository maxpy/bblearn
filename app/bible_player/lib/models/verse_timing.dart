/// Timing data for a single verse within an audio recording.
class VerseTiming {
  /// The verse number within the chapter.
  final int verse;

  /// Start time in seconds within the audio file.
  final double start;

  /// End time in seconds within the audio file.
  final double end;

  /// The text content of the verse (from subtitle data).
  final String text;

  const VerseTiming({
    required this.verse,
    required this.start,
    required this.end,
    required this.text,
  });

  /// Duration of this verse's audio segment in seconds.
  double get duration => end - start;

  factory VerseTiming.fromJson(Map<String, dynamic> json) {
    return VerseTiming(
      verse: json['verse'] as int,
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'verse': verse,
        'start': start,
        'end': end,
        'text': text,
      };

  @override
  String toString() =>
      'VerseTiming(verse: $verse, start: $start, end: $end)';
}
