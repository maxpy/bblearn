import 'package:equatable/equatable.dart';

class Chapter extends Equatable {
  final String bookId;
  final int number;
  final String? audioUrl;
  final String? srtUrl;

  const Chapter({
    required this.bookId,
    required this.number,
    this.audioUrl,
    this.srtUrl,
  });

  @override
  List<Object?> get props => [bookId, number, audioUrl, srtUrl];

  @override
  String toString() => 'Chapter(bookId: $bookId, number: $number)';
}
