import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/duel_controller.dart';
import '../../domain/entities/duel_entities.dart';
import '../widgets/duel_score_header.dart';
import '../widgets/duel_test_question.dart';
import '../widgets/duel_fill_blank_question.dart';
import '../widgets/duel_result_dialog.dart';

/// Düello oyun ekranı
class DuelGameScreen extends ConsumerStatefulWidget {
  const DuelGameScreen({super.key});

  @override
  ConsumerState<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends ConsumerState<DuelGameScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duelControllerProvider);
    final controller = ref.read(duelControllerProvider.notifier);

    // Oyun bittiğinde sonuç dialogunu göster
    if (state.status == DuelStatus.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResultDialog(context, controller.getResult(), state);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation(context);
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade300,
                Colors.orange.shade600,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Skor header'ı
                DuelScoreHeader(
                  userScore: state.userScore,
                  botScore: state.botScore,
                  botProfile: state.botProfile,
                  currentQuestion: state.currentQuestionIndex + 1,
                  totalQuestions: state.gameType == DuelGameType.test
                      ? controller.testQuestions.length
                      : controller.fillBlankQuestions.length,
                ),
                
                // Soru alanı
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: state.gameType == DuelGameType.test
                        ? _buildTestQuestion(state, controller)
                        : _buildFillBlankQuestion(state, controller),
                  ),
                ),
                
                // Bot durumu göstergesi
                _buildBotStatus(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestQuestion(DuelState state, DuelController controller) {
    final question = controller.currentTestQuestion;
    if (question == null) {
      return const Center(child: Text('Soru bulunamadı'));
    }

    return DuelTestQuestion(
      question: question,
      userSelectedIndex: state.userSelectedIndex,
      botSelectedIndex: state.botSelectedIndex,
      isAnswered: state.userAnsweredCorrectly != null,
      onAnswerSelected: (index) {
        final isCorrect = index == question.correctIndex;
        controller.userAnswer(index, isCorrect);
      },
    );
  }

  Widget _buildFillBlankQuestion(DuelState state, DuelController controller) {
    final question = controller.currentFillBlankQuestion;
    if (question == null) {
      return const Center(child: Text('Soru bulunamadı'));
    }

    return DuelFillBlankQuestionWidget(
      question: question,
      userSelectedIndex: state.userSelectedIndex,
      botSelectedIndex: state.botSelectedIndex,
      isAnswered: state.userAnsweredCorrectly != null,
      onAnswerSelected: (index) {
        final isCorrect = question.options[index] == question.answer;
        controller.userAnswer(index, isCorrect);
      },
    );
  }

  Widget _buildBotStatus(DuelState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.isBotAnswering) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${state.botProfile?.name ?? "Rakip"} düşünüyor...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ] else if (state.botAnsweredCorrectly != null) ...[
            Icon(
              state.botAnsweredCorrectly! ? Icons.check_circle : Icons.cancel,
              color: state.botAnsweredCorrectly! ? Colors.greenAccent : Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '${state.botProfile?.name ?? "Rakip"} ${state.botAnsweredCorrectly! ? "doğru" : "yanlış"} cevapladı',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Düellodan Çık'),
        content: const Text('Düellodan çıkmak istediğine emin misin? Bu düello kaybedilmiş sayılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(duelControllerProvider.notifier).reset();
              Navigator.pop(context); // Dialog'u kapat
              Navigator.pop(context); // Ekrandan çık
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, DuelResult result, DuelState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DuelResultDialog(
        result: result,
        userScore: state.userScore,
        botScore: state.botScore,
        botName: state.botProfile?.name ?? 'Rakip',
        onPlayAgain: () {
          ref.read(duelControllerProvider.notifier).reset();
          Navigator.pop(context); // Dialog'u kapat
          Navigator.pop(context); // Oyun ekranından çık
        },
        onExit: () {
          ref.read(duelControllerProvider.notifier).reset();
          Navigator.pop(context); // Dialog'u kapat
          Navigator.pop(context); // Oyun ekranından çık
        },
      ),
    );
  }
}
