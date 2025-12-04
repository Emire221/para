import 'package:flutter/material.dart';
import '../../features/games/fill_blanks/presentation/screens/level_selection_screen.dart';
import '../../features/games/arena/presentation/screens/opponent_search_screen.dart';
import '../../features/games/guess/presentation/screens/guess_level_selection_screen.dart';
import '../../features/games/memory/presentation/screens/memory_game_screen.dart';

/// Oyunlar tab'ı
class GamesTab extends StatelessWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Mini Oyunlar',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Eğlenerek öğren!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildGameCard(
          context,
          title: 'Cümle Tamamlama',
          description: 'Boşluğa doğru kelimeyi sürükle!',
          icon: Icons.text_fields,
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade700],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LevelSelectionScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          context,
          title: 'Arena Düello',
          description: 'Botlarla yarış!',
          icon: Icons.sports_esports,
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OpponentSearchScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          context,
          title: 'Salla Bakalım',
          description: 'Telefonu salla, sayıyı tahmin et!',
          icon: Icons.vibration,
          gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.cyan.shade600],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GuessLevelSelectionScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          context,
          title: 'Bul Bakalım',
          description: '1\'den 10\'a kadar sırayla bul!',
          icon: Icons.grid_view_rounded,
          gradient: LinearGradient(
            colors: [Colors.indigo.shade400, Colors.purple.shade600],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MemoryGameScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 140, // Minimum yükseklik
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 120,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Flexible size
                children: [
                  Icon(icon, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
