import 'package:flutter/material.dart';
import 'dart:async';
import '../../domain/models/weekly_exam.dart';
import '../../data/weekly_exam_service.dart';

/// Haftalık sınav çözme ekranı
class WeeklyExamScreen extends StatefulWidget {
  final WeeklyExam exam;

  const WeeklyExamScreen({super.key, required this.exam});

  @override
  State<WeeklyExamScreen> createState() => _WeeklyExamScreenState();
}

class _WeeklyExamScreenState extends State<WeeklyExamScreen> {
  final PageController _pageController = PageController();
  final WeeklyExamService _examService = WeeklyExamService();
  final Map<String, String> _answers = {};

  late int _remainingSeconds;
  Timer? _timer;
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.exam.duration * 60;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _finishExam();
        }
      });
    });
  }

  void _selectAnswer(String questionId, String answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  Future<void> _finishExam() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    _timer?.cancel();

    try {
      // Boş bırakılan soruları "EMPTY" olarak işaretle
      final allAnswers = <String, String>{};
      for (var i = 0; i < widget.exam.questions.length; i++) {
        final questionId = (i + 1).toString();
        allAnswers[questionId] = _answers[questionId] ?? 'EMPTY';
      }

      // Sonucu kaydet
      await _examService.saveExamResult(
        examId: widget.exam.examId,
        answers: allAnswers,
        exam: widget.exam,
      );

      if (!mounted) return;

      // Kullanıcıyı bilgilendir ve ana sayfaya dön
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cevapların kaydedildi! 🎉 Sonuçlar Pazar 20:00\'da açıklanacak.',
          ),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _isSubmitting = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sınavı Bırak'),
            content: const Text(
              'Sınavdan çıkmak istediğine emin misin?\n\n'
              '⚠️ Cevapların kaydedilmeyecek!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hayır, Devam Et'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Evet, Çık'),
              ),
            ],
          ),
        );
        if (shouldPop ?? false) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.indigo.shade800, Colors.indigo.shade400],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Üst bar
                _buildTopBar(),

                // İlerleme çubuğu
                LinearProgressIndicator(
                  value:
                      (_currentQuestionIndex + 1) /
                      widget.exam.questions.length,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),

                // Soru alanı
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                    },
                    itemCount: widget.exam.questions.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionPage(index);
                    },
                  ),
                ),

                // Alt navigasyon
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isLowTime = _remainingSeconds < 300; // Son 5 dakika

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Sınav başlığı
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exam.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentQuestionIndex + 1}/${widget.exam.questions.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Geri sayım
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isLowTime
                  ? Colors.red
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = widget.exam.questions[index];
    final questionId = (index + 1).toString();
    final selectedAnswer = _answers[questionId];

    final options = [
      ('A', question.optionA),
      ('B', question.optionB),
      ('C', question.optionC),
      ('D', question.optionD),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soru numarası
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Soru ${index + 1}',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Soru metni
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Seçenekler
          ...options.map((option) {
            final letter = option.$1;
            final text = option.$2;
            final isSelected = selectedAnswer == letter;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectAnswer(questionId, letter),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.amber.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.amber
                                : Colors.indigo.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.indigo.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.amber),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cevaplanmış soru sayısı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_answers.length}/${widget.exam.questions.length} cevaplandı',
              style: TextStyle(
                color: Colors.indigo.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Spacer(),

          // Geri butonu
          if (_currentQuestionIndex > 0)
            IconButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_back_ios),
              color: Colors.indigo,
            ),

          // İleri/Bitir butonu
          ElevatedButton.icon(
            onPressed: () {
              if (_currentQuestionIndex < widget.exam.questions.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _showFinishDialog();
              }
            },
            icon: Icon(
              _currentQuestionIndex < widget.exam.questions.length - 1
                  ? Icons.arrow_forward_ios
                  : Icons.check,
            ),
            label: Text(
              _currentQuestionIndex < widget.exam.questions.length - 1
                  ? 'İleri'
                  : 'Bitir',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _currentQuestionIndex < widget.exam.questions.length - 1
                  ? Colors.indigo
                  : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog() {
    final unanswered = widget.exam.questions.length - _answers.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınavı Bitir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.exam.questions.length} sorudan ${_answers.length} tanesini cevapladın.',
            ),
            if (unanswered > 0) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ $unanswered soru boş bırakılacak.',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Sınavı bitirmek istediğine emin misin?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _finishExam();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
