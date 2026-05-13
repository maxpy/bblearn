import 'package:equatable/equatable.dart';

class Chapter extends Equatable {
  final String bookId;
  final int number;
  final String? audioUrl;

  const Chapter({
    required this.bookId,
    required this.number,
    this.audioUrl,
  });

  @override
  List<Object?> get props => [bookId, number, audioUrl];

  @override
  String toString() => 'Chapter(bookId: $bookId, number: $number)';
}
