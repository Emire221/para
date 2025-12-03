import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_helper.dart';
import '../features/mascot/presentation/providers/mascot_provider.dart';
import 'answer_key_screen.dart';
import 'main_screen.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final int score;
  final int correctCount;
  final int wrongCount;
  final String topicId;
  final String topicName;
  final List<Map<String, dynamic>> answeredQuestions;
  final bool isFlashcard;

  const ResultScreen({
    super.key,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.topicId = '',
    this.topicName = '',
    this.answeredQuestions = const [],
    this.isFlashcard = false,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _resultSaved = false;

  @override
  void initState() {
    super.initState();
    _initializeResults();
  }

  Future<void> _initializeResults() async {
    await _saveResult();
    await _addXpToMascot();
  }

  Future<void> _saveResult() async {
    // Çift kayıt önleme
    if (_resultSaved) return;
    _resultSaved = true;

    try {
      // Yerel veritabanına kaydet
      final dbHelper = DatabaseHelper();
      await dbHelper.saveGameResult(
        gameType: widget.isFlashcard ? 'flashcard' : 'test',
        score: widget.score,
        correctCount: widget.correctCount,
        wrongCount: widget.wrongCount,
        totalQuestions: widget.correctCount + widget.wrongCount,
      );
      debugPrint(
        'Sonuç kaydedildi: ${widget.isFlashcard ? "flashcard" : "test"} - Skor: ${widget.score}',
      );
    } catch (e) {
      debugPrint('Sonuç kaydetme hatası: $e');
    }
  }

  /// Maskota XP ekle - Her oyun/test bitiminde 1 XP
  Future<void> _addXpToMascot() async {
    try {
      final mascotRepository = ref.read(mascotRepositoryProvider);
      await mascotRepository.addXp(1);
      // Provider'ı yenile ki UI güncellensin
      ref.invalidate(activeMascotProvider);
    } catch (e) {
      debugPrint('Maskot XP ekleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDA22FF), Color(0xFF9733EE)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.yellow, size: 100),
              const SizedBox(height: 24),
              const Text(
                'Tebrikler!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Puanın: ${widget.score}',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Doğru: ${widget.correctCount} / Yanlış: ${widget.wrongCount}',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Ana Sayfa'),
                  ),
                  // Flashcard modunda Cevapları Gör butonu gizlenir
                  if (!widget.isFlashcard) ...[
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnswerKeyScreen(
                              answeredQuestions: widget.answeredQuestions,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Cevapları Gör'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
