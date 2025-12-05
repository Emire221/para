import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_providers.dart';
import '../core/providers/user_provider.dart';
import '../widgets/glass_container.dart';
import 'flashcards_screen.dart';

class FlashcardSetSelectionScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicName;
  final String lessonName;

  const FlashcardSetSelectionScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.lessonName,
  });

  @override
  ConsumerState<FlashcardSetSelectionScreen> createState() =>
      _FlashcardSetSelectionScreenState();
}

class _FlashcardSetSelectionScreenState
    extends ConsumerState<FlashcardSetSelectionScreen> {
  bool _isLoading = true;
  List<dynamic> _flashcardSets = [];

  @override
  void initState() {
    super.initState();
    _loadFlashcardSets();
  }

  Future<void> _loadFlashcardSets() async {
    try {
      final userProfile = ref.read(userProfileProvider);
      final userGrade = userProfile.value?['grade'] ?? '3. Sınıf';
      final repository = ref.read(flashcardRepositoryProvider);

      final sets = await repository.getFlashcards(
        userGrade,
        widget.lessonName,
        widget.topicId,
      );

      if (mounted) {
        setState(() {
          _flashcardSets = sets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Bilgi kartları yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.topicName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10b981), Color(0xFF059669)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _flashcardSets.isEmpty
              ? const Center(
                  child: Text(
                    'Bu konuda henüz bilgi kartı bulunmuyor.',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _flashcardSets.length,
                  itemBuilder: (context, index) {
                    final flashcardSet = _flashcardSets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            flashcardSet.kartAdi,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${flashcardSet.kartlar.length} Kart',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FlashcardsScreen(
                                  topicId: widget.topicId,
                                  topicName: flashcardSet.kartAdi,
                                  initialCards: flashcardSet.kartlar,
                                ),
                              ),
                            );
                          },
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

