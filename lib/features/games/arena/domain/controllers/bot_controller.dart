import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Bot düello simülasyon controller'ı
class BotController {
  final int targetScore;
  final List<int> speedRange;
  final Random _random = Random();

  Timer? _timer;
  int _currentScore = 0;
  final void Function(int score)? onScoreUpdate;
  final VoidCallback? onWin;

  BotController({
    this.targetScore = 5,
    required this.speedRange,
    this.onScoreUpdate,
    this.onWin,
  });

  int get currentScore => _currentScore;

  /// Bot'u başlat
  void start() {
    _scheduleNextAnswer();
  }

  void _scheduleNextAnswer() {
    if (_currentScore >= targetScore) {
      onWin?.call();
      return;
    }

    // Rastgele süre sonra bot cevap verir
    final delay =
        _random.nextInt(speedRange[1] - speedRange[0]) + speedRange[0];

    _timer = Timer(Duration(milliseconds: delay), () {
      // %80 ihtimalle doğru cevap
      final isCorrect = _random.nextDouble() < 0.8;

      if (isCorrect) {
        _currentScore++;
        onScoreUpdate?.call(_currentScore);
      }

      _scheduleNextAnswer();
    });
  }

  /// Bot'u durdur
  void stop() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }
}
