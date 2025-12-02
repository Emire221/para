import 'package:flutter/material.dart';
import 'dart:ui';
import '../lesson_selection_screen.dart';
import '../../util/app_colors.dart';
import '../achievements_screen.dart';

/// Dersler ve konular tab'ı - Eğitim modüllerini listeler
class LessonsTab extends StatelessWidget {
  const LessonsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Öğrenme Maceraları',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hangi maceraya katılmak istersin?',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              _buildLearningCard(
                context,
                isDarkMode,
                title: 'Şifre Kırma Operasyonu',
                subtitle: 'Soruları bil, kilitleri aç ve ödülleri topla!',
                imagePath: 'assets/images/card_safe.png',
                buttonText: 'Kodu Gir',
                buttonIcon: Icons.arrow_forward,
                lightColor: AppColors.card1Light,
                darkColor: AppColors.card1Dark,
                mode: 'test',
              ),
              const SizedBox(height: 20),
              _buildLearningCard(
                context,
                isDarkMode,
                title: 'Gizli İpuçları İzle',
                subtitle: 'Konu anlatım videolarıyla eksiklerini tamamla.',
                imagePath: 'assets/images/card_tv.png',
                buttonText: 'İzle ve Öğren',
                buttonIcon: Icons.play_arrow,
                lightColor: AppColors.card2Light,
                darkColor: AppColors.card2Dark,
                mode: 'video',
              ),
              const SizedBox(height: 20),
              _buildLearningCard(
                context,
                isDarkMode,
                title: 'Süper Bilgi Kartları',
                subtitle: 'Doğru/Yanlış kartlarıyla hafızanı güçlendir.',
                imagePath: 'assets/images/card_brain.png',
                buttonText: 'Kartları Çek',
                buttonIcon: Icons.style,
                lightColor: AppColors.card3Light,
                darkColor: AppColors.card3Dark,
                mode: 'flashcard',
              ),
              const SizedBox(height: 20),
              _buildLearningCard(
                context,
                isDarkMode,
                title: 'Başarılarım',
                subtitle: 'Oyun skorların ve istatistiklerin.',
                imagePath: 'assets/images/card_trophy.png',
                buttonText: 'İstatistikleri Gör',
                buttonIcon: Icons.emoji_events,
                lightColor: AppColors.card4Light,
                darkColor: AppColors.card4Dark,
                mode: 'achievements',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLearningCard(
    BuildContext context,
    bool isDarkMode, {
    required String title,
    required String subtitle,
    required String imagePath,
    required String buttonText,
    required IconData buttonIcon,
    required Color lightColor,
    required Color darkColor,
    required String mode,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? darkColor : lightColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDarkMode ? darkColor : lightColor).withValues(
                  alpha: 0.3,
                ),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(imagePath, width: 96, height: 96),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (mode == 'achievements') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AchievementsScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LessonSelectionScreen(mode: mode),
                            ),
                          );
                        }
                      },
                      label: Text(buttonText),
                      icon: Icon(buttonIcon, size: 16),
                      style:
                          ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            elevation: 0,
                          ).copyWith(
                            overlayColor: WidgetStateProperty.all(
                              Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
