import 'package:flutter/material.dart';
import 'glass_container.dart';
import 'package:intl/intl.dart';

class GameResultCard extends StatelessWidget {
  final String gameType;
  final int score;
  final int correctCount;
  final int wrongCount;
  final int totalQuestions;
  final String date;

  const GameResultCard({
    super.key,
    required this.gameType,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.totalQuestions,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime parsedDate = DateTime.tryParse(date) ?? DateTime.now();
    final String formattedDate = DateFormat(
      'dd MMM yyyy HH:mm',
      'tr_TR',
    ).format(parsedDate);

    IconData icon;
    Color iconColor;
    String title;

    switch (gameType) {
      case 'test':
        icon = Icons.quiz;
        iconColor = Colors.blueAccent;
        title = 'Test Çözümü';
        break;
      case 'flashcard':
        icon = Icons.style;
        iconColor = Colors.greenAccent;
        title = 'Bilgi Kartları';
        break;
      case 'fill_blanks':
        icon = Icons.text_fields;
        iconColor = Colors.orangeAccent;
        title = 'Cümle Tamamlama';
        break;
      default:
        icon = Icons.videogame_asset;
        iconColor = Colors.purpleAccent;
        title = 'Oyun';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '$score Puan',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(
                  'Doğru',
                  correctCount.toString(),
                  Colors.greenAccent,
                ),
                _buildStatItem(
                  'Yanlış',
                  wrongCount.toString(),
                  Colors.redAccent,
                ),
                _buildStatItem(
                  'Toplam',
                  totalQuestions.toString(),
                  Colors.blueAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
