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
    _tabController = TabController(length: 5, vsync: this);
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
            Tab(text: 'Kartlar'),
            Tab(text: 'Cümle'),
            Tab(text: 'Salla'),
            Tab(text: 'Bul'),
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
            _buildGuessResultList(),
            _buildMemoryResultList(),
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

  Widget _buildGuessResultList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dbHelper.getGameResults('guess'),
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
                  Icons.vibration,
                  size: 64,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz Salla Bakalım oyunu oynamadın',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Son 10 oyun sonucu burada gösterilir',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.withValues(alpha: 0.6),
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
            return _buildGuessResultCard(result);
          },
        );
      },
    );
  }

  Widget _buildGuessResultCard(Map<String, dynamic> result) {
    final score = result['score'] as int;
    final correctCount = result['correctCount'] as int;
    final totalQuestions = result['totalQuestions'] as int;
    final dateStr = result['completedAt'] as String;
    final details = result['details'] as String?;

    // Parse details JSON
    String levelTitle = 'Bilinmeyen Seviye';
    int difficulty = 1;
    if (details != null && details.isNotEmpty) {
      try {
        // Simple parsing for our known format
        final titleMatch = RegExp(
          r'"levelTitle":\s*"([^"]+)"',
        ).firstMatch(details);
        final diffMatch = RegExp(r'"difficulty":\s*(\d+)').firstMatch(details);
        if (titleMatch != null) levelTitle = titleMatch.group(1)!;
        if (diffMatch != null) difficulty = int.parse(diffMatch.group(1)!);
      } catch (_) {}
    }

    final percentage = totalQuestions > 0 ? correctCount / totalQuestions : 0.0;
    final starCount = percentage >= 1.0
        ? 3
        : (percentage >= 0.7 ? 2 : (percentage >= 0.4 ? 1 : 0));

    // Parse date
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      date = DateTime.now();
    }

    final difficultyText = difficulty == 1
        ? 'Kolay'
        : (difficulty == 2 ? 'Orta' : 'Zor');
    final difficultyColor = difficulty == 1
        ? Colors.green
        : (difficulty == 2 ? Colors.orange : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.cyan.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım: Başlık ve yıldızlar
              Row(
                children: [
                  const Icon(Icons.vibration, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      levelTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Yıldızlar
                  Row(
                    children: List.generate(
                      3,
                      (i) => Icon(
                        i < starCount ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Orta kısım: Skor ve istatistikler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skor
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skor',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Doğru/Toplam
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Doğru',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '$correctCount/$totalQuestions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Zorluk
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: difficultyColor),
                    ),
                    child: Text(
                      difficultyText,
                      style: TextStyle(
                        color: difficultyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Alt kısım: Tarih
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryResultList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dbHelper.getGameResults('memory'),
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
                  Icons.grid_view_rounded,
                  size: 64,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz Bul Bakalım oyunu oynamadın',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kartları sırayla bul!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.withValues(alpha: 0.6),
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
            return _buildMemoryResultCard(result);
          },
        );
      },
    );
  }

  Widget _buildMemoryResultCard(Map<String, dynamic> result) {
    final score = result['score'] as int;
    final wrongCount = result['wrongCount'] as int;
    final dateStr = result['completedAt'] as String;
    final details = result['details'] as String?;

    // Parse details
    int moves = 0;
    int seconds = 0;
    if (details != null && details.isNotEmpty) {
      try {
        final movesMatch = RegExp(r'"moves":\s*(\d+)').firstMatch(details);
        final secondsMatch = RegExp(r'"seconds":\s*(\d+)').firstMatch(details);
        if (movesMatch != null) moves = int.parse(movesMatch.group(1)!);
        if (secondsMatch != null) seconds = int.parse(secondsMatch.group(1)!);
      } catch (_) {}
    }

    // Yıldız hesapla
    int starCount;
    if (wrongCount == 0) {
      starCount = 3;
    } else if (wrongCount <= 2) {
      starCount = 2;
    } else if (wrongCount <= 5) {
      starCount = 1;
    } else {
      starCount = 0;
    }

    // Süre formatla
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // Parse date
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      date = DateTime.now();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade400, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım
              Row(
                children: [
                  const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bul Bakalım',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Yıldızlar
                  Row(
                    children: List.generate(
                      3,
                      (i) => Icon(
                        i < starCount ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Orta kısım
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skor
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skor',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Süre
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Süre',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  // Hamle/Hata
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$moves hamle',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$wrongCount hata',
                        style: TextStyle(
                          color: wrongCount == 0
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Alt kısım: Tarih
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
