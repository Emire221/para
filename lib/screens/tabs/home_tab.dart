import 'package:flutter/material.dart';
import 'dart:ui';
import '../../util/app_colors.dart';
import '../../features/mascot/presentation/widgets/interactive_mascot_widget.dart';
import '../../widgets/daily_fact_widget.dart';

/// Ana sayfa tab'ı - Tam ekran interaktif maskot ile Talking Tom benzeri deneyim
class HomeTab extends StatelessWidget {
  /// Tab değiştirme callback'i (0: Ana Sayfa, 1: Dersler, 2: Oyunlar, 3: Profil)
  final void Function(int tabIndex)? onNavigateToTab;

  const HomeTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Katman 1: Arka plan dekorasyonları
        _buildBackgroundDecorations(context, isDarkMode),

        // Katman 2: Gradyan arka plan
        _buildGradientBackground(context, isDarkMode),

        // Katman 3: Büyük interaktif maskot (ortada)
        Positioned(
          top: screenHeight * 0.08,
          left: 0,
          right: 0,
          child: const InteractiveMascotWidget(enableVoiceInteraction: true),
        ),

        // Katman 4: Kaydırılabilir içerik (DraggableScrollableSheet)
        DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          snap: true,
          snapSizes: const [0.35, 0.6, 0.85],
          builder: (context, scrollController) {
            return _buildContentSheet(context, scrollController, isDarkMode);
          },
        ),
      ],
    );
  }

  Widget _buildGradientBackground(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  const Color(0xFF1a1a2e),
                  const Color(0xFF16213e),
                  const Color(0xFF0f0f23),
                ]
              : [
                  const Color(0xFFE8F5E9),
                  const Color(0xFFB2DFDB),
                  const Color(0xFF80CBC4),
                ],
        ),
      ),
    );
  }

  Widget _buildContentSheet(
    BuildContext context,
    ScrollController scrollController,
    bool isDarkMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[900]!.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sürükleme tutacağı
          _buildDragHandle(isDarkMode),

          // İçerik listesi
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const DailyFactWidget(),
                const SizedBox(height: 16),
                _buildWelcomeCard(context, isDarkMode),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(context, isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
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
            alpha: 0.08,
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
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoş Geldin, Bilgi Avcısı! 🎯',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Maskotuna basılı tut ve konuş - seni taklit etsin!',
                style: TextStyle(
                  fontSize: 14,
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

  Widget _buildQuickActionsGrid(BuildContext context, bool isDarkMode) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildQuickActionCard(
          context,
          icon: Icons.school,
          title: 'Ders Çalış',
          color: Colors.blue,
          isDarkMode: isDarkMode,
          onTap: () => onNavigateToTab?.call(1), // Dersler tab'ı
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.quiz,
          title: 'Sınav Ol',
          color: Colors.orange,
          isDarkMode: isDarkMode,
          onTap: () =>
              onNavigateToTab?.call(1), // Dersler tab'ı (sınavlar orada)
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.games,
          title: 'Oyun Oyna',
          color: Colors.purple,
          isDarkMode: isDarkMode,
          onTap: () => onNavigateToTab?.call(2), // Oyunlar tab'ı
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.emoji_events,
          title: 'Sıralama',
          color: Colors.amber,
          isDarkMode: isDarkMode,
          onTap: () =>
              onNavigateToTab?.call(3), // Profil tab'ı (sıralama orada)
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
