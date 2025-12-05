import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';

/// Sinematik Splash Screen
/// Oyunlaştırılmış eğitim uygulaması için etkileyici açılış deneyimi
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animasyon kontrolleri
  late AnimationController _meshController;
  late AnimationController _mascotBounceController;

  // Durum yönetimi
  bool _showBigBang = true;
  bool _showMascots = false;
  bool _showTitle = false;
  bool _showLoading = false;
  bool _isTransitioning = false;

  // Komik yükleme mesajları
  final List<String> _loadingMessages = [
    'Kedinin uykusu açılıyor... 😺',
    'Havuçlar toplanıyor... 🥕',
    'Matematik evreni kuruluyor... 🔢',
    'Köpek kuyruk sallıyor... 🐕',
    'Yıldızlar parlıyor... ⭐',
    'Bilgi hazinesi açılıyor... 📚',
    'Süper güçler şarj ediliyor... ⚡',
    'Macera kapıları açılıyor... 🚪',
  ];
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  // Renk paleti
  static const Color _primaryPurple = Color(0xFF6C5CE7);
  static const Color _energeticCoral = Color(0xFFFF7675);
  static const Color _turquoise = Color(0xFF00CEC9);
  static const Color _backgroundBase = Color(0xFFF5F6FA);
  static const Color _darkOverlay = Color(0xFF2D3436);

  // Maskot bounce state'leri
  final Map<String, bool> _mascotBouncing = {
    'kedi': false,
    'kopek': false,
    'tavsan': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Mesh gradient animasyonu için controller
    _meshController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    // Maskot bounce animasyonu için controller
    _mascotBounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _startAnimationSequence() async {
    // Splash ekranı minimum süresini takip et
    final splashStartTime = DateTime.now();
    const minimumSplashDuration = Duration(seconds: 2);

    // Big Bang - 0.5 saniye
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showBigBang = false);

    // Maskotlar beliriyor - 0.3 saniye sonra
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _showMascots = true);

    // Başlık beliriyor - 0.5 saniye sonra
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showTitle = true);

    // Loading beliriyor - 0.5 saniye sonra
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showLoading = true);

    // Minimum 2 saniye geçmesini garantile
    final elapsed = DateTime.now().difference(splashStartTime);
    if (elapsed < minimumSplashDuration) {
      await Future.delayed(minimumSplashDuration - elapsed);
    }

    // Mesaj değiştirme timer'ı
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % _loadingMessages.length;
      });
    });

    // Login'e geçiş
    if (!mounted) return;
    _navigateToLogin();
  }

  void _navigateToLogin() {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);

    Navigator.of(context).pushReplacement(_createZoomFadeTransition());
  }

  /// Özel Zoom + Fade geçiş animasyonu
  PageRouteBuilder<dynamic> _createZoomFadeTransition() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const LoginScreen(),
      transitionDuration: const Duration(milliseconds: 800),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Splash ekranı zoom out + fade out
        final splashZoom = Tween<double>(
          begin: 1.0,
          end: 1.5,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
        final splashFade = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

        // Login ekranı fade in + scale up
        final loginFade = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        final loginScale = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return Stack(
          children: [
            // Login Screen (arkada)
            FadeTransition(
              opacity: loginFade,
              child: ScaleTransition(scale: loginScale, child: child),
            ),
            // Splash Screen (önde, kaybolacak)
            if (animation.value < 1.0)
              FadeTransition(
                opacity: splashFade,
                child: ScaleTransition(
                  scale: splashZoom,
                  child: _buildSplashContent(),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Maskota tıklandığında bounce efekti
  void _onMascotTap(String mascotType) {
    if (_mascotBouncing[mascotType] == true) return;

    setState(() => _mascotBouncing[mascotType] = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _mascotBouncing[mascotType] = false);
      }
    });
  }

  @override
  void dispose() {
    _meshController.dispose();
    _mascotBounceController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildSplashContent());
  }

  Widget _buildSplashContent() {
    return Stack(
      children: [
        // 1. Hareketli Mesh Gradient Arka Plan
        _buildMeshGradientBackground(),

        // 2. Karanlık overlay (Big Bang öncesi)
        _buildDarkOverlay(),

        // 3. Big Bang noktası
        if (_showBigBang) _buildBigBangPoint(),

        // 4. Ana içerik
        _buildMainContent(),
      ],
    );
  }

  /// Hareketli Mesh Gradient Arka Plan
  Widget _buildMeshGradientBackground() {
    return AnimatedBuilder(
      animation: _meshController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: _backgroundBase,
          child: Stack(
            children: [
              // Mor top - sol üst
              _buildGradientOrb(
                color: _primaryPurple.withValues(alpha: 0.6),
                alignment: Alignment(
                  -1.2 + (_meshController.value * 0.4),
                  -1.2 + (_meshController.value * 0.3),
                ),
                size: 0.7,
              ),
              // Mercan top - sağ üst
              _buildGradientOrb(
                color: _energeticCoral.withValues(alpha: 0.5),
                alignment: Alignment(
                  1.2 - (_meshController.value * 0.3),
                  -0.8 + (_meshController.value * 0.4),
                ),
                size: 0.6,
              ),
              // Turkuaz top - alt orta
              _buildGradientOrb(
                color: _turquoise.withValues(alpha: 0.5),
                alignment: Alignment(
                  0.3 - (_meshController.value * 0.5),
                  1.3 - (_meshController.value * 0.2),
                ),
                size: 0.65,
              ),
              // Ekstra mor top - sağ alt
              _buildGradientOrb(
                color: _primaryPurple.withValues(alpha: 0.4),
                alignment: Alignment(
                  1.0 - (_meshController.value * 0.2),
                  0.8 + (_meshController.value * 0.3),
                ),
                size: 0.5,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Gradient Orb (Renkli bulanık top)
  Widget _buildGradientOrb({
    required Color color,
    required Alignment alignment,
    required double size,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        final orbSize = screenSize.shortestSide * size;

        return Align(
          alignment: alignment,
          child: Container(
            width: orbSize,
            height: orbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color, blurRadius: 120, spreadRadius: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Karanlık overlay (Big Bang öncesi efekt)
  Widget _buildDarkOverlay() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _showBigBang ? 0.7 : 0.0,
      child: Container(color: _darkOverlay),
    );
  }

  /// Big Bang noktası
  Widget _buildBigBangPoint() {
    return Center(
      child:
          Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              )
              .animate(onComplete: (_) {})
              .scale(
                begin: const Offset(0.1, 0.1),
                end: const Offset(3.0, 3.0),
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(delay: 300.ms, duration: 200.ms),
    );
  }

  /// Ana içerik
  Widget _buildMainContent() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenHeight < 600;

          // Responsive boyutlar - Ekran genişliğine göre otomatik ayar
          // 3 mascot + boşluklar = yaklaşık 3.5 * mascotSize
          // Merkez mascot 1.3x, yanlardakiler 1x = toplam 3.3x
          // Güvenli margin için 3.8x kullanıyoruz
          final maxMascotSize = screenWidth / 3.8;
          final mascotSize = maxMascotSize.clamp(70.0, 150.0);
          final titleSize = (screenWidth * 0.11).clamp(32.0, 64.0);
          final loadingSize = (screenWidth * 0.30).clamp(80.0, 160.0);

          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık - En üstte
                  if (_showTitle)
                    _buildTitle(titleSize, screenWidth)
                  else
                    SizedBox(height: titleSize + 20),

                  SizedBox(height: isSmallScreen ? 20 : 35),

                  // Maskotlar - Ortada, ekrana sığacak şekilde
                  _buildMascots(mascotSize, screenWidth),

                  SizedBox(height: isSmallScreen ? 20 : 35),

                  // Loading ve mesajlar - Alt kısım
                  if (_showLoading)
                    _buildLoadingSection(loadingSize, screenWidth)
                  else
                    SizedBox(height: loadingSize + 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Başlık animasyonu
  Widget _buildTitle(double fontSize, double screenWidth) {
    final letterSpacing = (screenWidth * 0.012).clamp(2.0, 6.0);

    return Column(
      children: [
        // Ana başlık - Responsive
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                Text(
                      'BİLGİ AVCISI',
                      style: GoogleFonts.bangers(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: _primaryPurple,
                        letterSpacing: letterSpacing,
                        shadows: [
                          Shadow(
                            color: _primaryPurple.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(2, 2),
                          ),
                          Shadow(
                            color: _energeticCoral.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(-1, 1),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .moveY(
                      begin: -40,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms)
                    .shimmer(
                      delay: 600.ms,
                      duration: 1200.ms,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
          ),
        ),

        const SizedBox(height: 10),

        // Alt başlık - Responsive
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryPurple.withValues(alpha: 0.1),
                            _turquoise.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🎮 Öğrenmenin Eğlenceli Yolu 🎮',
                        style: GoogleFonts.nunito(
                          fontSize: (fontSize * 0.38).clamp(12.0, 28.0),
                          fontWeight: FontWeight.w700,
                          color: _darkOverlay.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2, end: 0)
                    .then()
                    .shimmer(
                      delay: 500.ms,
                      duration: 1000.ms,
                      color: _turquoise.withValues(alpha: 0.3),
                    ),
          ),
        ),
      ],
    );
  }

  /// Maskotlar (Kedi, Köpek, Tavşan)
  Widget _buildMascots(double size, double screenWidth) {
    if (!_showMascots) {
      return SizedBox(height: size * 1.25);
    }

    // Mascotlar arası boşluk - responsive
    final spacing = (screenWidth * 0.02).clamp(4.0, 12.0);
    // Merkez mascot çarpanı
    final centerMultiplier = screenWidth < 360 ? 1.15 : 1.25;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Kedi (Sol)
            _buildMascot(
              assetPath: 'assets/animation/kedi_mascot.json',
              mascotType: 'kedi',
              size: size,
              delay: 0,
            ),

            SizedBox(width: spacing),

            // Köpek (Orta - biraz daha büyük)
            _buildMascot(
              assetPath: 'assets/animation/kopek_mascot.json',
              mascotType: 'kopek',
              size: size * centerMultiplier,
              delay: 100,
              isCenter: true,
            ),

            SizedBox(width: spacing),

            // Tavşan (Sağ)
            _buildMascot(
              assetPath: 'assets/animation/tavsan_mascot.json',
              mascotType: 'tavsan',
              size: size,
              delay: 200,
            ),
          ],
        ),
      ),
    );
  }

  /// Tek maskot widget'ı
  Widget _buildMascot({
    required String assetPath,
    required String mascotType,
    required double size,
    required int delay,
    bool isCenter = false,
  }) {
    final isBouncing = _mascotBouncing[mascotType] == true;

    return GestureDetector(
      onTap: () => _onMascotTap(mascotType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..setEntry(1, 3, isBouncing ? -20.0 : 0.0),
        child:
            Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: (isCenter ? _energeticCoral : _primaryPurple)
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Lottie.asset(
                    assetPath,
                    width: size,
                    height: size,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackMascot(mascotType, size);
                    },
                  ),
                )
                .animate(delay: Duration(milliseconds: delay))
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                )
                .shake(
                  delay: 400.ms,
                  duration: 300.ms,
                  hz: 4,
                  offset: const Offset(2, 0),
                ),
      ),
    );
  }

  /// Lottie yüklenemezse fallback
  Widget _buildFallbackMascot(String type, double size) {
    final icons = {'kedi': '🐱', 'kopek': '🐕', 'tavsan': '🐰'};
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _primaryPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Center(
        child: Text(
          icons[type] ?? '🎮',
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  /// Loading bölümü
  Widget _buildLoadingSection(double size, double screenWidth) {
    final messageFontSize = (screenWidth * 0.045).clamp(14.0, 20.0);

    return Column(
      children: [
        // Loading animasyonu
        SizedBox(
              width: size,
              height: size * 0.65,
              child: Lottie.asset(
                'assets/animation/loading-kum.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return CircularProgressIndicator(
                    color: _primaryPurple,
                    strokeWidth: 3,
                  );
                },
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

        const SizedBox(height: 16),

        // Komik mesajlar - Responsive
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child:
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryPurple.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _loadingMessages[_currentMessageIndex],
                          key: ValueKey<int>(_currentMessageIndex),
                          style: GoogleFonts.nunito(
                            fontSize: messageFontSize,
                            fontWeight: FontWeight.w700,
                            color: _darkOverlay.withValues(alpha: 0.85),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: 300.ms,
                    ),
          ),
        ),
      ],
    );
  }
}
