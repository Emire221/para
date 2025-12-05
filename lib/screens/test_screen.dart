import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../features/test/providers/test_provider.dart';
import '../features/test/models/test_state.dart';
import '../models/question_model.dart';
import 'result_screen.dart';

/// 🎮 Cyber Quiz Arena - Test Ekranı
/// Neon vurgulu, koyu modlu yarışma ekranı
class TestScreen extends ConsumerStatefulWidget {
  final String? topicId;
  final String? topicName;
  final Map<String, dynamic>? testData;

  const TestScreen({super.key, this.topicId, this.topicName, this.testData});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen>
    with TickerProviderStateMixin {
  // Seçilen cevap için animasyon
  int? _selectedOptionIndex;
  bool _isAnswering = false;

  // Animasyon controller'ları
  late AnimationController _pulseController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    // Pulse animasyonu (timer için)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Glow animasyonu
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Test başlat - MANTIK KORUNUYOR
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.testData != null) {
        final questions = widget.testData!['sorular'] as List<dynamic>? ?? [];
        final questionModels = questions
            .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
            .toList();
        ref
            .read(testControllerProvider.notifier)
            .initializeTest(questionModels);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(testControllerProvider);
    final controller = ref.read(testControllerProvider.notifier);

    // Test tamamlandığında result ekranına git - MANTIK KORUNUYOR
    ref.listen<bool>(isTestCompletedProvider, (previous, isCompleted) {
      if (isCompleted && mounted) {
        final currentState = ref.read(testControllerProvider);
        _navigateToResult(currentState);
      }
    });

    // Timer pulse kontrolü
    if (testState.timeLeft <= 10 && testState.timeLeft > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    // Loading durumu
    if (testState.status == TestStatus.loading || testState.questions.isEmpty) {
      return _buildLoadingScreen();
    }

    final currentQuestion = testState.currentQuestion;
    if (currentQuestion == null) {
      return _buildErrorScreen();
    }

    return PopScope(
      canPop: false, // Android geri tuşunu devre dışı bırak - MANTIK KORUNUYOR
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF000428), Color(0xFF001f54), Color(0xFF004e92)],
            ),
          ),
          child: Stack(
            children: [
              // Animasyonlu arka plan parçacıkları
              ..._buildBackgroundParticles(),

              // Ana içerik
              SafeArea(
                child: Column(
                  children: [
                    // HUD - Heads Up Display
                    _buildHUD(testState),

                    // Soru ve Cevaplar
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slideIn = Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation);

                          final slideOut = Tween<Offset>(
                            begin: const Offset(-1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation);

                          // Yeni widget için slideIn, eski için slideOut
                          return SlideTransition(
                            position:
                                animation.status == AnimationStatus.reverse
                                ? slideOut
                                : slideIn,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: _buildQuestionContent(
                          key: ValueKey(testState.currentQuestionIndex),
                          question: currentQuestion,
                          controller: controller,
                          questionIndex: testState.currentQuestionIndex,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Arka plan parçacıkları
  List<Widget> _buildBackgroundParticles() {
    return List.generate(15, (index) {
      final random = math.Random(index);
      final size = 4.0 + random.nextDouble() * 6;
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 800;
      final duration = 3000 + random.nextInt(4000);

      return Positioned(
            left: left,
            top: top,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyan.withValues(
                      alpha: 0.1 + (_glowController.value * 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withValues(
                          alpha: 0.3 * _glowController.value,
                        ),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          )
          .animate(
            onPlay: (c) => c.repeat(reverse: true),
            delay: Duration(milliseconds: index * 200),
          )
          .moveY(
            begin: 0,
            end: -30,
            duration: Duration(milliseconds: duration),
          );
    });
  }

  /// HUD - Heads Up Display
  Widget _buildHUD(TestState testState) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: _GlassContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Çıkış Butonu
              _buildExitButton(),

              const Spacer(),

              // Timer
              _buildTimer(testState.timeLeft),

              const Spacer(),

              // Soru Sayacı
              _buildQuestionCounter(
                testState.currentQuestionIndex + 1,
                testState.questions.length,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3, end: 0);
  }

  /// Çıkış butonu
  Widget _buildExitButton() {
    return GestureDetector(
      onTap: _showExitDialog,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: FaIcon(FontAwesomeIcons.xmark, color: Colors.red, size: 18),
        ),
      ),
    );
  }

  /// Timer widget'ı
  Widget _buildTimer(int timeLeft) {
    final totalTime = 60; // Toplam süre
    final percent = timeLeft / totalTime;
    final isLowTime = timeLeft <= 10;

    // Renk geçişi
    Color timerColor;
    if (percent > 0.5) {
      timerColor = Colors.greenAccent;
    } else if (percent > 0.25) {
      timerColor = Colors.amber;
    } else {
      timerColor = Colors.redAccent;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isLowTime ? 1.0 + (_pulseController.value * 0.1) : 1.0;

        return Transform.scale(
          scale: scale,
          child: CircularPercentIndicator(
            radius: 35,
            lineWidth: 6,
            percent: percent.clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.clock, color: timerColor, size: 14),
                const SizedBox(height: 2),
                Text(
                  '$timeLeft',
                  style: TextStyle(
                    color: timerColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            progressColor: timerColor,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            circularStrokeCap: CircularStrokeCap.round,
            animation: false,
          ),
        );
      },
    );
  }

  /// Soru sayacı
  Widget _buildQuestionCounter(int current, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withValues(alpha: 0.3),
            Colors.blue.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.listOl, color: Colors.cyan, size: 14),
          const SizedBox(width: 8),
          Text(
            '$current / $total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Soru içeriği
  Widget _buildQuestionContent({
    required Key key,
    required QuestionModel question,
    required dynamic controller,
    required int questionIndex,
  }) {
    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        children: [
          // Hologram Soru Kartı
          _HoloQuestionCard(
                questionText: question.soruMetni,
                questionNumber: questionIndex + 1,
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

          const SizedBox(height: 32),

          // Cevap Seçenekleri
          ...question.secenekler.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final label = String.fromCharCode(65 + index);

            return _GameOptionButton(
                  label: label,
                  optionText: option,
                  index: index,
                  isSelected: _selectedOptionIndex == index,
                  isDisabled: _isAnswering,
                  onTap: () => _handleAnswer(option, index, controller),
                )
                .animate(delay: Duration(milliseconds: 100 + (index * 100)))
                .fadeIn()
                .slideY(begin: 0.3, end: 0);
          }),
        ],
      ),
    );
  }

  /// Cevap seçme işlemi
  Future<void> _handleAnswer(
    String answer,
    int index,
    dynamic controller,
  ) async {
    if (_isAnswering) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _selectedOptionIndex = index;
      _isAnswering = true;
    });

    // Kısa bir gecikme ile cevabı gönder
    await Future.delayed(const Duration(milliseconds: 400));

    controller.answerQuestion(answer);

    // Bir sonraki soru için state'i sıfırla
    if (mounted) {
      setState(() {
        _selectedOptionIndex = null;
        _isAnswering = false;
      });
    }
  }

  /// Çıkış dialogu
  void _showExitDialog() {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Testten Çık',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Testi yarıda bırakmak istediğine emin misin?\n\nİlerlemeniz kaydedilmeyecek.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Devam Et',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Color(0xFFFF4444)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Çık',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Loading ekranı
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF000428), Color(0xFF004e92)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Neon loading indicator
              SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.cyan.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1500.ms, color: Colors.cyan),
              const SizedBox(height: 24),
              const Text(
                    'Arena Hazırlanıyor...',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn()
                  .then()
                  .fadeOut(duration: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }

  /// Hata ekranı
  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF000428), Color(0xFF004e92)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.circleExclamation,
                color: Colors.amber,
                size: 60,
              ),
              const SizedBox(height: 24),
              const Text(
                'Soru Bulunamadı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Geri Dön',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Result ekranına geç - MANTIK KORUNUYOR
  void _navigateToResult(TestState state) {
    final answeredQuestions = <Map<String, dynamic>>[];
    state.userAnswers.forEach((index, userAnswer) {
      if (index < state.questions.length) {
        answeredQuestions.add({
          'question': state.questions[index].toJson(),
          'userAnswer': userAnswer,
          'questionNumber': index + 1,
        });
      }
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          score: state.score,
          correctCount: state.correctCount,
          wrongCount: state.wrongCount,
          topicId: widget.topicId ?? '',
          topicName: widget.topicName ?? '',
          answeredQuestions: answeredQuestions,
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM WIDGETS
// ============================================================================

/// Glass Container - Cam efektli konteyner
class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Hologram Soru Kartı
class _HoloQuestionCard extends StatelessWidget {
  final String questionText;
  final int questionNumber;

  const _HoloQuestionCard({
    required this.questionText,
    required this.questionNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyan.withValues(alpha: 0.15),
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soru numarası badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.cyan, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  FontAwesomeIcons.question,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  'Soru $questionNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Soru metni
          Text(
            questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Game Option Button - Oyun tarzı seçenek butonu
class _GameOptionButton extends StatefulWidget {
  final String label;
  final String optionText;
  final int index;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _GameOptionButton({
    required this.label,
    required this.optionText,
    required this.index,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_GameOptionButton> createState() => _GameOptionButtonState();
}

class _GameOptionButtonState extends State<_GameOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Her şık için farklı renk
  static const List<List<Color>> _optionColors = [
    [Color(0xFF00D9FF), Color(0xFF00A8CC)], // A - Cyan
    [Color(0xFFFF6B6B), Color(0xFFEE5A5A)], // B - Red
    [Color(0xFF4ECDC4), Color(0xFF3CB4AC)], // C - Teal
    [Color(0xFFFFE66D), Color(0xFFF4D35E)], // D - Yellow
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _optionColors[widget.index % _optionColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) {
                setState(() => _isPressed = true);
                _controller.forward();
              },
        onTapUp: widget.isDisabled
            ? null
            : (_) {
                setState(() => _isPressed = false);
                _controller.reverse();
              },
        onTapCancel: widget.isDisabled
            ? null
            : () {
                setState(() => _isPressed = false);
                _controller.reverse();
              },
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: widget.isSelected
                        ? [
                            Colors.amber.withValues(alpha: 0.4),
                            Colors.orange.withValues(alpha: 0.3),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.04),
                          ],
                  ),
                  border: Border.all(
                    color: widget.isSelected
                        ? Colors.amber
                        : _isPressed
                        ? colors[0]
                        : Colors.white.withValues(alpha: 0.2),
                    width: widget.isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : _isPressed
                      ? [
                          BoxShadow(
                            color: colors[0].withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Label Circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.isSelected
                              ? [Colors.amber, Colors.orange]
                              : colors,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (widget.isSelected ? Colors.amber : colors[0])
                                    .withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Option Text
                    Expanded(
                      child: Text(
                        widget.optionText,
                        style: TextStyle(
                          color: widget.isSelected
                              ? Colors.amber
                              : Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: widget.isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Selected indicator
                    if (widget.isSelected)
                      Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.amber, Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0, 0),
                            end: const Offset(1, 1),
                          )
                          .fadeIn(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
