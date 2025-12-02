import 'dart:convert';

import 'database_helper.dart';

/// Akıllı karne - Kullanıcı performans analizi servisi
class AnalysisService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Kullanıcının tüm sınav sonuçlarını analiz et
  Future<AnalysisResult> analyzeResults(String userId) async {
    final db = await _dbHelper.database;

    // Kullanıcının tüm sonuçlarını al
    final results = await db.query(
      'TrialResults',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) {
      return AnalysisResult(
        totalExams: 0,
        averageScore: 0,
        weakTopics: [],
        strongTopics: [],
        recommendation: null,
      );
    }

    // Toplam sınav sayısı ve ortalama puan
    final totalExams = results.length;
    final totalScore = results.fold<int>(
      0,
      (sum, result) => sum + (result['score'] as int? ?? 0),
    );
    final averageScore = totalScore / totalExams;

    // Yanlış cevapları topicId'ye göre grupla
    final topicErrors = <String, int>{};

    for (final result in results) {
      final rawAnswersJson = result['rawAnswers'] as String;
      final rawAnswers = json.decode(rawAnswersJson) as Map<String, dynamic>;
      final examId = result['examId'] as String;

      // Sınavın sorularını al
      final examResults = await db.query(
        'TrialExams',
        where: 'id = ?',
        whereArgs: [examId],
      );

      if (examResults.isNotEmpty) {
        final contentJson = examResults.first['contentJson'] as String;
        final questions = json.decode(contentJson) as List<dynamic>;

        // Her soruyu kontrol et
        for (var i = 0; i < questions.length; i++) {
          final question = questions[i] as Map<String, dynamic>;
          final questionId = (i + 1).toString();
          final userAnswer = rawAnswers[questionId] as String?;
          final correctAnswer = question['correctAnswer'] as String;
          final topicId = question['topicId'] as String;

          // Yanlış cevap veya boş bırakma
          if (userAnswer != correctAnswer) {
            topicErrors[topicId] = (topicErrors[topicId] ?? 0) + 1;
          }
        }
      }
    }

    // En çok hata yapılan konuları bul
    final sortedTopics = topicErrors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final weakTopics = <TopicAnalysis>[];
    final strongTopics = <TopicAnalysis>[];

    for (final entry in sortedTopics) {
      final topicId = entry.key;
      final errorCount = entry.value;

      // Konu bilgisini al
      final topicResults = await db.query(
        'Konular',
        where: 'konuID = ?',
        whereArgs: [topicId],
      );

      if (topicResults.isNotEmpty) {
        final topicName = topicResults.first['konuAdi'] as String;
        final analysis = TopicAnalysis(
          topicId: topicId,
          topicName: topicName,
          errorCount: errorCount,
        );

        if (errorCount >= 3) {
          weakTopics.add(analysis);
        } else if (errorCount <= 1) {
          strongTopics.add(analysis);
        }
      }
    }

    // En zayıf konu için öneri getir
    Recommendation? recommendation;
    if (weakTopics.isNotEmpty) {
      recommendation = await getRecommendation(weakTopics.first.topicId);
    }

    return AnalysisResult(
      totalExams: totalExams,
      averageScore: averageScore,
      weakTopics: weakTopics,
      strongTopics: strongTopics,
      recommendation: recommendation,
    );
  }

  /// En çok hata yapılan konuyu bul
  Future<String?> findWeakestTopic(String userId) async {
    final analysis = await analyzeResults(userId);
    if (analysis.weakTopics.isEmpty) return null;
    return analysis.weakTopics.first.topicId;
  }

  /// Konu için öneri getir (video veya test)
  Future<Recommendation?> getRecommendation(String topicId) async {
    final db = await _dbHelper.database;

    // Önce video önerisi dene
    final videos = await db.query(
      'Videolar',
      where: 'konuID = ?',
      whereArgs: [topicId],
      limit: 1,
    );

    if (videos.isNotEmpty) {
      final video = videos.first;
      return Recommendation(
        type: RecommendationType.video,
        title: video['videoBaslik'] as String,
        description: 'Bu videoyu izleyerek konuyu pekiştirebilirsin',
        resourceId: video['videoID'] as String,
        topicId: topicId,
      );
    }

    // Video yoksa test önerisi
    final tests = await db.query(
      'Testler',
      where: 'konuID = ?',
      whereArgs: [topicId],
      limit: 1,
    );

    if (tests.isNotEmpty) {
      final test = tests.first;
      return Recommendation(
        type: RecommendationType.test,
        title: test['testAdi'] as String,
        description: 'Bu testi çözerek pratik yapabilirsin',
        resourceId: test['testID'] as String,
        topicId: topicId,
      );
    }

    return null;
  }
}

/// Analiz sonucu modeli
class AnalysisResult {
  final int totalExams;
  final double averageScore;
  final List<TopicAnalysis> weakTopics;
  final List<TopicAnalysis> strongTopics;
  final Recommendation? recommendation;

  AnalysisResult({
    required this.totalExams,
    required this.averageScore,
    required this.weakTopics,
    required this.strongTopics,
    this.recommendation,
  });

  /// Genel performans mesajı
  String get performanceMessage {
    if (averageScore >= 80) {
      return 'Harika gidiyorsun! Ortalaman ${averageScore.toStringAsFixed(1)}';
    } else if (averageScore >= 60) {
      return 'İyi bir performans! Ortalaman ${averageScore.toStringAsFixed(1)}';
    } else {
      return 'Biraz daha çalışmalısın. Ortalaman ${averageScore.toStringAsFixed(1)}';
    }
  }
}

/// Konu analizi
class TopicAnalysis {
  final String topicId;
  final String topicName;
  final int errorCount;

  TopicAnalysis({
    required this.topicId,
    required this.topicName,
    required this.errorCount,
  });
}

/// Öneri tipi
enum RecommendationType { video, test }

/// Öneri modeli
class Recommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final String resourceId;
  final String topicId;

  Recommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.resourceId,
    required this.topicId,
  });

  String get typeLabel => type == RecommendationType.video ? 'Video' : 'Test';
}
