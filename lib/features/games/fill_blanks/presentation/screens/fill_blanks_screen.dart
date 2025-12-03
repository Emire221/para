import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/fill_blanks_level.dart';
import '../../domain/entities/fill_blanks_question.dart';
import '../../../../../../services/database_helper.dart';
import '../../../../mascot/presentation/providers/mascot_provider.dart';

/// Cümle tamamlama oyunu ekranı
class FillBlanksScreen extends ConsumerStatefulWidget {
  final FillBlanksLevel level;

  const FillBlanksScreen({super.key, required this.level});

  @override
  ConsumerState<FillBlanksScreen> createState() => _FillBlanksScreenState();
}

class _FillBlanksScreenState extends ConsumerState<FillBlanksScreen> {
  late List<FillBlanksQuestion> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _showFeedback = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _questions = widget.level.questions;
  }

  void _onAnswerDropped(String answer) {
    setState(() {
      _selectedAnswer = answer;
      _isCorrect = answer == _questions[_currentQuestionIndex].answer;
      _showFeedback = true;

      if (_isCorrect) {
        _score++;
      }
    });

    // 1.5 saniye sonra sonraki soruya geç
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswer = null;
          _showFeedback = false;
        });
      } else {
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() {
    // Sonuçları kaydet
    _saveResults();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Oyun Bitti!'),
        content: Text(
          'Skorun: $_score / ${_questions.length}\n'
          'Doğru Cevap Oranı: ${((_score / _questions.length) * 100).toStringAsFixed(1)}%',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _questions = widget.level.questions;
                _currentQuestionIndex = 0;
                _score = 0;
                _selectedAnswer = null;
                _showFeedback = false;
              });
            },
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.level.title),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Skor: $_score / ${_questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Soru ${_currentQuestionIndex + 1} / ${_questions.length}',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            currentQuestion.question.replaceAll('____', ''),
                            style: const TextStyle(fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          DragTarget<String>(
                            onAcceptWithDetails: (data) =>
                                _onAnswerDropped(data.data),
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                width: 200,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _showFeedback
                                      ? (_isCorrect
                                            ? Colors.green.withValues(
                                                alpha: 0.3,
                                              )
                                            : Colors.red.withValues(alpha: 0.3))
                                      : Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _showFeedback
                                        ? (_isCorrect
                                              ? Colors.green
                                              : Colors.red)
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _selectedAnswer ?? '____',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedAnswer != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (!_showFeedback)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: currentQuestion.options.map((option) {
                          return Draggable<String>(
                            data: option,
                            feedback: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildOptionChip(option),
                            ),
                            child: _buildOptionChip(option),
                          );
                        }).toList(),
                      ),
                    if (_showFeedback)
                      Icon(
                        _isCorrect ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect ? Colors.green : Colors.red,
                        size: 80,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(String option) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Text(
        option,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  Future<void> _saveResults() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.saveGameResult(
        gameType: 'fill_blanks',
        score: _score * 10, // Her doğru 10 puan
        correctCount: _score,
        wrongCount: _questions.length - _score,
        totalQuestions: _questions.length,
        details: widget.level.title,
      );

      // Maskota XP ekle
      await _addXpToMascot();
    } catch (e) {
      debugPrint('Sonuç kaydetme hatası: $e');
    }
  }

  /// Maskota XP ekle - Her oyun bitiminde 1 XP
  Future<void> _addXpToMascot() async {
    try {
      final mascotRepository = ref.read(mascotRepositoryProvider);
      await mascotRepository.addXp(1);
      ref.invalidate(activeMascotProvider);
      debugPrint('Fill Blanks oyunu - Maskota 1 XP eklendi');
    } catch (e) {
      debugPrint('Maskot XP ekleme hatası: $e');
    }
  }
}
