import 'package:flutter/material.dart';
import '../profile_settings_screen.dart';

/// Profil ayarları tab'ı
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Doğrudan ProfileSettingsScreen'i göster
    return const ProfileSettingsScreen();
  }
}
