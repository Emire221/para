import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:shake/shake.dart';
import '../controllers/guess_controller.dart';
import '../../domain/entities/temperature.dart';
import '../../domain/entities/guess_level.dart';
import '../widgets/thermometer_widget.dart';
import 'guess_result_screen.dart';

/// Salla Bakalım Oyun Ekranı
class GuessGameScreen extends ConsumerStatefulWidget {
  final GuessLevel? level;
  final int? difficulty;

  const GuessGameScreen({super.key, this.level, this.difficulty});

  @override
  ConsumerState<GuessGameScreen> createState() => _GuessGameScreenState();
}

class _GuessGameScreenState extends ConsumerState<GuessGameScreen>
    with TickerProviderStateMixin {
  final TextEditingController _guessController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late ConfettiController _confettiController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  ShakeDetector? _shakeDetector;

  @override
  void initState() {
    super.initState();

    // Konfeti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Shake animasyonu
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Shake detection başlat
    _initShakeDetector();

    // Oyunu başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(guessControllerProvider.notifier)
          .startGame(level: widget.level, difficulty: widget.difficulty);
    });
  }

  void _initShakeDetector() {
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        _onShakeDetected();
      },
      minimumShakeCount: 2,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 2000,
      shakeThresholdGravity: 2.5,
    );
  }

  void _onShakeDetected() {
    // Eğer text input boş değilse tahmin gönder
    final text = _guessController.text.trim();
    if (text.isEmpty) {
      // Boşsa sadece haptic feedback ver
      HapticFeedback.mediumImpact();
      return;
    }

    // Giriş değerini kontrol et ve gönder
    final guess = int.tryParse(text);
    if (guess != null) {
      HapticFeedback.heavyImpact();
      ref.read(guessControllerProvider.notifier).submitGuess(guess);
      _guessController.clear();
    }
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    _guessController.dispose();
    _focusNode.dispose();
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _submitGuess() {
    final text = _guessController.text.trim();
    if (text.isEmpty) return;

    final guess = int.tryParse(text);
    if (guess == null) return;

    ref.read(guessControllerProvider.notifier).submitGuess(guess);
    _guessController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guessControllerProvider);

    // Durum değişikliklerini dinle
    ref.listen<GuessState>(guessControllerProvider, (previous, next) {
      // Doğru cevap
      if (next.isCorrect && !(previous?.isCorrect ?? false)) {
        _confettiController.play();
        HapticFeedback.heavyImpact();
      }
      // Yanlış cevap - shake ve haptic
      else if (next.currentGuess != null &&
          !next.isCorrect &&
          previous?.currentGuess != next.currentGuess) {
        _shakeController.forward().then((_) => _shakeController.reset());
        _triggerHaptic(next.temperature);
      }
      // Oyun bitti
      if (next.isGameOver && !(previous?.isGameOver ?? false)) {
        _navigateToResult(next);
      }
    });

    if (state.isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: Temperature.cool.gradient),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: Temperature.cool.gradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Geri Dön'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animasyonlu arka plan
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(gradient: state.temperature.gradient),
            child: SafeArea(
              child: Column(
                children: [
                  // Üst bar
                  _buildTopBar(state),

                  // İçerik
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Soru alanı
                            _buildQuestionCard(state),

                            const SizedBox(height: 24),

                            // Orta alan: Maskot + Termometre
                            _buildMiddleSection(state),

                            const SizedBox(height: 24),

                            // Input alanı
                            if (!state.isCorrect) _buildInputSection(state),

                            // Doğru cevap bilgisi
                            if (state.isCorrect)
                              _buildCorrectAnswerSection(state),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
              numberOfParticles: 30,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(GuessState state) {
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

          // Soru sayacı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Soru ${state.currentQuestionIndex + 1}/${state.totalQuestions}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(),

          // Skor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${state.totalScore}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
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

  Widget _buildQuestionCard(GuessState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value *
                (state.isCorrect ? 0 : 1) *
                ((_shakeController.value * 10).toInt() % 2 == 0 ? 1 : -1),
            0,
          ),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              question.question,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.attempts > 2 && question.hint != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      question.hint!,
                      style: const TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleSection(GuessState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Feedback alanı
        Expanded(
          child: Column(
            children: [
              // Sıcaklık ikonu
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  state.temperature.icon,
                  key: ValueKey(state.temperature),
                  color: Colors.white,
                  size: 64,
                ),
              ),

              const SizedBox(height: 12),

              // Feedback mesajı
              if (state.feedbackMessage.isNotEmpty) ...[
                Text(
                  state.feedbackMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!state.isCorrect && state.currentGuess != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.temperature.directionHint(state.goUp),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ],

              // Deneme sayısı
              if (state.attempts > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${state.attempts} deneme',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Termometre
        ThermometerWidget(temperature: state.temperature, height: 180),
      ],
    );
  }

  Widget _buildInputSection(GuessState state) {
    return Column(
      children: [
        // Input alanı
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _guessController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tahminin?',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  onSubmitted: (_) => _submitGuess(),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: _submitGuess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.temperature.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tahmin Et',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Salla ipucu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.vibration, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'Telefonu sallayarak tahmin gönder!',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCorrectAnswerSection(GuessState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Doğru cevap
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Column(
            children: [
              const Text(
                '🎉 DOĞRU!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cevap: ${question.answer}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.attempts} denemede buldun!',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        // Bilgi kartı
        if (question.info != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Biliyor muydun?',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question.info!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Devam butonu
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ref.read(guessControllerProvider.notifier).nextQuestion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: state.temperature.color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              state.currentQuestionIndex + 1 >= state.totalQuestions
                  ? 'Sonuçları Gör'
                  : 'Sonraki Soru →',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _triggerHaptic(Temperature temperature) {
    switch (temperature) {
      case Temperature.freezing:
      case Temperature.cold:
        HapticFeedback.heavyImpact();
        break;
      case Temperature.cool:
      case Temperature.warm:
        HapticFeedback.mediumImpact();
        break;
      case Temperature.hot:
      case Temperature.boiling:
        HapticFeedback.lightImpact();
        break;
      case Temperature.correct:
        HapticFeedback.vibrate();
        break;
    }
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

  void _navigateToResult(GuessState state) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GuessResultScreen(
          level: state.level!,
          correctCount: state.correctCount,
          totalQuestions: state.totalQuestions,
          totalScore: state.totalScore,
        ),
      ),
    );
  }
}
