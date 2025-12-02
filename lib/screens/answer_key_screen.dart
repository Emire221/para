import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';

class AnswerKeyScreen extends StatelessWidget {
  final List<Map<String, dynamic>> answeredQuestions;

  const AnswerKeyScreen({super.key, required this.answeredQuestions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cevap Anahtarı',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDA22FF), Color(0xFF9733EE)],
          ),
        ),
        child: answeredQuestions.isEmpty
            ? const Center(
                child: Text(
                  'Hiç soru cevaplanmadı',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: answeredQuestions.length,
                itemBuilder: (context, index) {
                  try {
                    final item = answeredQuestions[index];

                    final question = item['question'] as Map<String, dynamic>?;
                    if (question == null) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: GlassContainer(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Soru verisi hatalı',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    }

                    final userAnswer = item['userAnswer']?.toString() ?? '-';
                    final correctAnswer =
                        question['dogruCevap']?.toString() ?? '';
                    final questionNumber =
                        item['questionNumber']?.toString() ?? '?';
                    final isCorrect = userAnswer == correctAnswer;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Soru $questionNumber',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              question['soruMetni']?.toString() ??
                                  'Soru metni bulunamadı',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Doğru Cevap: $correctAnswer',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isCorrect)
                              Text(
                                'Senin Cevabın: $userAnswer',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  } catch (e) {
                    // Hata durumunda güvenli fallback göster
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Soru #${index + 1} verisi okunamadı',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }
                },
              ),
      ),
    );
  }
}
