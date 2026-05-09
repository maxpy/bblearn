import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/bible_book.dart';
import '../models/play_sequence.dart';
import '../providers/playback_provider.dart';
import '../services/audio_player_service.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final int bookNumber;
  final int chapter;

  const PlayerScreen({
    super.key,
    required this.bookNumber,
    required this.chapter,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late BibleBook _book;

  @override
  void initState() {
    super.initState();
    _book = BibleBook.allBooks[widget.bookNumber - 1];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bilingualPlayerProvider.notifier).loadChapter(
            book: _book,
            chapter: widget.chapter,
            autoPlay: false,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(bilingualPlayerProvider);
    final playbackAsync = ref.watch(playbackStateProvider);
    final sequence = ref.watch(currentSequenceProvider);

    final playback = playbackAsync.valueOrNull ?? const PlaybackState();

    // Use dynamic book/chapter from playerState (updates on auto-advance)
    final currentBook = BibleBook.allBooks.firstWhere(
      (b) => b.number == playerState.bookNumber,
      orElse: () => _book,
    );
    final currentChapter = playerState.chapter;

    return Scaffold(
      appBar: AppBar(
        title: Text('${currentBook.nameEn} $currentChapter  ${currentBook.nameZh}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/book/${currentBook.number}'),
        ),
        actions: [
          // Sequence selector
          PopupMenuButton<PlaySequence>(
            tooltip: '播放序列',
            initialValue: sequence,
            onSelected: (seq) {
              ref.read(currentSequenceProvider.notifier).setSequence(seq);
              ref.read(bilingualPlayerProvider.notifier).loadChapter(
                    book: currentBook,
                    chapter: currentChapter,
                    startVerse: playback.currentVerse,
                  );
            },
            itemBuilder: (_) => PresetSequences.all
                .map((s) => PopupMenuItem(value: s, child: Text(s.name)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Chip(label: Text(sequence.name)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (playerState.isLoading) const LinearProgressIndicator(),
          if (playerState.error != null)
            _ErrorBanner(message: playerState.error!),

          // Verse display
          Expanded(
            child: _BilingualVerseList(
              playerState: playerState,
              playback: playback,
              onVerseTap: (verse) {
                ref.read(audioPlayerServiceProvider).seekToVerse(verse);
              },
            ),
          ),

          // Controls
          _PlayerControls(playback: playback),
        ],
      ),
    );
  }
}

// ── Bilingual verse list ──────────────────────────────────────────────────────

class _BilingualVerseList extends StatefulWidget {
  final BilingualPlayerState playerState;
  final PlaybackState playback;
  final ValueChanged<int> onVerseTap;

  const _BilingualVerseList({
    required this.playerState,
    required this.playback,
    required this.onVerseTap,
  });

  @override
  State<_BilingualVerseList> createState() => _BilingualVerseListState();
}

class _BilingualVerseListState extends State<_BilingualVerseList> {
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  int _lastScrolledVerse = -1;

  @override
  void didUpdateWidget(_BilingualVerseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final verse = widget.playback.currentVerse;
    if (verse != _lastScrolledVerse && verse > 0) {
      _lastScrolledVerse = verse;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToVerse(verse));
    }
  }

  void _scrollToVerse(int verse) {
    final key = _verseKeys[verse];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        alignment: 0.25,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kjvData = widget.playerState.chapterData['KJV'];
    final cuvData = widget.playerState.chapterData['CUV'];

    if (kjvData == null && cuvData == null) {
      return const Center(child: Text('Loading verses...'));
    }

    // Use whichever version has data; prefer KJV for verse count
    final verseCount = (kjvData ?? cuvData)!.verseCount;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: verseCount,
      itemBuilder: (context, index) {
        final verseNum = index + 1;
        final key = _verseKeys.putIfAbsent(verseNum, () => GlobalKey());
        final isActive = widget.playback.currentVerse == verseNum;
        final isCurrentVersion = isActive;

        final kjvText = kjvData?.textForVerse(verseNum)?.text ?? '';
        final cuvText = cuvData?.textForVerse(verseNum)?.text ?? '';

        return _VerseTile(
          key: key,
          verseNumber: verseNum,
          kjvText: kjvText,
          cuvText: cuvText,
          isActive: isActive,
          activeVersion: isCurrentVersion ? widget.playback.currentVersion : null,
          onTap: () => widget.onVerseTap(verseNum),
        );
      },
    );
  }
}

class _VerseTile extends StatelessWidget {
  final int verseNumber;
  final String kjvText;
  final String cuvText;
  final bool isActive;
  final String? activeVersion;
  final VoidCallback onTap;

  const _VerseTile({
    super.key,
    required this.verseNumber,
    required this.kjvText,
    required this.cuvText,
    required this.isActive,
    required this.activeVersion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer.withValues(alpha: 0.45) : null,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: cs.primary, width: 1.5) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verse number
            SizedBox(
              width: 28,
              child: Text(
                '$verseNumber',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            // Text columns
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kjvText.isNotEmpty)
                    _VerseText(
                      text: kjvText,
                      isHighlighted: isActive && activeVersion == 'KJV',
                      theme: theme,
                    ),
                  if (kjvText.isNotEmpty && cuvText.isNotEmpty)
                    const SizedBox(height: 4),
                  if (cuvText.isNotEmpty)
                    _VerseText(
                      text: cuvText,
                      isHighlighted: isActive && activeVersion == 'CUV',
                      theme: theme,
                      isChinese: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseText extends StatelessWidget {
  final String text;
  final bool isHighlighted;
  final ThemeData theme;
  final bool isChinese;

  const _VerseText({
    required this.text,
    required this.isHighlighted,
    required this.theme,
    this.isChinese = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.55,
        fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.normal,
        color: isHighlighted ? theme.colorScheme.primary : null,
        fontSize: isChinese ? 15 : null,
      ),
    );
  }
}

// ── Player controls ───────────────────────────────────────────────────────────

class _PlayerControls extends ConsumerWidget {
  final PlaybackState playback;

  const _PlayerControls({required this.playback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(audioPlayerServiceProvider);
    final theme = Theme.of(context);
    final sequence = ref.watch(currentSequenceProvider);
    final stepSpeeds = ref.watch(stepSpeedsProvider);
    final playerState = ref.watch(bilingualPlayerProvider);

    final currentBook = BibleBook.allBooks.firstWhere(
      (b) => b.number == playerState.bookNumber,
      orElse: () => BibleBook.allBooks.first,
    );
    final hasPrevChapter =
        playerState.chapter > 1 || currentBook.number > 1;
    final hasNextChapter = playerState.chapter < currentBook.chapters ||
        currentBook.number < BibleBook.allBooks.last.number;

    void loadChapter(int delta) {
      int newChapter = playerState.chapter + delta;
      BibleBook newBook = currentBook;
      if (newChapter < 1) {
        final prevBookIdx =
            BibleBook.allBooks.indexWhere((b) => b.number == currentBook.number) - 1;
        if (prevBookIdx >= 0) {
          newBook = BibleBook.allBooks[prevBookIdx];
          newChapter = newBook.chapters;
        } else {
          return;
        }
      } else if (newChapter > currentBook.chapters) {
        final nextBookIdx =
            BibleBook.allBooks.indexWhere((b) => b.number == currentBook.number) + 1;
        if (nextBookIdx < BibleBook.allBooks.length) {
          newBook = BibleBook.allBooks[nextBookIdx];
          newChapter = 1;
        } else {
          return;
        }
      }
      ref
          .read(bilingualPlayerProvider.notifier)
          .loadChapter(book: newBook, chapter: newChapter);
    }

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Verse progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Text(
                    'v.${playback.currentVerse}',
                    style: theme.textTheme.labelSmall,
                  ),
                  const Spacer(),
                  Text(
                    playback.currentVersion,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Controls + speed in one row
            Row(
              children: [
                // Left speed controls (first half of steps)
                ...List.generate(
                  (sequence.steps.length / 2).ceil(),
                  (i) => _StepSpeedControl(
                    label: sequence.steps[i].version,
                    speed: stepSpeeds[sequence.steps[i].version] ?? 1.0,
                    onChanged: (newSpeed) {
                      ref.read(stepSpeedsProvider.notifier).setSpeed(sequence.steps[i].version, newSpeed);
                      ref.read(bilingualPlayerProvider.notifier).loadChapter(
                            book: currentBook,
                            chapter: playerState.chapter,
                            startVerse: playback.currentVerse,
                          );
                    },
                  ),
                ),
                // Center playback controls
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.first_page),
                        tooltip: '上一章',
                        onPressed: hasPrevChapter ? () => loadChapter(-1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        tooltip: '上一节',
                        onPressed: () => svc.previousVerse(),
                      ),
                      IconButton(
                        iconSize: 52,
                        icon: Icon(
                          playback.isLoading
                              ? Icons.hourglass_empty
                              : playback.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () => svc.togglePlayPause(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        tooltip: '下一节',
                        onPressed: () => svc.nextVerse(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.last_page),
                        tooltip: '下一章',
                        onPressed: hasNextChapter ? () => loadChapter(1) : null,
                      ),
                    ],
                  ),
                ),
                // Right speed controls (second half of steps)
                ...List.generate(
                  sequence.steps.length - (sequence.steps.length / 2).ceil(),
                  (j) {
                    final i = (sequence.steps.length / 2).ceil() + j;
                    return _StepSpeedControl(
                      label: sequence.steps[i].version,
                      speed: stepSpeeds[sequence.steps[i].version] ?? 1.0,
                      onChanged: (newSpeed) {
                        ref.read(stepSpeedsProvider.notifier).setSpeed(sequence.steps[i].version, newSpeed);
                        ref.read(bilingualPlayerProvider.notifier).loadChapter(
                              book: currentBook,
                              chapter: playerState.chapter,
                              startVerse: playback.currentVerse,
                            );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the speed option list:
/// 0.5–0.9 step 0.1, 1.0–1.9 step 0.1, 2.0–2.9 step 0.2, 3.0–4.0 step 0.3
List<double> _buildSpeedSteps() {
  final steps = <double>[];
  // 0.5 to 0.9
  for (int i = 5; i <= 9; i++) {
    steps.add(i / 10);
  }
  // 1.0 to 1.9
  for (int i = 10; i <= 19; i++) {
    steps.add(i / 10);
  }
  // 2.0 to 2.8 step 0.2
  for (int i = 20; i <= 28; i += 2) {
    steps.add(i / 10);
  }
  // 3.0 to 4.0 step 0.3
  for (int i = 30; i <= 40; i += 3) {
    steps.add(i / 10);
  }
  return steps;
}

final _speedSteps = _buildSpeedSteps();

class _StepSpeedControl extends StatefulWidget {
  final String label;
  final double speed;
  final ValueChanged<double> onChanged;

  const _StepSpeedControl({
    required this.label,
    required this.speed,
    required this.onChanged,
  });

  @override
  State<_StepSpeedControl> createState() => _StepSpeedControlState();
}

class _StepSpeedControlState extends State<_StepSpeedControl> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: _indexOfSpeed(widget.speed),
    );
  }

  @override
  void didUpdateWidget(_StepSpeedControl old) {
    super.didUpdateWidget(old);
    if (old.speed != widget.speed) {
      final idx = _indexOfSpeed(widget.speed);
      if (_controller.hasClients && _controller.selectedItem != idx) {
        _controller.jumpToItem(idx);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _indexOfSpeed(double s) {
    // Find closest index
    int best = 0;
    double bestDiff = (_speedSteps[0] - s).abs();
    for (int i = 1; i < _speedSteps.length; i++) {
      final d = (_speedSteps[i] - s).abs();
      if (d < bestDiff) {
        bestDiff = d;
        best = i;
      }
    }
    return best;
  }

  String _fmt(double v) {
    // Show one decimal for clean values, two for others
    final s = v.toStringAsFixed(1);
    return '${s}x';
  }

  void _showPicker(BuildContext context) {
    final theme = Theme.of(context);
    const itemExtent = 40.0;
    int selectedIdx = _indexOfSpeed(widget.speed);
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: 240,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(widget.label,
                        style: theme.textTheme.titleSmall),
                  ),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _controller,
                      itemExtent: itemExtent,
                      perspective: 0.003,
                      diameterRatio: 1.8,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (idx) {
                        setSheetState(() => selectedIdx = idx);
                        widget.onChanged(_speedSteps[idx]);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _speedSteps.length,
                        builder: (context, idx) {
                          final v = _speedSteps[idx];
                          final selected = selectedIdx == idx;
                          return Center(
                            child: Text(
                              _fmt(v),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 2),
            Text(
              _fmt(widget.speed),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.errorContainer,
      padding: const EdgeInsets.all(10),
      child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
    );
  }
}
