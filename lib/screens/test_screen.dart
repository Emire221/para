import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/test/providers/test_provider.dart';
import '../features/test/models/test_state.dart';
import '../models/question_model.dart';
import '../widgets/common/question_card.dart';
import '../widgets/common/answer_option_button.dart';
import '../widgets/common/test_timer_display.dart';
import '../widgets/common/question_progress.dart';
import 'result_screen.dart';

/// Test Ekranı - Yeni Mimari ile Refactor Edilmiş
class TestScreen extends ConsumerStatefulWidget {
  final String? topicId;
  final String? topicName;
  final Map<String, dynamic>? testData;

  const TestScreen({super.key, this.topicId, this.topicName, this.testData});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  @override
  void initState() {
    super.initState();
    // Test başlat
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
  Widget build(BuildContext context) {
    final testState = ref.watch(testControllerProvider);
    final controller = ref.read(testControllerProvider.notifier);

    // Test tamamlandığında result ekranına git
    ref.listen<bool>(isTestCompletedProvider, (previous, isCompleted) {
      if (isCompleted && mounted) {
        _navigateToResult(testState);
      }
    });

    // Loading durumu
    if (testState.status == TestStatus.loading || testState.questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = testState.currentQuestion;
    if (currentQuestion == null) {
      return const Scaffold(body: Center(child: Text('Soru bulunamadı')));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000428), Color(0xFF004e92)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer
                    TestTimerDisplay(timeLeft: testState.timeLeft),
                    // Progress
                    QuestionProgress(
                      currentIndex: testState.currentQuestionIndex,
                      totalQuestions: testState.questions.length,
                    ),
                  ],
                ),
              ),

              // Question Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Soru Kartı
                      QuestionCard(questionText: currentQuestion.soruMetni),

                      const SizedBox(height: 32),

                      // Cevap Seçenekleri
                      ..._buildAnswerOptions(currentQuestion, controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cevap seçeneklerini oluştur
  List<Widget> _buildAnswerOptions(QuestionModel question, controller) {
    final options = question.secenekler;

    return options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      final label = String.fromCharCode(65 + index); // A, B, C, D

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: AnswerOptionButton(
          optionText: option,
          label: label,
          onTap: () => controller.answerQuestion(option),
        ),
      );
    }).toList();
  }

  /// Result ekranına geç
  void _navigateToResult(TestState state) {
    // Cevaplanmış soruları hazırla
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
