import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../services/database_helper.dart';
import '../domain/entities/duel_entities.dart';

/// Düello için veri sağlayan repository
class DuelRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Random _random = Random();

  /// Test sorularını çeker
  Future<List<DuelQuestion>> getTestQuestions({int count = 5}) async {
    try {
      final db = await _dbHelper.database;

      // Tüm testleri çek
      final tests = await db.query('Tests');

      if (tests.isEmpty) {
        if (kDebugMode) debugPrint('❌ Hiç test bulunamadı');
        return _getDefaultTestQuestions();
      }

      final List<DuelQuestion> allQuestions = [];

      // Her testten soruları çıkar
      for (final test in tests) {
        final questionsJson = test['sorular'] as String?;
        if (questionsJson != null && questionsJson.isNotEmpty) {
          try {
            final List<dynamic> questions = json.decode(questionsJson);
            for (int i = 0; i < questions.length; i++) {
              final q = questions[i];
              allQuestions.add(
                DuelQuestion(
                  id: '${test['testID']}_$i',
                  question: q['soru'] ?? '',
                  options: List<String>.from(q['secenekler'] ?? []),
                  correctIndex: q['dogruCevap'] ?? 0,
                  imageUrl: q['resim'],
                ),
              );
            }
          } catch (e) {
            if (kDebugMode) debugPrint('Soru parse hatası: $e');
          }
        }
      }

      if (allQuestions.isEmpty) {
        return _getDefaultTestQuestions();
      }

      // Rastgele karıştır ve istenilen kadar döndür
      allQuestions.shuffle(_random);
      return allQuestions.take(count).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Test soruları çekme hatası: $e');
      return _getDefaultTestQuestions();
    }
  }

  /// Cümle tamamlama sorularını çeker
  Future<List<DuelFillBlankQuestion>> getFillBlankQuestions({
    int count = 5,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Fill Blanks levellarını çek
      final levels = await db.query('FillBlanksLevels');

      if (levels.isEmpty) {
        if (kDebugMode) debugPrint('❌ Hiç fill blanks level bulunamadı');
        return _getDefaultFillBlankQuestions();
      }

      final List<DuelFillBlankQuestion> allQuestions = [];

      // Her level'dan soruları çıkar
      for (final level in levels) {
        final questionsJson = level['questions'] as String?;
        if (questionsJson != null && questionsJson.isNotEmpty) {
          try {
            final List<dynamic> questions = json.decode(questionsJson);
            for (int i = 0; i < questions.length; i++) {
              final q = questions[i];
              allQuestions.add(
                DuelFillBlankQuestion(
                  id: '${level['levelID']}_$i',
                  sentence: q['sentence'] ?? q['cumle'] ?? '',
                  answer: q['answer'] ?? q['cevap'] ?? '',
                  options: List<String>.from(
                    q['options'] ?? q['secenekler'] ?? [],
                  ),
                ),
              );
            }
          } catch (e) {
            if (kDebugMode) debugPrint('Soru parse hatası: $e');
          }
        }
      }

      if (allQuestions.isEmpty) {
        return _getDefaultFillBlankQuestions();
      }

      // Rastgele karıştır ve istenilen kadar döndür
      allQuestions.shuffle(_random);
      return allQuestions.take(count).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Fill blank soruları çekme hatası: $e');
      return _getDefaultFillBlankQuestions();
    }
  }

  /// Varsayılan test soruları (veri yoksa)
  List<DuelQuestion> _getDefaultTestQuestions() {
    return [
      const DuelQuestion(
        id: 'default_1',
        question: 'Türkiye\'nin başkenti neresidir?',
        options: ['İstanbul', 'Ankara', 'İzmir', 'Bursa'],
        correctIndex: 1,
      ),
      const DuelQuestion(
        id: 'default_2',
        question: '2 + 2 kaç eder?',
        options: ['3', '4', '5', '6'],
        correctIndex: 1,
      ),
      const DuelQuestion(
        id: 'default_3',
        question: 'Güneş sisteminde kaç gezegen vardır?',
        options: ['7', '8', '9', '10'],
        correctIndex: 1,
      ),
      const DuelQuestion(
        id: 'default_4',
        question: 'Su hangi elementlerden oluşur?',
        options: [
          'Karbon ve Oksijen',
          'Hidrojen ve Oksijen',
          'Azot ve Oksijen',
          'Helyum ve Hidrojen',
        ],
        correctIndex: 1,
      ),
      const DuelQuestion(
        id: 'default_5',
        question: 'Türkiye\'nin en uzun nehri hangisidir?',
        options: ['Fırat', 'Kızılırmak', 'Dicle', 'Sakarya'],
        correctIndex: 1,
      ),
    ];
  }

  /// Varsayılan cümle tamamlama soruları (veri yoksa)
  List<DuelFillBlankQuestion> _getDefaultFillBlankQuestions() {
    return [
      const DuelFillBlankQuestion(
        id: 'fb_default_1',
        sentence: 'Güneş ___ dan doğar.',
        answer: 'doğu',
        options: ['doğu', 'batı', 'kuzey', 'güney'],
      ),
      const DuelFillBlankQuestion(
        id: 'fb_default_2',
        sentence: 'Kuşlar ___ ile uçar.',
        answer: 'kanatları',
        options: ['kanatları', 'ayakları', 'gagaları', 'tüyleri'],
      ),
      const DuelFillBlankQuestion(
        id: 'fb_default_3',
        sentence: 'Yılda ___ mevsim vardır.',
        answer: 'dört',
        options: ['üç', 'dört', 'beş', 'altı'],
      ),
      const DuelFillBlankQuestion(
        id: 'fb_default_4',
        sentence: 'Kitap okumak ___ geliştirir.',
        answer: 'zekayı',
        options: ['kasları', 'zekayı', 'sesi', 'boyunu'],
      ),
      const DuelFillBlankQuestion(
        id: 'fb_default_5',
        sentence: 'Balıklar ___ de yaşar.',
        answer: 'su',
        options: ['hava', 'toprak', 'su', 'ateş'],
      ),
    ];
  }
}
