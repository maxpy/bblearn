import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/verse_text.dart';
import '../models/verse_timing.dart';
import '../providers/bible_providers.dart';
import '../services/audio_service.dart';
import '../services/bible_data_service.dart';

class ChapterScreen extends ConsumerStatefulWidget {
  const ChapterScreen({super.key});

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  final _audio = AudioService.instance;
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  int _activeVerse = -1;
  bool _audioAvailable = false;
  StreamSubscription<Duration>? _posSub;
  List<VerseTiming> _timings = [];

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final book = ref.read(selectedBookProvider);
    final chapter = ref.read(selectedChapterProvider);
    final version = ref.read(bibleVersionProvider);
    if (book == null) return;

    final assetPath = BibleDataService.instance.audioAssetPath(
      version: version,
      book: book,
      chapter: chapter,
    );

    final dur = await _audio.load(assetPath);
    if (mounted) {
      setState(() => _audioAvailable = dur != null);
    }

    // Listen to position to highlight the current verse.
    _posSub = _audio.positionStream.listen(_onPosition);
  }

  void _onPosition(Duration pos) {
    if (_timings.isEmpty) return;
    final sec = pos.inMilliseconds / 1000.0;
    int verse = -1;
    for (final t in _timings) {
      if (sec >= t.start && sec < t.end) {
        verse = t.verse;
        break;
      }
    }
    if (verse != _activeVerse) {
      setState(() => _activeVerse = verse);
      _scrollToVerse(verse);
    }
  }

  void _scrollToVerse(int verse) {
    final key = _verseKeys[verse];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        alignment: 0.3,
      );
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(selectedBookProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final versesAsync = ref.watch(verseTextProvider);
    final timingsAsync = ref.watch(verseTimingProvider);

    // Cache timings for position listener.
    timingsAsync.whenData((t) => _timings = t);

    final title = book != null ? '${book.name} $chapter' : 'Chapter';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (book != null && chapter > 1)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous chapter',
              onPressed: () => _changeChapter(chapter - 1),
            ),
          if (book != null && chapter < book.chapters)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next chapter',
              onPressed: () => _changeChapter(chapter + 1),
            ),
        ],
      ),
      body: Column(
        children: [
          // Verse list
          Expanded(
            child: versesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (verses) => _buildVerseList(verses),
            ),
          ),
          // Audio controls
          if (_audioAvailable) _buildAudioBar(),
        ],
      ),
    );
  }

  Widget _buildVerseList(List<VerseText> verses) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final v = verses[index];
        final key = _verseKeys.putIfAbsent(v.verse, () => GlobalKey());
        final isActive = v.verse == _activeVerse;
        return _VerseTile(
          key: key,
          verse: v,
          isActive: isActive,
          onTap: () => _seekToVerse(v.verse),
        );
      },
    );
  }

  void _seekToVerse(int verse) {
    final timing = _timings.where((t) => t.verse == verse).firstOrNull;
    if (timing != null) {
      _audio.seekToSeconds(timing.start);
      if (!_audio.isPlaying) _audio.play();
    }
  }

  void _changeChapter(int newChapter) {
    _audio.stop();
    ref.read(selectedChapterProvider.notifier).state = newChapter;
    setState(() {
      _activeVerse = -1;
      _audioAvailable = false;
      _verseKeys.clear();
    });
    _initAudio();
  }

  // ── Audio bar ─────────────────────────────────────────────────────────

  Widget _buildAudioBar() {
    return StreamBuilder<PlayerState>(
      stream: _audio.player.playerStateStream,
      builder: (context, snap) {
        final state = snap.data;
        final playing = state?.playing ?? false;
        final completed =
            state?.processingState == ProcessingState.completed;

        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seek bar
                StreamBuilder<Duration>(
                  stream: _audio.positionStream,
                  builder: (context, posSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    final dur = _audio.duration ?? Duration.zero;
                    return Slider(
                      min: 0,
                      max: dur.inMilliseconds.toDouble().clamp(1, double.infinity),
                      value: pos.inMilliseconds
                          .toDouble()
                          .clamp(0, dur.inMilliseconds.toDouble().clamp(1, double.infinity)),
                      onChanged: (v) {
                        _audio.seekTo(
                            Duration(milliseconds: v.round()));
                      },
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        final pos = _audio.position;
                        _audio.seekTo(pos - const Duration(seconds: 10));
                      },
                    ),
                    IconButton(
                      iconSize: 48,
                      icon: Icon(
                        completed
                            ? Icons.replay
                            : playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                      ),
                      onPressed: () {
                        if (completed) {
                          _audio.seekTo(Duration.zero);
                          _audio.play();
                        } else if (playing) {
                          _audio.pause();
                        } else {
                          _audio.play();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      onPressed: () {
                        final pos = _audio.position;
                        _audio.seekTo(pos + const Duration(seconds: 10));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Verse tile ───────────────────────────────────────────────────────────────

class _VerseTile extends StatelessWidget {
  final VerseText verse;
  final bool isActive;
  final VoidCallback onTap;

  const _VerseTile({
    super.key,
    required this.verse,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: isActive
            ? BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${verse.verse}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                verse.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontWeight: isActive ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
