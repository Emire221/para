/// Arena düello sorusu modeli
class ArenaQuestion {
  final String question;
  final List<String> options;
  final String correct;
  final int difficulty;
  final String? category;

  const ArenaQuestion({
    required this.question,
    required this.options,
    required this.correct,
    required this.difficulty,
    this.category,
  });

  /// JSON'dan model oluşturma
  factory ArenaQuestion.fromJson(Map<String, dynamic> json) {
    return ArenaQuestion(
      question: json['question'] as String,
      options: List<String>.from(json['options']),
      correct: json['correct'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
      category: json['category'] as String?,
    );
  }

  /// Model'den JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correct': correct,
      'difficulty': difficulty,
      'category': category,
    };
  }

  /// Map formatına dönüştürme (ArenaScreen uyumluluğu için)
  Map<String, dynamic> toMap() {
    return {
      'questionText': question,
      'optionA': options.isNotEmpty ? options[0] : '',
      'optionB': options.length > 1 ? options[1] : '',
      'optionC': options.length > 2 ? options[2] : '',
      'optionD': options.length > 3 ? options[3] : '',
      'correctAnswer': correct,
    };
  }

  @override
  String toString() {
    return 'ArenaQuestion(question: $question, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArenaQuestion &&
        other.question == question &&
        other.correct == correct &&
        other.difficulty == difficulty;
  }

  @override
  int get hashCode {
    return question.hashCode ^ correct.hashCode ^ difficulty.hashCode;
  }
}
