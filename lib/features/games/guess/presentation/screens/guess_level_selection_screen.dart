import 'package:flutter/material.dart';
import 'dart:convert';
import '../../domain/entities/guess_level.dart';
import 'guess_game_screen.dart';
import '../../../../../services/database_helper.dart';
import '../../../../../widgets/glass_container.dart';

/// Salla Bakalım - Seviye seçim ekranı
class GuessLevelSelectionScreen extends StatefulWidget {
  const GuessLevelSelectionScreen({super.key});

  @override
  State<GuessLevelSelectionScreen> createState() =>
      _GuessLevelSelectionScreenState();
}

class _GuessLevelSelectionScreenState extends State<GuessLevelSelectionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<GuessLevel>? _levels;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Veritabanından seviyeleri yükle
      final levelsData = await _dbHelper.getGuessLevels();

      if (levelsData.isEmpty) {
        throw Exception('Henüz seviye verisi yüklenmemiş');
      }

      // Map<String, dynamic> listesini GuessLevel listesine dönüştür
      final levels = levelsData.map((data) {
        // questions alanı JSON string olarak kaydedilmiş, parse et
        final levelMap = Map<String, dynamic>.from(data);
        if (levelMap['questions'] is String) {
          levelMap['questions'] = json.decode(levelMap['questions']);
        }
        return GuessLevel.fromJson(levelMap);
      }).toList();

      setState(() {
        _levels = levels;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Seviye yükleme hatası: $e');
      setState(() {
        _errorMessage =
            'Seviyeler yüklenemedi.\n'
            'Lütfen önce veri senkronizasyonunu yapın.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.teal.shade900, Colors.cyan.shade900]
                : [Colors.teal.shade300, Colors.cyan.shade400],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDarkMode),
              Expanded(child: _buildBody(context, isDarkMode)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '📳 Salla Bakalım',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Seviye Seç',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadLevels,
            tooltip: 'Yenile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Seviyeler yükleniyor...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadLevels,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_levels == null || _levels!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vibration, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Henüz seviye bulunmuyor',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Veri senkronizasyonunu yapın',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLevels,
              icon: const Icon(Icons.refresh),
              label: const Text('Yenile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _levels!.length,
      itemBuilder: (context, index) {
        final level = _levels![index];
        return _buildLevelCard(context, isDarkMode, level, index);
      },
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    bool isDarkMode,
    GuessLevel level,
    int index,
  ) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuessGameScreen(level: level),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Seviye numarası
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getLevelColors(level.difficulty),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getLevelColors(
                      level.difficulty,
                    )[0].withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Seviye bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.description,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDifficultyStars(level.difficulty),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          level.difficultyText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${level.questions.length} Soru',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // İlerle ikonu
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyStars(int difficulty) {
    return Row(
      children: List.generate(3, (index) {
        return Icon(
          index < difficulty ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  List<Color> _getLevelColors(int difficulty) {
    switch (difficulty) {
      case 1:
        return [Colors.green.shade400, Colors.green.shade600];
      case 2:
        return [Colors.orange.shade400, Colors.orange.shade600];
      case 3:
        return [Colors.red.shade400, Colors.red.shade600];
      default:
        return [Colors.teal.shade400, Colors.cyan.shade600];
    }
  }
}
