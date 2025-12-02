import 'dart:math';

/// Offline sıralama simülasyonu - Deterministik algoritma
/// Sunucuya bağlanmadan, yerel matematiksel formüllerle "Türkiye Geneli Sıralaması" üretir
class RankingSimulator {
  /// Sıralama simülasyonu yap
  ///
  /// [userScore]: Kullanıcının aldığı puan (0-100)
  /// [userId]: Kullanıcı ID'si (tutarlılık için)
  /// [examId]: Sınav ID'si (seed için)
  /// [difficultyCoefficient]: Sınav zorluk katsayısı (0.5 - 1.5 arası, varsayılan 1.0)
  RankingResult simulate({
    required int userScore,
    required String userId,
    required String examId,
    double difficultyCoefficient = 1.0,
  }) {
    // Seed: examId + userScore için deterministik random
    final seed = examId.hashCode + userScore;
    final random = Random(seed);

    // Katılımcı sayısı: Zorluk katsayısına göre değişken
    // Kolay sınavlarda daha fazla katılımcı
    final baseParticipants = 15000 + random.nextInt(35000); // 15k - 50k
    final totalParticipants = (baseParticipants * difficultyCoefficient)
        .round();

    // Sıralama hesaplama
    final ranking = _calculateRanking(
      userScore: userScore,
      totalParticipants: totalParticipants,
      random: random,
      difficultyCoefficient: difficultyCoefficient,
    );

    // Yüzdelik dilim
    final percentile = (ranking / totalParticipants) * 100;

    // Puan dağılımı (ortalama ve standart sapma)
    final averageScore = _calculateAverageScore(difficultyCoefficient, random);
    final standardDeviation = 15.0 + random.nextDouble() * 5; // 15-20 arası

    return RankingResult(
      ranking: ranking,
      totalParticipants: totalParticipants,
      percentile: percentile,
      averageScore: averageScore,
      standardDeviation: standardDeviation,
      userScore: userScore,
    );
  }

  /// Sıralama hesapla
  int _calculateRanking({
    required int userScore,
    required int totalParticipants,
    required Random random,
    required double difficultyCoefficient,
  }) {
    // Puan bazlı sıralama: Yüksek puan = düşük sıra
    // 100 puan = %1-5 arası
    // 90 puan = %5-15 arası
    // 80 puan = %15-30 arası
    // 70 puan = %30-50 arası
    // 60 puan = %50-70 arası
    // 50 ve altı = %70-95 arası

    double rankingPercentage;

    if (userScore >= 95) {
      rankingPercentage = 0.01 + random.nextDouble() * 0.04; // %1-5
    } else if (userScore >= 90) {
      rankingPercentage = 0.05 + random.nextDouble() * 0.10; // %5-15
    } else if (userScore >= 80) {
      rankingPercentage = 0.15 + random.nextDouble() * 0.15; // %15-30
    } else if (userScore >= 70) {
      rankingPercentage = 0.30 + random.nextDouble() * 0.20; // %30-50
    } else if (userScore >= 60) {
      rankingPercentage = 0.50 + random.nextDouble() * 0.20; // %50-70
    } else if (userScore >= 50) {
      rankingPercentage = 0.70 + random.nextDouble() * 0.20; // %70-90
    } else {
      rankingPercentage = 0.90 + random.nextDouble() * 0.05; // %90-95
    }

    // Zorluk katsayısı etkisi: Zor sınavlarda sıralama biraz daha iyi olabilir
    rankingPercentage *= (2.0 - difficultyCoefficient) * 0.5 + 0.5;

    final ranking = (totalParticipants * rankingPercentage).round();
    return ranking.clamp(1, totalParticipants);
  }

  /// Ortalama puan hesapla
  double _calculateAverageScore(double difficultyCoefficient, Random random) {
    // Zorluk katsayısına göre ortalama puan
    // Kolay sınav (0.5): Ortalama ~70
    // Normal sınav (1.0): Ortalama ~60
    // Zor sınav (1.5): Ortalama ~50

    final baseAverage = 75.0 - (difficultyCoefficient * 15);
    final variation = random.nextDouble() * 5 - 2.5; // -2.5 ile +2.5 arası

    return (baseAverage + variation).clamp(40.0, 80.0);
  }
}

/// Sıralama sonucu modeli
class RankingResult {
  final int ranking;
  final int totalParticipants;
  final double percentile;
  final double averageScore;
  final double standardDeviation;
  final int userScore;

  RankingResult({
    required this.ranking,
    required this.totalParticipants,
    required this.percentile,
    required this.averageScore,
    required this.standardDeviation,
    required this.userScore,
  });

  /// Kullanıcı dostu mesaj
  String get message {
    return '$totalParticipants kişi arasında $ranking. oldun';
  }

  /// Başarı seviyesi
  String get performanceLevel {
    if (percentile <= 10) return 'Mükemmel';
    if (percentile <= 25) return 'Çok İyi';
    if (percentile <= 50) return 'İyi';
    if (percentile <= 75) return 'Orta';
    return 'Geliştirilmeli';
  }

  /// Karşılaştırma mesajı
  String get comparisonMessage {
    final diff = userScore - averageScore;
    if (diff > 10) {
      return 'Ortalamanın ${diff.toStringAsFixed(1)} puan üstündesin!';
    } else if (diff > 0) {
      return 'Ortalamanın ${diff.toStringAsFixed(1)} puan üstündesin.';
    } else if (diff > -10) {
      return 'Ortalamaya ${diff.abs().toStringAsFixed(1)} puan yakınsın.';
    } else {
      return 'Ortalamanın ${diff.abs().toStringAsFixed(1)} puan altındasın.';
    }
  }
}
