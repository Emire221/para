import 'package:flutter/material.dart';
import '../../features/games/fill_blanks/presentation/screens/level_selection_screen.dart';
import '../../features/games/arena/presentation/screens/opponent_search_screen.dart';

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
        height: 140,
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
                mainAxisAlignment: MainAxisAlignment.center,
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
