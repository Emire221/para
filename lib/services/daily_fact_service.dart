import 'dart:convert';
import 'package:flutter/services.dart';

/// Günlük ilginç bilgiler için model sınıfı
class DailyFact {
  final int dayOfYear;
  final String title;
  final String fact;

  const DailyFact({
    required this.dayOfYear,
    required this.title,
    required this.fact,
  });

  factory DailyFact.fromMap(Map<String, dynamic> map) {
    return DailyFact(
      dayOfYear: map['dayOfYear'] as int,
      title: map['title'] as String,
      fact: map['fact'] as String,
    );
  }
}

/// Günlük ilginç bilgiler servisi
class DailyFactService {
  static List<DailyFact>? _cachedFacts;

  /// JSON'dan tüm faktleri yükle
  static Future<List<DailyFact>> _loadFacts() async {
    if (_cachedFacts != null) return _cachedFacts!;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/json/daily_facts.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedFacts = jsonList
          .map((json) => DailyFact.fromMap(json as Map<String, dynamic>))
          .toList();

      return _cachedFacts!;
    } catch (e) {
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  /// Bugünün ilginç bilgisini getir
  static Future<DailyFact?> getTodaysFact() async {
    final now = DateTime.now();
    final dayOfYear = _getDayOfYear(now);

    final facts = await _loadFacts();
    if (facts.isEmpty) return null;

    // dayOfYear'e göre bul, yoksa modulo ile döngüsel seç
    DailyFact? fact = facts.firstWhere(
      (f) => f.dayOfYear == dayOfYear,
      orElse: () {
        // Eğer bu gün için fact yoksa, modulo ile seç
        final index = (dayOfYear - 1) % facts.length;
        return facts[index];
      },
    );

    return fact;
  }

  /// Yılın kaçıncı günü olduğunu hesapla (1-365/366)
  static int _getDayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final difference = date.difference(startOfYear).inDays;
    return difference + 1;
  }

  /// Belirli bir gün için fact getir (test amaçlı)
  static Future<DailyFact?> getFactForDay(int dayOfYear) async {
    final facts = await _loadFacts();
    if (facts.isEmpty) return null;

    return facts.firstWhere(
      (f) => f.dayOfYear == dayOfYear,
      orElse: () {
        final index = (dayOfYear - 1) % facts.length;
        return facts[index];
      },
    );
  }
}
