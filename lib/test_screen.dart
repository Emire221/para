// 🧪 Ekran Test Dosyası
// Hangi ekranı test etmek istiyorsan import'u değiştir
// Kullanım: flutter run -d emulator-5554 -t lib/test_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

// 👇 Test etmek istediğin ekranı buradan import et
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlat (gerekirse)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Screen Test',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C5CE7),
            brightness: Brightness.light,
          ),
        ),
        // 👇 Test etmek istediğin ekranı buraya yaz
        home: const MainScreen(),
      ),
    ),
  );
}
