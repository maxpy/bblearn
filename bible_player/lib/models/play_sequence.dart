/// Defines a step in a play sequence.
class PlayStep {
  /// The Bible version to use for this step (e.g. 'KJV', 'CUV').
  final String version;

  /// Playback speed multiplier (1.0 = normal speed).
  final double speed;

  const PlayStep({required this.version, this.speed = 1.0});

  @override
  String toString() => 'PlayStep(version: $version, speed: $speed)';
}

/// A complete play sequence configuration.
class PlaySequence {
  /// Display name for this sequence.
  final String name;

  /// Ordered list of steps to execute for each verse.
  final List<PlayStep> steps;

  /// Pause duration in seconds between steps within the same verse.
  final double gapBetweenSteps;

  /// Pause duration in seconds between verses.
  final double gapBetweenVerses;

  const PlaySequence({
    required this.name,
    required this.steps,
    this.gapBetweenSteps = 0.5,
    this.gapBetweenVerses = 1.0,
  });

  @override
  String toString() => 'PlaySequence($name, ${steps.length} steps)';
}

/// Preset play sequences.
class PresetSequences {
  PresetSequences._();

  static const en = PlaySequence(
    name: 'EN',
    steps: [PlayStep(version: 'KJV')],
  );

  static const cn = PlaySequence(
    name: 'CN',
    steps: [PlayStep(version: 'CUV')],
  );

  static const enCn = PlaySequence(
    name: 'EN→CN',
    steps: [PlayStep(version: 'KJV'), PlayStep(version: 'CUV')],
  );

  static const cnEn = PlaySequence(
    name: 'CN→EN',
    steps: [PlayStep(version: 'CUV'), PlayStep(version: 'KJV')],
  );

  static const enCnEn = PlaySequence(
    name: 'EN→CN→EN',
    steps: [
      PlayStep(version: 'KJV'),
      PlayStep(version: 'CUV', speed: 0.8),
      PlayStep(version: 'KJV', speed: 1.2),
    ],
  );

  static const cnEnCn = PlaySequence(
    name: 'CN→EN→CN',
    steps: [
      PlayStep(version: 'CUV'),
      PlayStep(version: 'KJV'),
      PlayStep(version: 'CUV', speed: 0.8),
    ],
  );

  static const List<PlaySequence> all = [en, cn, enCn, cnEn, enCnEn, cnEnCn];

  static PlaySequence? byName(String? name) {
    if (name == null) return null;
    try {
      return all.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }
}
