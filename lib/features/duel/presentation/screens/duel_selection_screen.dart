import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/duel_controller.dart';
import '../../domain/entities/duel_entities.dart';
import '../../data/connectivity_service.dart';
import 'matchmaking_screen.dart';

/// Düello seçim ekranı - oyun türü seçimi için modal bottom sheet
class DuelSelectionSheet extends ConsumerWidget {
  const DuelSelectionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Başlık
          const Row(
            children: [
              Icon(Icons.sports_esports, size: 32, color: Colors.orange),
              SizedBox(width: 12),
              Text(
                '1v1 Düello',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Rakibinle yarış! Hangi oyun türünde mücadele etmek istersin?',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),

          const SizedBox(height: 24),

          // Test Çözme seçeneği
          _buildOptionCard(
            context,
            ref,
            title: 'Test Çözme',
            description: '4 şıklı sorularla yarış',
            icon: Icons.quiz,
            color: Colors.blue,
            gameType: DuelGameType.test,
          ),

          const SizedBox(height: 12),

          // Cümle Tamamlama seçeneği
          _buildOptionCard(
            context,
            ref,
            title: 'Cümle Tamamlama',
            description: 'Boşlukları doğru kelimeyle doldur',
            icon: Icons.text_fields,
            color: Colors.purple,
            gameType: DuelGameType.fillBlanks,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required DuelGameType gameType,
  }) {
    return InkWell(
      onTap: () => _onGameTypeSelected(context, ref, gameType),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _onGameTypeSelected(
    BuildContext context,
    WidgetRef ref,
    DuelGameType gameType,
  ) async {
    // Modal'ı kapat
    Navigator.pop(context);

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    // İnternet kontrolü
    final hasInternet = await ConnectivityService.hasInternetConnection();

    // Loading'i kapat
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (!hasInternet) {
      // İnternet yok hatası göster
      if (context.mounted) {
        _showNoInternetDialog(context);
      }
      return;
    }

    // Oyun türünü seç
    ref.read(duelControllerProvider.notifier).selectGameType(gameType);

    // Matchmaking ekranına git
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MatchmakingScreen()),
      );
    }
  }

  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Bağlantı Hatası'),
          ],
        ),
        content: const Text(
          'Düello oynayabilmek için internet bağlantısı gereklidir. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

/// Düello seçim modal'ını göster
void showDuelSelectionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const DuelSelectionSheet(),
  );
}
