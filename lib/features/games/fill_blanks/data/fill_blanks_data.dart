import '../domain/entities/fill_blanks_question.dart';

/// Cümle tamamlama oyunu için mock data
class FillBlanksData {
  static final List<FillBlanksQuestion> questions = [
    const FillBlanksQuestion(
      id: 1,
      question: 'Türkiye\'nin başkenti ____ dır.',
      answer: 'Ankara',
      options: ['İstanbul', 'Ankara', 'İzmir', 'Bursa'],
      category: 'Sosyal Bilgiler',
    ),
    const FillBlanksQuestion(
      id: 2,
      question: 'Suyun kimyasal formülü ____ dır.',
      answer: 'H2O',
      options: ['CO2', 'H2O', 'O2', 'NaCl'],
      category: 'Fen Bilimleri',
    ),
    const FillBlanksQuestion(
      id: 3,
      question: '5 + 7 = ____',
      answer: '12',
      options: ['10', '11', '12', '13'],
      category: 'Matematik',
    ),
    const FillBlanksQuestion(
      id: 4,
      question: 'İlk Türk devleti ____ dır.',
      answer: 'Hun Devleti',
      options: ['Selçuklu', 'Hun Devleti', 'Osmanlı', 'İlhanlı'],
      category: 'Tarih',
    ),
    const FillBlanksQuestion(
      id: 5,
      question: 'Dünyamızın uydusu ____ dır.',
      answer: 'Ay',
      options: ['Güneş', 'Mars', 'Ay', 'Venüs'],
      category: 'Fen Bilimleri',
    ),
    const FillBlanksQuestion(
      id: 6,
      question: 'En hızlı kara hayvanı ____ dır.',
      answer: 'Çita',
      options: ['Aslan', 'Çita', 'At', 'Kaplan'],
      category: 'Hayvanlar',
    ),
    const FillBlanksQuestion(
      id: 7,
      question: '12 x 8 = ____',
      answer: '96',
      options: ['86', '96', '106', '76'],
      category: 'Matematik',
    ),
    const FillBlanksQuestion(
      id: 8,
      question: 'Mustafa Kemal Atatürk ____ yılında doğdu.',
      answer: '1881',
      options: ['1880', '1881', '1882', '1883'],
      category: 'Tarih',
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
