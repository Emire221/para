import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../widgets/glass_container.dart';
import 'topic_selection_screen.dart';

class LessonSelectionScreen extends StatefulWidget {
  final String mode; // 'test', 'video', 'flashcard'

  const LessonSelectionScreen({super.key, this.mode = 'all'});

  @override
  State<LessonSelectionScreen> createState() => _LessonSelectionScreenState();
}

class _LessonSelectionScreenState extends State<LessonSelectionScreen> {
  List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db.query('Dersler');

      setState(() {
        _lessons = maps;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Dersler yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Ders Seçimi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf12711), Color(0xFFf5af19)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hedef: 100 Puan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.flag, color: Colors.white),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _lessons.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return _buildLessonCard(
                            context,
                            lesson['dersAdi'],
                            _getIcon(lesson['ikon']),
                            Color(int.parse(lesson['renk'])),
                            lesson['dersID'],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'book':
        return Icons.book;
      case 'calculate':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'public':
        return Icons.public;
      case 'language':
        return Icons.language;
      case 'history_edu':
        return Icons.history_edu;
      default:
        return Icons.class_;
    }
  }

  Widget _buildLessonCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String lessonId,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicSelectionScreen(
              lessonId: lessonId,
              lessonName: title,
              lessonColor: color,
              mode: widget.mode,
            ),
          ),
        );
      },
      child: GlassContainer(
        color: color.withValues(alpha: 0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

