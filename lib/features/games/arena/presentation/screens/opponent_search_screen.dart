import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import '../../domain/entities/bot.dart';
import '../../domain/entities/arena_question.dart';
import '../../../../../services/database_helper.dart';
import '../../../../../widgets/glass_container.dart';
import 'arena_screen.dart';

/// Rakip arama ekranı - Matchmaking simülasyonu
class OpponentSearchScreen extends StatefulWidget {
  const OpponentSearchScreen({super.key});

  @override
  State<OpponentSearchScreen> createState() => _OpponentSearchScreenState();
}

class _OpponentSearchScreenState extends State<OpponentSearchScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late AnimationController _animationController;
  Bot? _selectedBot;
  List<ArenaQuestion>? _questions;
  bool _foundOpponent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startSearch();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startSearch() async {
    final random = Random();
    final randomDelay = 2 + random.nextInt(3); // 2-4 saniye

    try {
      // Veritabanından arena setlerini yükle
      final arenaSetsData = await _dbHelper.getArenaSets();

      if (arenaSetsData.isEmpty) {
        throw Exception('Arena soruları henüz yüklenmemiş');
      }

      // Rastgele bir set seç
      final selectedSet = arenaSetsData[random.nextInt(arenaSetsData.length)];

      // questions alanını parse et
      final questionsJson = json.decode(selectedSet['questions'] as String);
      final questions = (questionsJson as List)
          .map((q) => ArenaQuestion.fromJson(q as Map<String, dynamic>))
          .toList();

      // Belirlenen süre sonra rakip bul
      await Future.delayed(Duration(seconds: randomDelay));

      if (mounted) {
        setState(() {
          _selectedBot = Bot.bots[random.nextInt(Bot.bots.length)];
          _questions = questions;
          _foundOpponent = true;
        });

        _animationController.stop();

        // 1.5 saniye sonra arena'ya geç
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ArenaScreen(
                selectedBot: _selectedBot!,
                questions: _questions,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Rakip arama hatası: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Rakip bulunamadı.\n'
              'Lütfen önce veri senkronizasyonunu yapın.';
        });
        _animationController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Arena Düello')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage != null) ...[
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                    _animationController.repeat();
                    _startSearch();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Geri Dön'),
                ),
              ] else ...[
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _foundOpponent ? 'Rakip Bulundu!' : 'Rakip Aranıyor...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _foundOpponent
                            ? 'Arena\'ya yönlendiriliyorsun...'
                            : 'Eşit seviyede bir rakip bulunuyor...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Radar animasyonu
                _buildRadarAnimation(),
                const SizedBox(height: 48),
                // Bot bilgisi (bulunduysa)
                if (_foundOpponent && _selectedBot != null)
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedBot!.avatar,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedBot!.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(3, (index) {
                                return Icon(
                                  Icons.star,
                                  size: 16,
                                  color:
                                      index <
                                          (_selectedBot!.speedRange[1] / 1000)
                                              .round()
                                      ? Colors.amber
                                      : Colors.grey,
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarAnimation() {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: RadarPainter(
              progress: _animationController.value,
              foundOpponent: _foundOpponent,
            ),
            child: Center(
              child: Icon(
                _foundOpponent ? Icons.check_circle : Icons.search,
                size: 48,
                color: _foundOpponent ? Colors.green : Colors.blue,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Radar animasyon painter'ı
class RadarPainter extends CustomPainter {
  final double progress;
  final bool foundOpponent;

  RadarPainter({required this.progress, required this.foundOpponent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Arka plan daireler
    final circlePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), circlePaint);
    }

    if (!foundOpponent) {
      // Dönen tarama çizgisi
      final sweepPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.5),
            Colors.blue.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      final sweepAngle = progress * 2 * pi;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(sweepAngle);
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(0, 0), radius: radius),
        -pi / 4,
        pi / 2,
        true,
        sweepPaint,
      );
      canvas.restore();
    } else {
      // Rakip bulundu - yeşil parlama efekti
      final glowPaint = Paint()
        ..color = Colors.green.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius * 0.8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      foundOpponent != oldDelegate.foundOpponent;
}

