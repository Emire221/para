import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../domain/entities/guess_level.dart';
import '../../domain/entities/temperature.dart';
import '../../../../../services/database_helper.dart';

/// Salla Bakalım Sonuç Ekranı
class GuessResultScreen extends StatefulWidget {
  final GuessLevel level;
  final int correctCount;
  final int totalQuestions;
  final int totalScore;

  const GuessResultScreen({
    super.key,
    required this.level,
    required this.correctCount,
    required this.totalQuestions,
    required this.totalScore,
  });

  @override
  State<GuessResultScreen> createState() => _GuessResultScreenState();
}

class _GuessResultScreenState extends State<GuessResultScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;
  late AnimationController _starController;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.totalScore.toDouble(),
    ).animate(CurvedAnimation(parent: _scoreController, curve: Curves.easeOut));

    _starController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animasyonları başlat ve sonucu kaydet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scoreController.forward();
      _starController.forward();

      // Başarılıysa konfeti göster
      if (_getStarCount() >= 2) {
        _confettiController.play();
      }

      // Sonucu veritabanına kaydet
      _saveResult();
    });
  }

  Future<void> _saveResult() async {
    try {
      await DatabaseHelper().saveGuessResult(
        score: widget.totalScore,
        correctCount: widget.correctCount,
        totalQuestions: widget.totalQuestions,
        levelTitle: widget.level.title,
        difficulty: widget.level.difficulty,
        totalAttempts: 0, // Controller'dan gelmediği için şimdilik 0
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Salla Bakalım sonucu kaydedilemedi: $e');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreController.dispose();
    _starController.dispose();
    super.dispose();
  }

  int _getStarCount() {
    final percentage = widget.correctCount / widget.totalQuestions;
    if (percentage >= 1.0) return 3;
    if (percentage >= 0.7) return 2;
    if (percentage >= 0.4) return 1;
    return 0;
  }

  String _getResultMessage() {
    final starCount = _getStarCount();
    switch (starCount) {
      case 3:
        return 'Mükemmel! 🏆';
      case 2:
        return 'Harika! 🎉';
      case 1:
        return 'İyi deneme! 👍';
      default:
        return 'Daha çok çalışmalısın 📚';
    }
  }

  Color _getResultColor() {
    final starCount = _getStarCount();
    switch (starCount) {
      case 3:
        return Colors.amber;
      case 2:
        return Colors.green;
      case 1:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final starCount = _getStarCount();

    return Scaffold(
      body: Stack(
        children: [
          // Arka plan gradyanı
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getResultColor().withValues(alpha: 0.8),
                  _getResultColor().withValues(alpha: 0.4),
                  Colors.white,
                ],
              ),
            ),
          ),

          // İçerik
          SafeArea(
            child: Column(
              children: [
                // Üst bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Spacer(),
                      const Text(
                        'Sonuçlar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Ana içerik
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Başarı rozeti
                        _buildResultBadge(starCount),

                        const SizedBox(height: 24),

                        // Sonuç mesajı
                        Text(
                          _getResultMessage(),
                          style: TextStyle(
                            color: _getResultColor(),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // İstatistikler
                        _buildStatsSection(),

                        const SizedBox(height: 32),

                        // Seviye bilgisi
                        _buildLevelInfo(),

                        const SizedBox(height: 32),

                        // Butonlar
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Konfeti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
              numberOfParticles: 50,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBadge(int starCount) {
    return AnimatedBuilder(
      animation: _starController,
      builder: (context, child) {
        return Transform.scale(scale: _starController.value, child: child);
      },
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _getResultColor().withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Yıldızlar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isEarned = index < starCount;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    isEarned ? Icons.star : Icons.star_border,
                    color: isEarned ? Colors.amber : Colors.grey.shade300,
                    size: index == 1 ? 48 : 36,
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // Skor
            AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                return Text(
                  '${_scoreAnimation.value.toInt()}',
                  style: TextStyle(
                    color: _getResultColor(),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),

            Text(
              'puan',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.check_circle,
            color: Colors.green,
            value: '${widget.correctCount}',
            label: 'Doğru',
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          _buildStatItem(
            icon: Icons.cancel,
            color: Colors.red,
            value: '${widget.totalQuestions - widget.correctCount}',
            label: 'Yanlış',
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          _buildStatItem(
            icon: Icons.help_outline,
            color: Colors.blue,
            value: '${widget.totalQuestions}',
            label: 'Toplam',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLevelInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Temperature.warm.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.quiz, color: Temperature.warm.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.level.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.level.description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getDifficultyColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getDifficultyText(),
              style: TextStyle(
                color: _getDifficultyColor(),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyText() {
    switch (widget.level.difficulty) {
      case 1:
        return 'Kolay';
      case 2:
        return 'Orta';
      case 3:
        return 'Zor';
      default:
        return 'Orta';
    }
  }

  Color _getDifficultyColor() {
    switch (widget.level.difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Ana sayfa
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: const Text('Ana Sayfa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getResultColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tekrar oyna
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Oyunu yeniden başlat
            },
            icon: const Icon(Icons.replay),
            label: const Text('Tekrar Oyna'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _getResultColor(),
              side: BorderSide(color: _getResultColor()),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

