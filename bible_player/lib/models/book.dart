import 'package:equatable/equatable.dart';

enum Testament { old, new_ }

class Book extends Equatable {
  final String id;
  final String name;
  final int chapters;
  final Testament testament;

  const Book({
    required this.id,
    required this.name,
    required this.chapters,
    required this.testament,
  });

  @override
  List<Object?> get props => [id, name, chapters, testament];

  @override
  String toString() => 'Book(id: $id, name: $name, chapters: $chapters)';
}
