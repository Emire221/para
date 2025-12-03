import '../domain/entities/fill_blanks_question.dart';

/// Cümle tamamlama oyunu için mock data
class FillBlanksData {
  static final List<FillBlanksQuestion> questions = [
    const FillBlanksQuestion(
      id: '1',
      question: '5 + 3 = ___',
      answer: '8',
      options: ['6', '7', '8', '9'],
      category: 'Matematik',
    ),
    const FillBlanksQuestion(
      id: '2',
      question: '12 - 4 = ___',
      answer: '8',
      options: ['7', '8', '9', '10'],
      category: 'Matematik',
    ),
    const FillBlanksQuestion(
      id: '3',
      question: 'Türkiye\'nin başkenti ___dir.',
      answer: 'Ankara',
      options: ['İstanbul', 'Ankara', 'İzmir', 'Bursa'],
      category: 'Sosyal Bilgiler',
    ),
    const FillBlanksQuestion(
      id: '4',
      question: 'Bir üçgenin ___ kenarı vardır.',
      answer: 'üç',
      options: ['iki', 'üç', 'dört', 'beş'],
      category: 'Geometri',
    ),
    const FillBlanksQuestion(
      id: '5',
      question: 'Güneş doğudan ___.',
      answer: 'doğar',
      options: ['batar', 'doğar', 'kaybolur', 'parlar'],
      category: 'Genel Kültür',
    ),
    const FillBlanksQuestion(
      id: '6',
      question: 'Su ___°C\'de kaynar.',
      answer: '100',
      options: ['0', '50', '100', '200'],
      category: 'Fen Bilgisi',
    ),
    const FillBlanksQuestion(
      id: '7',
      question: '3 x 4 = ___',
      answer: '12',
      options: ['10', '11', '12', '13'],
      category: 'Matematik',
    ),
    const FillBlanksQuestion(
      id: '8',
      question: 'Bir yılda ___ ay vardır.',
      answer: '12',
      options: ['10', '11', '12', '13'],
      category: 'Genel Kültür',
    ),
  ];

  /// Rastgele 5 soru getir
  static List<FillBlanksQuestion> getRandomQuestions({int count = 5}) {
    final shuffled = List<FillBlanksQuestion>.from(questions)..shuffle();
    return shuffled.take(count).toList();
  }

  /// Kategori bazlı sorular getir
  static List<FillBlanksQuestion> getQuestionsByCategory(String category) {
    return questions.where((q) => q.category == category).toList();
  }
}
