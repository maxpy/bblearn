import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home'));
  }
}

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Bookmarks'));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings'));
  }
}

class PlayerScreen extends StatelessWidget {
  final int bookId;
  final int chapter;
  const PlayerScreen({super.key, required this.bookId, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Player: book $bookId, chapter $chapter'));
  }
}

class SequenceEditorScreen extends StatelessWidget {
  const SequenceEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Sequence Editor'));
  }
}
