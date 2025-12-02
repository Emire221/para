import 'package:flutter/material.dart';
import 'dart:ui';
import '../../util/app_colors.dart';
import '../../features/mascot/presentation/widgets/mascot_widget.dart';
import '../../widgets/daily_fact_widget.dart';

/// Ana sayfa tab'ı - Dashboard içeriğinin özeti
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        _buildBackgroundDecorations(context, isDarkMode),
        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                children: [
                  const MascotWidget(),
                  const DailyFactWidget(),
                  const SizedBox(height: 16),
                  _buildWelcomeCard(context, isDarkMode),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundDecorations(BuildContext context, bool isDarkMode) {
    return Stack(
      children: [
        _buildDecoImage(
          context,
          'assets/images/icon_compass_1.png',
          top: 0.08,
          left: -0.05,
        ),
        _buildDecoImage(
          context,
          'assets/images/icon_palette.png',
          top: 0.05,
          right: -0.03,
        ),
        _buildDecoImage(
          context,
          'assets/images/icon_ruler.png',
          top: 0.3,
          right: -0.05,
          angle: -12,
        ),
        _buildDecoImage(
          context,
          'assets/images/icon_book.png',
          top: 0.5,
          right: -0.03,
        ),
        _buildDecoImage(
          context,
          'assets/images/icon_compass_2.png',
          top: 0.5,
          left: -0.05,
        ),
        _buildDecoImage(
          context,
          'assets/images/icon_backpack.png',
          bottom: 0.1,
          right: -0.03,
        ),
      ],
    );
  }

  Widget _buildDecoImage(
    BuildContext context,
    String path, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    double angle = 0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: top != null ? screenHeight * top : null,
      bottom: bottom != null ? screenHeight * bottom : null,
      left: left != null ? screenWidth * left : null,
      right: right != null ? screenWidth * right : null,
      child: Transform.rotate(
        angle: angle * 3.14159 / 180,
        child: Image.asset(
          path,
          width: 64,
          height: 64,
          color: (isDarkMode ? Colors.white : Colors.black).withValues(
            alpha: 0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey[800]!.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoş Geldin, Bilgi Avcısı! 🎯',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bugün hangi macerayı seçiyorsun?',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
