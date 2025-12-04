import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../../services/database_helper.dart';

/// Bul Bakalım Sonuç Ekranı
class MemoryResultScreen extends StatefulWidget {
  final int moves;
  final int mistakes;
  final int elapsedSeconds;
  final int score;
  final int starCount;

  const MemoryResultScreen({
    super.key,
    required this.moves,
    required this.mistakes,
    required this.elapsedSeconds,
    required this.score,
    required this.starCount,
  });

  @override
  State<MemoryResultScreen> createState() => _MemoryResultScreenState();
}

class _MemoryResultScreenState extends State<MemoryResultScreen>
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
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(parent: _scoreController, curve: Curves.easeOut));

    _starController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scoreController.forward();
      _starController.forward();

      if (widget.starCount >= 2) {
        _confettiController.play();
      }

      _saveResult();
    });
  }

  Future<void> _saveResult() async {
    try {
      await DatabaseHelper().saveGameResult(
        gameType: 'memory',
        score: widget.score,
        correctCount: 10, // 10 kart bulundu
        wrongCount: widget.mistakes,
        totalQuestions: 10,
        details:
            '{"moves": ${widget.moves}, "mistakes": ${widget.mistakes}, "seconds": ${widget.elapsedSeconds}}',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Bul Bakalım sonucu kaydedilemedi: $e');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreController.dispose();
    _starController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getResultMessage() {
    switch (widget.starCount) {
      case 3:
        return 'Mükemmel Hafıza! 🧠';
      case 2:
        return 'Harika! 🎉';
      case 1:
        return 'İyi deneme! 👍';
      default:
        return 'Tekrar dene! 💪';
    }
  }

  Color _getResultColor() {
    switch (widget.starCount) {
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
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan
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

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildResultBadge(),
                        const SizedBox(height: 24),
                        Text(
                          _getResultMessage(),
                          style: TextStyle(
                            color: _getResultColor(),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildStatsSection(),
                        const SizedBox(height: 32),
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

  Widget _buildResultBadge() {
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
                final isEarned = index < widget.starCount;
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.timer,
                color: Colors.blue,
                value: _formatTime(widget.elapsedSeconds),
                label: 'Süre',
              ),
              Container(width: 1, height: 50, color: Colors.grey.shade300),
              _buildStatItem(
                icon: Icons.touch_app,
                color: Colors.purple,
                value: '${widget.moves}',
                label: 'Hamle',
              ),
              Container(width: 1, height: 50, color: Colors.grey.shade300),
              _buildStatItem(
                icon: Icons.close,
                color: Colors.red,
                value: '${widget.mistakes}',
                label: 'Hata',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Performans mesajı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getResultColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology, color: _getResultColor()),
                const SizedBox(width: 8),
                Text(
                  widget.mistakes == 0
                      ? 'Hiç hata yapmadın!'
                      : widget.mistakes == 1
                      ? 'Sadece 1 hata!'
                      : '${widget.mistakes} hata yaptın',
                  style: TextStyle(
                    color: _getResultColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
            fontSize: 22,
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

  Widget _buildActionButtons() {
    return Column(
      children: [
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
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

