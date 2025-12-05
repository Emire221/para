/// Düello oyun türleri
enum DuelGameType {
  test,
  fillBlanks,
}

/// Düello durumları
enum DuelStatus {
  idle,
  searching,
  found,
  playing,
  finished,
}

/// Düello soru entity'si
class DuelQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? imageUrl;

  const DuelQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.imageUrl,
  });

  factory DuelQuestion.fromJson(Map<String, dynamic> json) {
    return DuelQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? json['soru'] ?? '',
      options: List<String>.from(json['options'] ?? json['secenekler'] ?? []),
      correctIndex: json['correctIndex'] ?? json['dogruCevap'] ?? 0,
      imageUrl: json['imageUrl'] ?? json['resim'],
    );
  }
}

/// Cümle tamamlama sorusu entity'si
class DuelFillBlankQuestion {
  final String id;
  final String sentence;
  final String answer;
  final List<String> options;

  const DuelFillBlankQuestion({
    required this.id,
    required this.sentence,
    required this.answer,
    required this.options,
  });

  factory DuelFillBlankQuestion.fromJson(Map<String, dynamic> json) {
    return DuelFillBlankQuestion(
      id: json['id'] ?? '',
      sentence: json['sentence'] ?? json['cumle'] ?? '',
      answer: json['answer'] ?? json['cevap'] ?? '',
      options: List<String>.from(json['options'] ?? json['secenekler'] ?? []),
    );
  }
}
