import '../models/chapter_data.dart';
import '../models/play_sequence.dart';

/// A single item in the play queue, representing either an audio segment
/// or a pause between segments.
class PlayQueueItem {
  /// Asset path to the audio file (empty for pause items).
  final String audioPath;

  /// Start time in seconds within the audio file.
  final double startTime;

  /// End time in seconds within the audio file.
  final double endTime;

  /// Playback speed multiplier.
  final double speed;

  /// The Bible version this item belongs to.
  final String version;

  /// The verse number this item corresponds to.
  final int verse;

  /// Whether this item is a pause rather than audio playback.
  final bool isPause;

  /// Duration of the pause in seconds (only relevant when [isPause] is true).
  final double pauseDuration;

  const PlayQueueItem({
    this.audioPath = '',
    this.startTime = 0.0,
    this.endTime = 0.0,
    this.speed = 1.0,
    this.version = '',
    this.verse = 0,
    this.isPause = false,
    this.pauseDuration = 0.0,
  });

  /// Creates a pause item with the given duration.
  const PlayQueueItem.pause({
    required this.pauseDuration,
    this.verse = 0,
  })  : audioPath = '',
        startTime = 0.0,
        endTime = 0.0,
        speed = 1.0,
        version = '',
        isPause = true;

  /// The effective duration of this item in seconds.
  double get duration =>
      isPause ? pauseDuration : (endTime - startTime) / speed;

  @override
  String toString() => isPause
      ? 'PlayQueueItem.pause(${pauseDuration}s, verse: $verse)'
      : 'PlayQueueItem(version: $version, verse: $verse, '
          '${startTime.toStringAsFixed(2)}-${endTime.toStringAsFixed(2)}s, '
          'speed: $speed)';
}

/// A queue of [PlayQueueItem]s that manages playback order and navigation.
class PlayQueue {
  /// The ordered list of items to play.
  final List<PlayQueueItem> items;

  /// The index of the currently active item.
  int currentIndex;

  PlayQueue({
    required this.items,
    this.currentIndex = 0,
  });

  /// Builds a [PlayQueue] from chapter data and a play sequence.
  ///
  /// For each verse in the range [startVerse]..[endVerse], iterates through
  /// each step in the [sequence], creating audio items from the matching
  /// version's timing data. Inserts pause items between steps and between verses.
  ///
  /// [chapterDataByVersion] maps version IDs to their loaded [ChapterData].
  /// [sequence] defines the playback steps and gap durations.
  /// [startVerse] defaults to 1 if not specified.
  /// [endVerse] defaults to the max verse count across all versions if not specified.
  static PlayQueue build({
    required Map<String, ChapterData> chapterDataByVersion,
    required PlaySequence sequence,
    Map<String, double>? stepSpeeds,
    int? startVerse,
    int? endVerse,
  }) {
    if (chapterDataByVersion.isEmpty || sequence.steps.isEmpty) {
      return PlayQueue(items: []);
    }

    // Determine verse range from available data
    final maxVerseCount = chapterDataByVersion.values
        .map((cd) => cd.verseCount)
        .reduce((a, b) => a > b ? a : b);

    final firstVerse = startVerse ?? 1;
    final lastVerse = endVerse ?? maxVerseCount;

    final items = <PlayQueueItem>[];

    for (int verse = firstVerse; verse <= lastVerse; verse++) {
      for (int stepIdx = 0; stepIdx < sequence.steps.length; stepIdx++) {
        final step = sequence.steps[stepIdx];
        final chapterData = chapterDataByVersion[step.version];

        if (chapterData == null) continue;

        final timing = chapterData.timingForVerse(verse);
        if (timing == null) continue;

        items.add(PlayQueueItem(
          audioPath: chapterData.audioPath,
          startTime: timing.start,
          endTime: timing.end,
          speed: step.speed * (stepSpeeds?[step.version] ?? 1.0),
          version: step.version,
          verse: verse,
          isPause: false,
          pauseDuration: 0.0,
        ));

        // Add gap between steps (but not after the last step for this verse)
        if (stepIdx < sequence.steps.length - 1 &&
            sequence.gapBetweenSteps > 0) {
          items.add(PlayQueueItem.pause(
            pauseDuration: sequence.gapBetweenSteps,
            verse: verse,
          ));
        }
      }

      // Add gap between verses (but not after the last verse)
      if (verse < lastVerse && sequence.gapBetweenVerses > 0) {
        items.add(PlayQueueItem.pause(
          pauseDuration: sequence.gapBetweenVerses,
          verse: verse,
        ));
      }
    }

    return PlayQueue(items: items);
  }

  /// The currently active item, or null if the queue is empty.
  PlayQueueItem? get current =>
      items.isNotEmpty && currentIndex >= 0 && currentIndex < items.length
          ? items[currentIndex]
          : null;

  /// Whether there is a next item in the queue.
  bool get hasNext => currentIndex < items.length - 1;

  /// Whether there is a previous item in the queue.
  bool get hasPrevious => currentIndex > 0;

  /// Advances to the next item and returns it, or null if at the end.
  PlayQueueItem? nextItem() {
    if (!hasNext) return null;
    currentIndex++;
    return current;
  }

  /// Advances to the first item of the next verse.
  ///
  /// Skips over remaining items (including pauses) for the current verse.
  /// Returns the first item of the next verse, or null if no next verse exists.
  PlayQueueItem? nextVerse() {
    if (items.isEmpty) return null;

    final currentVerse = current?.verse ?? 0;

    // Find the first item with a higher verse number
    for (int i = currentIndex + 1; i < items.length; i++) {
      if (!items[i].isPause && items[i].verse > currentVerse) {
        currentIndex = i;
        return current;
      }
    }

    return null;
  }

  /// Moves back to the first item of the previous verse.
  ///
  /// Returns the first item of the previous verse, or null if no previous verse exists.
  PlayQueueItem? previousVerse() {
    if (items.isEmpty) return null;

    final currentVerse = current?.verse ?? 0;
    final targetVerse = currentVerse - 1;

    if (targetVerse < 1) return null;

    // Find the first item matching the target verse
    for (int i = 0; i < items.length; i++) {
      if (!items[i].isPause && items[i].verse == targetVerse) {
        currentIndex = i;
        return current;
      }
    }

    return null;
  }

  /// Seeks to the first item of the specified verse number.
  ///
  /// Returns the item at the new position, or null if the verse is not found.
  PlayQueueItem? seekToVerse(int verse) {
    for (int i = 0; i < items.length; i++) {
      if (!items[i].isPause && items[i].verse == verse) {
        currentIndex = i;
        return current;
      }
    }
    return null;
  }

  /// Whether the queue is empty.
  bool get isEmpty => items.isEmpty;

  /// Whether the queue has items.
  bool get isNotEmpty => items.isNotEmpty;

  /// Total number of items in the queue.
  int get length => items.length;

  /// Returns all unique verse numbers in the queue.
  List<int> get verseNumbers {
    final verses = <int>{};
    for (final item in items) {
      if (!item.isPause && item.verse > 0) {
        verses.add(item.verse);
      }
    }
    return verses.toList()..sort();
  }

  @override
  String toString() =>
      'PlayQueue(items: ${items.length}, currentIndex: $currentIndex)';
}
