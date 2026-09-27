class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String category;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.category,
  });

  // Firestore'dan gelen ham veriyi (Map) Question nesnesine çevirir
  factory Question.fromMap(String id, Map<String, dynamic> map) {
    return Question(
      id: id,
      text: map['text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
      category: map['category'] ?? 'Genel',
    );
  }
}
