import 'package:flutter/material.dart';
import 'dart:convert';
import '../../domain/entities/fill_blanks_level.dart';
import 'fill_blanks_screen.dart';
import '../../../../../services/firebase_storage_service.dart';
import '../../../../../widgets/glass_container.dart';

/// Seviye seçim ekranı - Cümle Tamamlama oyunu için
class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  List<FillBlanksLevel>? _levels;
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
      // Firebase Storage'dan levels.json dosyasını indir
      final jsonString = await _storageService.downloadGameContent(
        'games/fill_blanks/levels.json',
      );

      if (jsonString == null) {
        throw Exception('Seviye verileri yüklenemedi');
      }

      // JSON parse et
      final jsonData = json.decode(jsonString);
      final levelsList = jsonData['levels'] as List<dynamic>;

      final levels = levelsList
          .map(
            (levelJson) =>
                FillBlanksLevel.fromJson(levelJson as Map<String, dynamic>),
          )
          .toList();

      setState(() {
        _levels = levels;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Seviye yükleme hatası: $e');
      setState(() {
        _errorMessage =
            'Seviyeler yüklenemedi.\n'
            'İnternet bağlantınızı kontrol edin.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seviye Seç'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLevels,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _buildBody(context, isDarkMode),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Seviyeler yükleniyor...'),
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadLevels,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_levels == null || _levels!.isEmpty) {
      return const Center(child: Text('Henüz seviye bulunmuyor'));
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
    FillBlanksLevel level,
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
              builder: (context) => FillBlanksScreen(level: level),
            ),
          );
        },
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDifficultyStars(level.difficulty),
                      const SizedBox(width: 12),
                      Text(
                        '${level.questions.length} Soru',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // İlerle ikonu
            Icon(
              Icons.arrow_forward_ios,
              color: isDarkMode ? Colors.white54 : Colors.black38,
              size: 20,
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
        return [Colors.blue.shade400, Colors.blue.shade600];
    }
  }
}
