import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/memory_game_controller.dart';
import '../../domain/entities/memory_game_state.dart';
import '../widgets/flip_card_widget.dart';
import 'memory_result_screen.dart';

/// Bul Bakalım Ana Oyun Ekranı
class MemoryGameScreen extends ConsumerStatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  ConsumerState<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends ConsumerState<MemoryGameScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoryGameProvider.notifier).startGame();
      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryGameProvider);

    // Oyun bittiğinde sonuç ekranına git
    ref.listen<MemoryGameState>(memoryGameProvider, (previous, next) {
      if (next.isCompleted && !(previous?.isCompleted ?? false)) {
        _timer?.cancel();
        HapticFeedback.heavyImpact();

        // Navigator'u async gap öncesi yakala
        final navigator = Navigator.of(context);
        final resultScreen = MemoryResultScreen(
          moves: next.moves,
          mistakes: next.mistakes,
          elapsedSeconds: next.elapsedSeconds,
          score: next.score,
          starCount: next.starCount,
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => resultScreen),
            );
          }
        });
      }

      // Yanlış cevapta haptic feedback
      if (next.isChecking && !(previous?.isChecking ?? false)) {
        HapticFeedback.mediumImpact();
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade900, Colors.purple.shade800],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(state),

              // Durum göstergesi
              _buildStatusIndicator(state),

              // Kart grid'i
              Expanded(child: _buildCardGrid(state)),

              // Alt bilgi
              _buildBottomInfo(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(MemoryGameState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Geri butonu
          IconButton(
            onPressed: () => _showExitDialog(),
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),

          const Spacer(),

          // Süre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Yeniden başlat
          IconButton(
            onPressed: () {
              ref.read(memoryGameProvider.notifier).restartGame();
              _startTimer();
            },
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(MemoryGameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Sıradaki sayı
          _buildStatBox(
            icon: Icons.looks_one,
            label: 'Sıradaki',
            value: state.nextExpectedNumber > 10
                ? '✓'
                : '${state.nextExpectedNumber}',
            color: Colors.green,
          ),

          // Hamle sayısı
          _buildStatBox(
            icon: Icons.touch_app,
            label: 'Hamle',
            value: '${state.moves}',
            color: Colors.blue,
          ),

          // Hata sayısı
          _buildStatBox(
            icon: Icons.close,
            label: 'Hata',
            value: '${state.mistakes}',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(MemoryGameState state) {
    if (state.cards.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: 10,
            itemBuilder: (context, index) {
              // 4x3 grid için padding (10 kart var, 2 boşluk)
              // İlk 4, sonra 4, sonra 2 (ortada)
              int cardIndex;
              if (index < 4) {
                cardIndex = index;
              } else if (index < 8) {
                cardIndex = index;
              } else {
                // Son satırda 2 kart ortada
                if (index == 8) {
                  cardIndex = 8;
                } else if (index == 9) {
                  cardIndex = 9;
                } else {
                  return const SizedBox();
                }
              }

              if (cardIndex >= state.cards.length) {
                return const SizedBox();
              }

              final card = state.cards[cardIndex];

              return FlipCardWidget(
                card: card,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(memoryGameProvider.notifier).flipCard(card.id);
                },
                disabled: state.isChecking || card.isMatched,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo(MemoryGameState state) {
    String message;
    Color messageColor;

    if (state.isChecking) {
      message = '❌ Yanlış! Kartlar kapanıyor...';
      messageColor = Colors.red.shade300;
    } else if (state.matchedCount > 0) {
      message = '✅ ${state.matchedCount}/10 kart bulundu';
      messageColor = Colors.green.shade300;
    } else {
      message = '🎯 1\'den başlayarak sırayla bul!';
      messageColor = Colors.white70;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: messageColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oyundan Çık'),
        content: const Text('Oyundan çıkmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Çık'),
          ),
        ],
      ),
    );
  }
}
