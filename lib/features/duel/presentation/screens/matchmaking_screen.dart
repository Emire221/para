import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/duel_controller.dart';
import '../../domain/entities/duel_entities.dart';
import 'duel_game_screen.dart';

/// Rakip arama ekranı - animasyonlu matchmaking
class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  
  String _statusText = 'Rakip Aranıyor...';
  bool _isFound = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Pulse animasyonu
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Rotate animasyonu
    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Matchmaking sürecini başlat
    _startMatchmaking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _startMatchmaking() async {
    // Soruları yükle
    final success = await ref.read(duelControllerProvider.notifier).loadQuestions();
    
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sorular yüklenemedi, tekrar deneyin')),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Rastgele bekleme süresi (3-5 saniye)
    final waitTime = 3000 + _random.nextInt(2000);
    
    // Durum mesajlarını değiştir
    _updateStatusMessages();
    
    // Bekleme süresi
    await Future.delayed(Duration(milliseconds: waitTime));
    
    if (!mounted) return;

    // Rakip bulundu
    setState(() {
      _isFound = true;
      _statusText = 'Rakip Bulundu!';
    });

    // Kısa bir bekleme ve oyuna geç
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    // Oyunu başlat
    ref.read(duelControllerProvider.notifier).startGame();
    
    // Oyun ekranına git
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const DuelGameScreen(),
      ),
    );
  }

  void _updateStatusMessages() async {
    final messages = [
      'Rakip Aranıyor...',
      'Uygun oyuncu bulunuyor...',
      'Eşleştirme yapılıyor...',
      'Neredeyse tamam...',
    ];

    for (int i = 0; i < messages.length && mounted && !_isFound; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && !_isFound) {
        setState(() {
          _statusText = messages[i % messages.length];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duelControllerProvider);
    final botProfile = state.botProfile;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade400,
              Colors.deepOrange.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Oyun türü
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  state.gameType == DuelGameType.test 
                      ? '🎯 Test Çözme' 
                      : '📝 Cümle Tamamlama',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              // Animasyonlu avatar alanı
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: _isFound && botProfile != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                botProfile.avatar,
                                style: const TextStyle(fontSize: 50),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Lv.${botProfile.level}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RotationTransition(
                          turns: _rotateController,
                          child: const Icon(
                            Icons.search,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 30),

              // Durum metni
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusText,
                  key: ValueKey(_statusText),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),

              // Bot ismi (bulunduğunda)
              if (_isFound && botProfile != null) ...[
                Text(
                  botProfile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 48,
                ),
              ] else ...[
                // Arama göstergesi
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
              
              const SizedBox(height: 40),

              // İptal butonu
              if (!_isFound)
                TextButton.icon(
                  onPressed: () {
                    ref.read(duelControllerProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, color: Colors.white70),
                  label: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
