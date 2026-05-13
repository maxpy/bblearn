import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/bible_book.dart';
import '../widgets/chapter_selector.dart';

class BookScreen extends StatelessWidget {
  final int bookNumber;

  const BookScreen({super.key, required this.bookNumber});

  @override
  Widget build(BuildContext context) {
    final book = BibleBook.byNumber(bookNumber);

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Not Found')),
        body: const Center(child: Text('Book not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${book.nameEn}  ${book.nameZh}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a Chapter',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ChapterSelector(
                totalChapters: book.chapters,
                onChapterSelected: (chapter) {
                  context.go('/player/${book.number}/$chapter');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
