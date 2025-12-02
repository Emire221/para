import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../widgets/game_result_card.dart';
import '../util/app_colors.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Başarılarım'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.card4Light,
          labelColor: isDarkMode ? Colors.white : Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Testler'),
            Tab(text: 'Bilgi Kartları'),
            Tab(text: 'Cümle Tamamlama'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [AppColors.backgroundDark, const Color(0xFF1a202c)]
                : [AppColors.backgroundLight, Colors.white],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildResultList('test'),
            _buildResultList('flashcard'),
            _buildResultList('fill_blanks'),
          ],
        ),
      ),
    );
  }

  Widget _buildResultList(String gameType) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dbHelper.getGameResults(gameType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz kayıtlı sonuç yok',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return GameResultCard(
              gameType: result['gameType'] as String,
              score: result['score'] as int,
              correctCount: result['correctCount'] as int,
              wrongCount: result['wrongCount'] as int,
              totalQuestions: result['totalQuestions'] as int,
              date: result['completedAt'] as String,
            );
          },
        );
      },
    );
  }
}
