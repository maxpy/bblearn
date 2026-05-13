/// A single verse's text content.
class VerseText {
  /// The verse number within the chapter.
  final int verse;

  /// The text content of the verse.
  final String text;

  const VerseText({
    required this.verse,
    required this.text,
  });

  factory VerseText.fromJson(Map<String, dynamic> json) {
    return VerseText(
      verse: json['verse'] as int,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'verse': verse,
        'text': text,
      };

  @override
  String toString() => 'VerseText(verse: $verse, text: $text)';
}
