import 'package:flutter/material.dart';
import '../../domain/models/weekly_exam.dart';
import '../../data/weekly_exam_service.dart';

/// Haftalık sınav sonuç ekranı - Pazar 20:00'da açılır
class WeeklyExamResultScreen extends StatefulWidget {
  final WeeklyExam exam;
  final WeeklyExamResult? result;

  const WeeklyExamResultScreen({super.key, required this.exam, this.result});

  @override
  State<WeeklyExamResultScreen> createState() => _WeeklyExamResultScreenState();
}

class _WeeklyExamResultScreenState extends State<WeeklyExamResultScreen> {
  final WeeklyExamService _examService = WeeklyExamService();

  @override
  Widget build(BuildContext context) {
    final weekStart = _examService.getThisWeekMonday();
    final areResultsAvailable = _examService.areResultsAvailable(weekStart);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade800, Colors.purple.shade400],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        _examService.generateRoomName(weekStart),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),

              // İçerik
              Expanded(
                child: areResultsAvailable
                    ? _buildResultsContent()
                    : _buildWaitingContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingContent() {
    final weekStart = _examService.getThisWeekMonday();
    final remaining = _examService.getTimeRemaining(
      weekStart,
      ExamRoomStatus.kapali,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Sonuçlar Bekleniyor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sonuçlar Pazar 20:00\'da açıklanacak',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _formatDuration(remaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (widget.result != null) ...[
              const Divider(color: Colors.white30),
              const SizedBox(height: 16),
              const Text(
                'Senin Cevapların',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildAnswerSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent() {
    if (widget.result == null) {
      return _buildNoParticipationContent();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Ana skor kartı
          _buildScoreCard(),

          const SizedBox(height: 24),

          // Sıralama kartı
          _buildRankingCard(),

          const SizedBox(height: 24),

          // İstatistikler
          _buildStatsGrid(),

          const SizedBox(height: 24),

          // Detaylı cevaplar
          _buildDetailedAnswers(),
        ],
      ),
    );
  }

  Widget _buildNoParticipationContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied,
              size: 100,
              color: Colors.white54,
            ),
            const SizedBox(height: 24),
            const Text(
              'Bu sınava katılmadın',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Gelecek hafta seni bekliyoruz! 💪',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final puan = widget.result?.puan ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
          const SizedBox(height: 16),
          const Text(
            'Puanın',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '$puan',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(puan),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getScoreMessage(puan),
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard() {
    final siralama = widget.result?.siralama;
    final toplamKatilimci = widget.result?.toplamKatilimci;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            '🇹🇷 Türkiye Sıralaması',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (siralama != null && toplamKatilimci != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '#$siralama',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8),
                  child: Text(
                    '/ $toplamKatilimci',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getRankingMessage(siralama, toplamKatilimci),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ] else ...[
            const Text(
              'Sıralama hesaplanıyor...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Doğru',
            widget.result?.dogru?.toString() ?? '-',
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Yanlış',
            widget.result?.yanlis?.toString() ?? '-',
            Colors.red,
            Icons.cancel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Boş',
            widget.result?.bos?.toString() ?? '-',
            Colors.grey,
            Icons.remove_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnswers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cevap Anahtarı',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...widget.exam.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final questionId = (index + 1).toString();
            final userAnswer = widget.result?.cevaplar[questionId];
            final isCorrect = userAnswer == question.correctAnswer;
            final isEmpty = userAnswer == null || userAnswer == 'EMPTY';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isEmpty
                          ? Colors.grey.shade200
                          : isCorrect
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        questionId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isEmpty
                              ? Colors.grey
                              : isCorrect
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Senin: ${isEmpty ? "-" : userAnswer}',
                    style: TextStyle(
                      color: isEmpty
                          ? Colors.grey
                          : isCorrect
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Doğru: ${question.correctAnswer}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Icon(
                    isEmpty
                        ? Icons.remove_circle_outline
                        : isCorrect
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: isEmpty
                        ? Colors.grey
                        : isCorrect
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnswerSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Doğru',
            widget.result?.dogru?.toString() ?? '-',
            Colors.green,
          ),
          _buildSummaryItem(
            'Yanlış',
            widget.result?.yanlis?.toString() ?? '-',
            Colors.red,
          ),
          _buildSummaryItem(
            'Boş',
            widget.result?.bos?.toString() ?? '-',
            Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(int score) {
    if (score >= 90) return 'Mükemmel! 🌟';
    if (score >= 80) return 'Harika! 🎉';
    if (score >= 70) return 'Çok iyi! 👏';
    if (score >= 60) return 'İyi! 👍';
    if (score >= 50) return 'Fena değil 😊';
    if (score >= 40) return 'Geliştirebilirsin 💪';
    return 'Daha çok çalışmalısın 📚';
  }

  String _getRankingMessage(int rank, int total) {
    final percentage = (rank / total * 100);
    if (percentage <= 1) return 'İlk %1\'desin! Süpersin! 🏆';
    if (percentage <= 5) return 'İlk %5\'tesin! Harika! 🥇';
    if (percentage <= 10) return 'İlk %10\'dasın! Çok iyi! 🥈';
    if (percentage <= 25) return 'İlk %25\'tesin! Başarılı! 🥉';
    if (percentage <= 50) return 'Üst yarıdasın! İyi gidiyorsun! 👍';
    return 'Gelişmeye devam et! 💪';
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00:00';

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return '$days gün ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
