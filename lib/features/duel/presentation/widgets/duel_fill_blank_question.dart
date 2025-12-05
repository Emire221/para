import 'package:flutter/material.dart';
import '../../domain/entities/duel_entities.dart' as entities;

/// Cümle tamamlama sorusu widget'ı
class DuelFillBlankQuestionWidget extends StatelessWidget {
  final entities.DuelFillBlankQuestion question;
  final int? userSelectedIndex;
  final int? botSelectedIndex;
  final bool isAnswered;
  final Function(int) onAnswerSelected;

  const DuelFillBlankQuestionWidget({
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
        // Cümle
        Expanded(
          flex: 2,
          child: Center(
            child: SingleChildScrollView(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  children: _buildSentenceSpans(),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Seçenekler (Grid)
        Expanded(
          flex: 3,
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(question.options.length, (index) {
              return _buildOptionButton(context, index);
            }),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildSentenceSpans() {
    final parts = question.sentence.split('_');
    final List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));

      if (i < parts.length - 1) {
        // Boşluk alanı
        String blankText = '______';
        TextStyle blankStyle = const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.orange,
          decoration: TextDecoration.underline,
        );

        if (isAnswered) {
          blankText = question.answer;
          blankStyle = const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          );
        } else if (userSelectedIndex != null) {
          blankText = question.options[userSelectedIndex!];
          blankStyle = const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          );
        }

        spans.add(TextSpan(text: blankText, style: blankStyle));
      }
    }

    return spans;
  }

  Widget _buildOptionButton(BuildContext context, int index) {
    final option = question.options[index];
    final isCorrect = option == question.answer;
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

    return InkWell(
      onTap: isAnswered ? null : () => onAnswerSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // İşaretler
            if (isAnswered) ...[
              const SizedBox(width: 4),
              if (isUserSelected)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              if (isBotSelected) ...[
                if (isUserSelected) const SizedBox(width: 2),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
