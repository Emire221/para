import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/glass_container.dart';
import '../services/data_service.dart';
import 'video_player_screen.dart';
import 'test_list_screen.dart';
import 'flashcard_set_selection_screen.dart';
import '../core/providers/user_provider.dart';

class TopicSelectionScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String lessonName;
  final Color lessonColor;
  final String mode;

  const TopicSelectionScreen({
    super.key,
    required this.lessonId,
    required this.lessonName,
    required this.lessonColor,
    this.mode = 'all',
  });

  @override
  ConsumerState<TopicSelectionScreen> createState() =>
      _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends ConsumerState<TopicSelectionScreen> {
  final DataService _dataService = DataService();
  List<dynamic> _topics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final userProfile = ref.read(userProfileProvider);
    final userGrade = userProfile.value?['grade'] ?? '3. Sınıf';

    final topics = await _dataService.getTopics(userGrade, widget.lessonId);
    setState(() {
      _topics = topics;
    });
  }

  Future<void> _openVideo(String topicId, String topicName) async {
    final userProfile = ref.read(userProfileProvider);
    final userGrade = userProfile.value?['grade'] ?? '3. Sınıf';
    final videoData = await _dataService.getTopicVideo(userGrade, topicId);

    if (videoData != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoUrl: videoData['youtubeURL'],
            videoTitle: videoData['videoBaslik'],
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Video bulunamadı')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.lessonName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.lessonColor.withValues(alpha: 0.8),
              widget.lessonColor,
            ],
          ),
        ),
        child: SafeArea(
          child: _topics.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    final topic = _topics[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${topic['sira']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    topic['konuAdi'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (widget.mode == 'video' ||
                                    widget.mode == 'all')
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openVideo(
                                        topic['konuID'],
                                        topic['konuAdi'],
                                      ),
                                      icon: const Icon(
                                        Icons.play_circle_outline,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'İzle',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.2),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (widget.mode == 'video' ||
                                    widget.mode == 'all')
                                  const SizedBox(width: 6),
                                if (widget.mode == 'test' ||
                                    widget.mode == 'all')
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TestListScreen(
                                                  topicId: topic['konuID'],
                                                  topicName: topic['konuAdi'],
                                                  lessonName: widget.lessonName,
                                                  color: widget.lessonColor,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.quiz, size: 18),
                                      label: const Text(
                                        'Test',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: widget.lessonColor,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (widget.mode == 'test' ||
                                    widget.mode == 'all')
                                  const SizedBox(width: 6),
                                if (widget.mode == 'flashcard' ||
                                    widget.mode == 'all')
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FlashcardSetSelectionScreen(
                                                  topicId: topic['konuID'],
                                                  topicName: topic['konuAdi'],
                                                  lessonName: widget.lessonName,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.style, size: 18),
                                      label: const Text(
                                        'Kart',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange
                                            .withValues(alpha: 0.9),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
