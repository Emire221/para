import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shake/shake.dart';
import '../services/database_helper.dart';
import '../features/games/fill_blanks/presentation/screens/level_selection_screen.dart';
import '../features/games/arena/presentation/screens/opponent_search_screen.dart';
import '../features/games/guess/presentation/screens/guess_game_screen.dart';
import '../features/games/memory/presentation/screens/memory_game_screen.dart';
import 'dart:math';

/// İçerik türleri
enum ContentType {
  test,
  flashcard,
  fillBlanks,
  arena,
  sallabakalim,
  bulbakalim,
}

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
      minimumShakeCount: 1, // Tek sallama yeterli
      shakeSlopTimeMS: 300, // Daha hızlı tepki
      shakeCountResetTime: 1500,
      shakeThresholdGravity: 1.8, // Daha hassas algılama
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

  /// Rastgele içerik seç ve dialog göster (Test, Bilgi Kartları veya Oyunlar)
  Future<void> _showRandomContentDialog() async {
    try {
      final db = await DatabaseHelper().database;
      final random = Random();

      // Tüm içerik türlerinden rastgele birini seç
      final contentTypes = ContentType.values;
      final selectedType = contentTypes[random.nextInt(contentTypes.length)];

      switch (selectedType) {
        case ContentType.test:
          await _showTestContent(db, random);
          break;
        case ContentType.flashcard:
          await _showFlashcardContent(db, random);
          break;
        case ContentType.fillBlanks:
          _showGameContent(
            title: '🧩 Cümle Tamamlama',
            description: 'Boşluğa doğru kelimeyi sürükle ve öğren!',
            icon: Icons.text_fields,
            color: Colors.purple,
            onAction: () {
              Navigator.of(_context).pop();
              Navigator.push(
                _context,
                MaterialPageRoute(
                  builder: (context) => const LevelSelectionScreen(),
                ),
              );
            },
          );
          break;
        case ContentType.arena:
          _showGameContent(
            title: '⚔️ Arena Düello',
            description: 'Botlarla yarış ve şampiyon ol!',
            icon: Icons.sports_esports,
            color: Colors.blue,
            onAction: () {
              Navigator.of(_context).pop();
              Navigator.push(
                _context,
                MaterialPageRoute(
                  builder: (context) => const OpponentSearchScreen(),
                ),
              );
            },
          );
          break;
        case ContentType.sallabakalim:
          _showGameContent(
            title: '📳 Salla Bakalım',
            description: 'Telefonu salla ve sayıyı tahmin et!',
            icon: Icons.vibration,
            color: Colors.teal,
            onAction: () {
              Navigator.of(_context).pop();
              Navigator.push(
                _context,
                MaterialPageRoute(
                  builder: (context) => const GuessGameScreen(),
                ),
              );
            },
          );
          break;
        case ContentType.bulbakalim:
          _showGameContent(
            title: '🔢 Bul Bakalım',
            description: '1\'den 10\'a kadar sırayla bul!',
            icon: Icons.grid_view_rounded,
            color: Colors.indigo,
            onAction: () {
              Navigator.of(_context).pop();
              Navigator.push(
                _context,
                MaterialPageRoute(
                  builder: (context) => const MemoryGameScreen(),
                ),
              );
            },
          );
          break;
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
      debugPrint('Shake service error: $e');
    }
  }

  /// Test içeriği göster
  Future<void> _showTestContent(dynamic db, Random random) async {
    final tests = await db.query('Tests', limit: 100);
    if (tests.isEmpty) {
      // Test yoksa oyun öner
      _showGameContent(
        title: '🎮 Salla Bakalım',
        description: 'Telefonu salla ve sayıyı tahmin et!',
        icon: Icons.vibration,
        color: Colors.teal,
        onAction: () {
          Navigator.of(_context).pop();
          Navigator.push(
            _context,
            MaterialPageRoute(builder: (context) => const GuessGameScreen()),
          );
        },
      );
      return;
    }

    final randomTest = tests[random.nextInt(tests.length)];
    final testName = randomTest['testName'] as String;

    _showContentDialog(
      title: '📝 Şansına Bu Çıktı!',
      content: '"$testName" testini çözmek ister misin?',
      actionLabel: 'Hadi Başlayalım!',
      icon: Icons.quiz,
      color: Colors.orange,
      onAction: () {
        Navigator.of(_context).pop();
      },
    );
  }

  /// Bilgi kartı içeriği göster
  Future<void> _showFlashcardContent(dynamic db, Random random) async {
    final flashcards = await db.query('Flashcards', limit: 100);
    if (flashcards.isEmpty) {
      // Kart yoksa oyun öner
      _showGameContent(
        title: '🔢 Bul Bakalım',
        description: '1\'den 10\'a kadar sırayla bul!',
        icon: Icons.grid_view_rounded,
        color: Colors.indigo,
        onAction: () {
          Navigator.of(_context).pop();
          Navigator.push(
            _context,
            MaterialPageRoute(builder: (context) => const MemoryGameScreen()),
          );
        },
      );
      return;
    }

    final randomCard = flashcards[random.nextInt(flashcards.length)];
    final front = randomCard['front'] as String? ?? 'Bilgi Kartı';

    _showContentDialog(
      title: '🃏 Bilgi Kartı!',
      content: '"$front" kartını öğrenmek ister misin?',
      actionLabel: 'Kartı Gör!',
      icon: Icons.style,
      color: Colors.green,
      onAction: () {
        Navigator.of(_context).pop();
      },
    );
  }

  /// Oyun içeriği göster
  void _showGameContent({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onAction,
  }) {
    _showContentDialog(
      title: title,
      content: description,
      actionLabel: 'Oyna!',
      icon: icon,
      color: color,
      onAction: onAction,
    );
  }

  /// İçerik önerisi dialogu göster
  void _showContentDialog({
    required String title,
    required String content,
    required String actionLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onAction,
  }) {
    showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_android, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Telefonu salladın! 📱',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Belki Sonra',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
