// 🧪 Ekran Test Dosyası
// Hangi ekranı test etmek istiyorsan import'u değiştir
// Kullanım: flutter run -d emulator-5554 -t lib/test_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

// 👇 Test etmek istediğin ekranı buradan import et
import 'features/exam/presentation/widgets/weekly_exam_card.dart';

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
        home: const _WeeklyExamCardTestScreen(),
      ),
    ),
  );
}

/// WeeklyExamCard test ekranı
class _WeeklyExamCardTestScreen extends StatelessWidget {
  const _WeeklyExamCardTestScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a0033),
      appBar: AppBar(
        title: const Text('Weekly Exam Card Test'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            WeeklyExamCard(),
            SizedBox(height: 32),
            Text(
              '👆 THE GOLDEN BOSS CARD',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
