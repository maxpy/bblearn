import 'package:flutter/material.dart';

class ChapterSelector extends StatelessWidget {
  final int totalChapters;
  final ValueChanged<int> onChapterSelected;

  const ChapterSelector({
    super.key,
    required this.totalChapters,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 70,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalChapters,
      itemBuilder: (context, index) {
        final chapter = index + 1;
        return Material(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => onChapterSelected(chapter),
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                '$chapter',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
