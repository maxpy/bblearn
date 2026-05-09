import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/bible_book.dart';
import '../utils/constants.dart';

/// Screen that displays a grid of chapter buttons for a given Bible book.
class ChapterSelectScreen extends ConsumerWidget {
  /// The canonical book number (1-66).
  final int bookId;

  const ChapterSelectScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = BibleBook.byNumber(bookId);

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Book #$bookId not found',
                style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth >= 600 ? 5 : 4;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.nameZh,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              book.nameEn,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: book.chapters,
          itemBuilder: (context, index) {
            final chapter = index + 1;
            return _ChapterButton(
              chapter: chapter,
              onTap: () => context.go('/play/$bookId/$chapter'),
            );
          },
        ),
      ),
    );
  }
}

class _ChapterButton extends StatelessWidget {
  final int chapter;
  final VoidCallback onTap;

  const _ChapterButton({required this.chapter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            '$chapter',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
