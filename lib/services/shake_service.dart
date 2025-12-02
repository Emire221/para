import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shake/shake.dart';
import '../services/database_helper.dart';
import 'dart:math';

/// Telefon sallama algılama ve rastgele içerik önerme servisi
class ShakeService {
  ShakeDetector? _shakeDetector;
  final BuildContext _context;
  final VoidCallback? onShake;
  DateTime? _lastShakeTime;
  static const _shakeCooldown = Duration(seconds: 3);

  ShakeService(this._context, {this.onShake});

  /// Shake dinlemeyi başlat
  void start() {
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        _handleShake();
      },
      minimumShakeCount: 2,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
    );
  }

  /// Shake olayını işle
  void _handleShake() {
    // Çok sık sallama engellemek için cooldown kontrolü
    final now = DateTime.now();
    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!) < _shakeCooldown) {
      return;
    }
    _lastShakeTime = now;

    // Titreşim feedback'i ver
    HapticFeedback.mediumImpact();

    // Custom callback varsa çağır
    if (onShake != null) {
      onShake!();
    }

    // Rastgele içerik öner
    _showRandomContentDialog();
  }

  /// Rastgele test veya konu seç ve dialog göster
  Future<void> _showRandomContentDialog() async {
    try {
      final db = await DatabaseHelper().database;

      // Rastgele test veya konu seçimi
      final random = Random();
      final isTest = random.nextBool();

      if (isTest) {
        // Rastgele test getir
        final tests = await db.query('Tests', limit: 100);
        if (tests.isEmpty) return;

        final randomTest = tests[random.nextInt(tests.length)];
        final testName = randomTest['testName'] as String;

        _showContentDialog(
          title: '🎲 Şansına Bu Çıktı!',
          content: '"$testName" testini çözmek ister misin?',
          actionLabel: 'Hadi Başlayalım!',
          onAction: () {
            // Test ekranına yönlendir (şimdilik sadece kapat)
            Navigator.of(_context).pop();
          },
        );
      } else {
        // Rastgele konu getir
        final topics = await db.query('Topics', limit: 100);
        if (topics.isEmpty) return;

        final randomTopic = topics[random.nextInt(topics.length)];
        final topicName = randomTopic['topicName'] as String;

        _showContentDialog(
          title: '🎲 Şansına Bu Çıktı!',
          content: '"$topicName" konusunu öğrenmek ister misin?',
          actionLabel: 'Videoya Geç!',
          onAction: () {
            // Konu ekranına yönlendir (şimdilik sadece kapat)
            Navigator.of(_context).pop();
          },
        );
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
      debugPrint('Shake service error: $e');
    }
  }

  /// İçerik önerisi dialogu göster
  void _showContentDialog({
    required String title,
    required String content,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.casino, color: Colors.purple, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(content, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Belki Sonra'),
          ),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  /// Shake dinlemeyi durdur
  void dispose() {
    _shakeDetector?.stopListening();
  }
}
