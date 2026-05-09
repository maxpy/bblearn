import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/bible_book.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Audio Player'),
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Old Testament 旧约'),
                Tab(text: 'New Testament 新约'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _BookGrid(books: BibleBook.oldTestament),
                  _BookGrid(books: BibleBook.newTestament),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  final List<BibleBook> books;

  const _BookGrid({required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _BookCard(
          book: book,
          onTap: () => context.go('/book/${book.number}'),
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final BibleBook book;
  final VoidCallback onTap;

  const _BookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOT = book.testament == Testament.ot;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                book.nameEn,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                book.nameZh,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isOT
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '${book.chapters} ch.',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
