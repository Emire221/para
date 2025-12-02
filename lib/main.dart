import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'util/app_colors.dart';

// Basit bir tema yöneticisi
class ThemeManager extends ValueNotifier<ThemeMode> {
  ThemeManager() : super(ThemeMode.system);

  void toggleTheme(bool isDarkMode) {
    value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}

// Uygulamanın herhangi bir yerinden tema yöneticisine erişim sağlamak için
// bir InheritedWidget (veya Provider gibi bir paket) kullanılabilir.
// Şimdilik, global bir değişken kullanarak basitleştireceğiz.
final themeManager = ThemeManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeManager,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Görev Merkezi',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.backgroundLight,
            primaryColor: AppColors.primary,
            textTheme: GoogleFonts.nunitoTextTheme(textTheme).apply(
              bodyColor: AppColors.textLight,
              displayColor: AppColors.textLight,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.backgroundDark,
            primaryColor: AppColors.primary,
            textTheme: GoogleFonts.nunitoTextTheme(textTheme).apply(
              bodyColor: AppColors.textDark,
              displayColor: AppColors.textDark,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
              surface: AppColors.backgroundDark,
            ),
            useMaterial3: true,
          ),
          themeMode: currentMode,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                return const AuthWrapper();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Hata: ${snapshot.error}')));
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          return const MainScreen();
        }

        return const ProfileSetupScreen();
      },
    );
  }
}
