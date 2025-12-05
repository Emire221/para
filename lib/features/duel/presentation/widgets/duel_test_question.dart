import 'package:flutter/material.dart';
import '../../domain/entities/duel_entities.dart';

/// Test sorusu widget'ı
class DuelTestQuestion extends StatelessWidget {
  final DuelQuestion question;
  final int? userSelectedIndex;
  final int? botSelectedIndex;
  final bool isAnswered;
  final Function(int) onAnswerSelected;

  const DuelTestQuestion({
    super.key,
    required this.question,
    this.userSelectedIndex,
    this.botSelectedIndex,
    required this.isAnswered,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Soru metni
        Expanded(
          flex: 2,
          child: Center(
            child: SingleChildScrollView(
              child: Text(
                question.question,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Şıklar
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(question.options.length, (index) {
              return _buildOptionButton(context, index);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(BuildContext context, int index) {
    final isCorrect = index == question.correctIndex;
    final isUserSelected = userSelectedIndex == index;
    final isBotSelected = botSelectedIndex == index;

    Color backgroundColor = Colors.grey[100]!;
    Color borderColor = Colors.grey[300]!;
    Color textColor = Colors.black87;

    // Cevaplandıktan sonra renkleri göster
    if (isAnswered) {
      if (isCorrect) {
        backgroundColor = Colors.green[100]!;
        borderColor = Colors.green;
        textColor = Colors.green[800]!;
      } else if (isUserSelected || isBotSelected) {
        backgroundColor = Colors.red[100]!;
        borderColor = Colors.red;
        textColor = Colors.red[800]!;
      }
    } else if (isUserSelected) {
      backgroundColor = Colors.blue[100]!;
      borderColor = Colors.blue;
      textColor = Colors.blue[800]!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: isAnswered ? null : () => onAnswerSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              // Şık harfi
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Seçenek metni
              Expanded(
                child: Text(
                  question.options[index],
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
              ),

              // İşaretler
              if (isAnswered) ...[
                if (isUserSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                if (isBotSelected) ...[
                  if (isUserSelected) const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
