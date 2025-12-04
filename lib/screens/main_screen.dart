import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../main.dart'; // themeManager'a erişim için
import '../util/app_colors.dart';
import '../core/providers/user_provider.dart';
import '../services/shake_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/lessons_tab.dart';
import 'tabs/games_tab.dart';
import 'tabs/profile_tab.dart';
import 'notifications_screen.dart';

/// Uygulamanın ana iskeleti - BottomNavigationBar ile 4 tab yönetimi
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  ShakeService? _shakeService;

  // Tab'ları geç başlat (callback ile)
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    // Tab'ları callback ile oluştur
    _tabs = [
      HomeTab(onNavigateToTab: _navigateToTab),
      const LessonsTab(),
      const GamesTab(),
      const ProfileTab(),
    ];

    // Shake servisi başlatma (build sonrası)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shakeService = ShakeService(context);
      _shakeService?.start();
    });
  }

  /// Belirtilen tab'a geçiş yapar
  void _navigateToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  void dispose() {
    _shakeService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Brightness platformBrightness = MediaQuery.platformBrightnessOf(
      context,
    );
    final bool isSystemDark = platformBrightness == Brightness.dark;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeManager,
      builder: (context, currentMode, child) {
        final bool isDarkMode;
        if (currentMode == ThemeMode.system) {
          isDarkMode = isSystemDark;
        } else {
          isDarkMode = currentMode == ThemeMode.dark;
        }

        return PopScope(
          canPop: false, // Geri butonunu devre dışı bırak
          child: Scaffold(
            appBar: _currentIndex == 0
                ? _buildAppBar(context, isDarkMode)
                : null,
            body: IndexedStack(index: _currentIndex, children: _tabs),
            bottomNavigationBar: _buildBottomNavigationBar(isDarkMode),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDarkMode) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[900]!.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
      title: userProfileAsync.when(
        data: (profile) {
          final name = profile?['name'] ?? 'Öğrenci';
          final grade = profile?['grade'] ?? '3. Sınıf';
          final avatar = profile?['avatar'] ?? 'assets/images/avatar.png';

          final avatarImage = avatar.startsWith('assets/')
              ? AssetImage(avatar)
              : const AssetImage('assets/images/avatar.png');

          return Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: avatarImage),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '$grade Kaptanı',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      actions: [
        _buildThemeToggleButton(context, isDarkMode),
        const SizedBox(width: 8),
        PopupMenuButton<void>(
          offset: const Offset(0, 50),
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Stack(
            alignment: Alignment.topRight,
            children: [
              Icon(
                Icons.notifications,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                size: 28,
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              enabled: false,
              padding: EdgeInsets.zero,
              child: NotificationsList(),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildThemeToggleButton(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[700]!.withValues(alpha: 0.5)
            : Colors.grey[200]!.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _themeButton(
            context,
            Icons.light_mode,
            !isDarkMode,
            () => themeManager.toggleTheme(false),
          ),
          _themeButton(
            context,
            Icons.dark_mode,
            isDarkMode,
            () => themeManager.toggleTheme(true),
          ),
        ],
      ),
    );
  }

  Widget _themeButton(
    BuildContext context,
    IconData icon,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.grey[800] : Colors.white)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected
              ? (isDarkMode ? Colors.yellow[400] : Colors.yellow[700])
              : (isDarkMode ? Colors.grey[400] : Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDarkMode
                ? Colors.grey[900]!.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.9),
            selectedItemColor: isDarkMode
                ? AppColors.card1Dark
                : AppColors.card1Light,
            unselectedItemColor: isDarkMode
                ? Colors.grey[400]
                : Colors.grey[600],
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'Dersler',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.games_outlined),
                activeIcon: Icon(Icons.games),
                label: 'Oyunlar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
