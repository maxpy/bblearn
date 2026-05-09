/// Data model for user bookmarks.
///
/// Bookmarks allow users to save and annotate specific Bible verses.
library;

/// An immutable bookmark pointing to a specific Bible verse.
class Bookmark {
  /// Unique identifier for this bookmark.
  final String id;

  /// The canonical book number (1-66).
  final int bookNumber;

  /// The chapter number within the book.
  final int chapter;

  /// The verse number within the chapter.
  final int verse;

  /// User-provided note or annotation.
  final String note;

  /// When this bookmark was created.
  final DateTime createdAt;

  /// Creates a [Bookmark] instance.
  const Bookmark({
    required this.id,
    required this.bookNumber,
    required this.chapter,
    required this.verse,
    this.note = '',
    required this.createdAt,
  });

  /// Creates a copy of this bookmark with the given fields replaced.
  Bookmark copyWith({
    String? id,
    int? bookNumber,
    int? chapter,
    int? verse,
    String? note,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookNumber: bookNumber ?? this.bookNumber,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serializes this bookmark to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'bookNumber': bookNumber,
        'chapter': chapter,
        'verse': verse,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserializes a bookmark from a JSON-compatible map.
  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        bookNumber: json['bookNumber'] as int,
        chapter: json['chapter'] as int,
        verse: json['verse'] as int,
        note: json['note'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  String toString() =>
      'Bookmark($id: book $bookNumber, ch $chapter:$verse)';
}
