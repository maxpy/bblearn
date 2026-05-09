import 'package:equatable/equatable.dart';

/// Represents a single verse with start/end timestamps from an SRT file.
class TimedVerse extends Equatable {
  final int verseNumber;
  final String text;
  final Duration startTime;
  final Duration endTime;

  const TimedVerse({
    required this.verseNumber,
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  /// Whether this verse is currently active given the playback [position].
  bool isActiveAt(Duration position) {
    return position >= startTime && position < endTime;
  }

  @override
  List<Object?> get props => [verseNumber, text, startTime, endTime];

  @override
  String toString() =>
      'TimedVerse(v$verseNumber, ${startTime.inSeconds}s-${endTime.inSeconds}s)';
}
