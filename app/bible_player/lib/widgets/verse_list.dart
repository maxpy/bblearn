import 'package:flutter/material.dart';
import '../models/timed_verse.dart';

class VerseList extends StatefulWidget {
  final List<TimedVerse> verses;
  final TimedVerse? activeVerse;
  final ValueChanged<int> onVerseTap;

  const VerseList({
    super.key,
    required this.verses,
    required this.activeVerse,
    required this.onVerseTap,
  });

  @override
  State<VerseList> createState() => _VerseListState();
}

class _VerseListState extends State<VerseList> {
  final ScrollController _scrollController = ScrollController();
  int? _lastActiveVerse;

  @override
  void didUpdateWidget(VerseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to active verse when it changes.
    if (widget.activeVerse != null &&
        widget.activeVerse!.verseNumber != _lastActiveVerse) {
      _lastActiveVerse = widget.activeVerse!.verseNumber;
      _scrollToActiveVerse();
    }
  }

  void _scrollToActiveVerse() {
    if (widget.activeVerse == null) return;
    final index = widget.verses.indexWhere(
        (v) => v.verseNumber == widget.activeVerse!.verseNumber);
    if (index >= 0 && _scrollController.hasClients) {
      final offset = (index * 72.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
    final theme = Theme.of(context);

    if (widget.verses.isEmpty) {
      return const Center(
        child: Text('No verses loaded yet.'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.verses.length,
      itemBuilder: (context, index) {
        final verse = widget.verses[index];
        final isActive = widget.activeVerse?.verseNumber == verse.verseNumber;

        return GestureDetector(
          onTap: () => widget.onVerseTap(verse.verseNumber),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${verse.verseNumber}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    verse.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
