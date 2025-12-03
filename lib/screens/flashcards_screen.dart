import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/glass_container.dart';
import '../providers/repository_providers.dart';
import '../models/flashcard_model.dart';
import '../core/providers/user_provider.dart';
import 'result_screen.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  final String? topicId;
  final String? topicName;
  final String? lessonName;
  final List<FlashcardModel>? initialCards;

  const FlashcardsScreen({
    super.key,
    this.topicId,
    this.topicName,
    this.lessonName,
    this.initialCards,
  });

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  List<FlashcardModel> _allCards = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isProcessing =
      false; // Kaydırma işlemi devam ederken yeni kaydırmayı engelle

  // Feedback state
  bool _showFeedback = false;
  String _feedbackMessage = '';
  bool _isCorrect = false;

  // Motivasyon mesajları
  List<String> _dogruMesajlari = [];
  List<String> _yanlisMesajlari = [];

  // Skor değişkenleri
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _resultsSaved = false;

  @override
  void initState() {
    super.initState();
    _loadMotivationMessages();
    _loadCards();
  }

  Future<void> _loadMotivationMessages() async {
    try {
      // dogru.json yükle
      final dogruJson = await rootBundle.loadString('assets/json/dogru.json');
      final dogruData = json.decode(dogruJson);
      _dogruMesajlari = List<String>.from(dogruData['mesajlar']);

      // yanlis.json yükle
      final yanlisJson = await rootBundle.loadString('assets/json/yanlis.json');
      final yanlisData = json.decode(yanlisJson);
      _yanlisMesajlari = List<String>.from(yanlisData['mesajlar']);
    } catch (e) {
      debugPrint('Motivasyon mesajları yükleme hatası: $e');
      // Fallback mesajlar
      _dogruMesajlari = ['Harikasın! 🎉', 'Süper! ⭐', 'Mükemmel! 🏆'];
      _yanlisMesajlari = ['Bir Dahakine! 💫', 'Pes Etme! 🚀', 'Devam Et! 💪'];
    }
  }

  Future<void> _loadCards() async {
    // Eğer initialCards verilmişse, doğrudan kullan
    if (widget.initialCards != null && widget.initialCards!.isNotEmpty) {
      setState(() {
        _allCards = widget.initialCards!;
        _isLoading = false;
      });
      return;
    }

    // Değilse, repository'den çek
    if (widget.topicId != null && widget.lessonName != null) {
      try {
        final userProfile = ref.read(userProfileProvider);
        final userGrade = userProfile.value?['grade'] ?? '3. Sınıf';
        final repository = ref.read(flashcardRepositoryProvider);

        final cardSets = await repository.getFlashcards(
          userGrade,
          widget.lessonName!,
          widget.topicId!,
        );

        // Tüm setlerden gelen kartları birleştir
        List<FlashcardModel> flatCards = [];
        for (var set in cardSets) {
          flatCards.addAll(set.kartlar);
        }

        if (mounted) {
          setState(() {
            _allCards = flatCards;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Kart yükleme hatası: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSwipe(DismissDirection direction) async {
    if (_currentIndex >= _allCards.length || _isProcessing) return;

    _isProcessing = true;
    final currentCard = _allCards[_currentIndex];

    // Kullanıcının cevabı
    final userSaidTrue =
        direction == DismissDirection.startToEnd; // Sağa kaydırma = Doğru
    final userSaidFalse =
        direction == DismissDirection.endToStart; // Sola kaydırma = Yanlış

    // Kontrol mantığı
    bool isCorrectAnswer = false;
    if (userSaidTrue && currentCard.dogruMu == true) {
      isCorrectAnswer = true; // Kullanıcı DOĞRU dedi ve kart DOĞRU
    } else if (userSaidFalse && currentCard.dogruMu == false) {
      isCorrectAnswer = true; // Kullanıcı YANLIŞ dedi ve kart YANLIŞ
    }

    // Skor güncelle
    if (isCorrectAnswer) {
      _correctCount++;
    } else {
      _wrongCount++;
    }

    // Rastgele mesaj seç
    String message;
    if (isCorrectAnswer) {
      message =
          _dogruMesajlari[DateTime.now().millisecondsSinceEpoch %
              _dogruMesajlari.length];
    } else {
      message =
          _yanlisMesajlari[DateTime.now().millisecondsSinceEpoch %
              _yanlisMesajlari.length];
    }

    // Feedback göster
    setState(() {
      _showFeedback = true;
      _feedbackMessage = message;
      _isCorrect = isCorrectAnswer;
    });

    // 1 saniye bekle
    await Future.delayed(const Duration(seconds: 1));

    // Feedback gizle ve sonraki karta geç
    if (mounted) {
      final isLastCard = _currentIndex >= _allCards.length - 1;

      setState(() {
        _showFeedback = false;
        _currentIndex++;
        _isProcessing = false;
      });

      // Eğer son kartsa ResultScreen'e yönlendir
      if (isLastCard && !_resultsSaved) {
        _resultsSaved = true; // Tekrar yönlendirmeyi engelle
        debugPrint('Son kart tamamlandı, ResultScreen\'e yönlendiriliyor...');
        debugPrint(
          'Skor: ${_correctCount * 10}, Doğru: $_correctCount, Yanlış: $_wrongCount',
        );

        // mounted kontrolü - async işlem sonrası context güvenli kullanım
        if (!mounted) return;

        // ResultScreen'e yönlendir - kayıt orada yapılacak
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              score: _correctCount * 10, // Her doğru 10 puan
              correctCount: _correctCount,
              wrongCount: _wrongCount,
              topicId: widget.topicId ?? '',
              topicName: widget.topicName ?? 'Bilgi Kartları',
              answeredQuestions: const [], // Flashcards'ta cevap anahtarı yok
              isFlashcard: true, // Flashcard modu olduğunu belirt
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.topicName ?? 'Doğru mu? Yanlış mı?',
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
            colors: [Color(0xFF833ab4), Color(0xFFfd1d1d), Color(0xFFfcb045)],
          ),
        ),
        child: Stack(
          children: [
            // Ana içerik
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _allCards.isEmpty
                  ? const Text(
                      'Bu konuda henüz kart bulunmuyor.',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    )
                  : _buildCardWithInstructions(),
            ),

            // Feedback Overlay
            if (_showFeedback)
              AnimatedOpacity(
                opacity: _showFeedback ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: _isCorrect
                      ? Colors.green.withValues(alpha: 0.95)
                      : Colors.red.withValues(alpha: 0.95),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isCorrect ? Icons.check_circle : Icons.cancel,
                          color: Colors.white,
                          size: 120,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _feedbackMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWithInstructions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Yönlendirme metni
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Text(
            'Bu bilgi doğru mu yanlış mı?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Kart
        _currentIndex < _allCards.length
            ? Dismissible(
                key: ValueKey(
                  'flashcard_${_allCards[_currentIndex].kartID}_$_currentIndex',
                ),
                confirmDismiss: (direction) async {
                  // Feedback gösteriliyorsa veya işlem devam ediyorsa kaydırmayı engelle
                  if (_showFeedback || _isProcessing) {
                    return false;
                  }
                  // Kaydırma işlemini başlat
                  _handleSwipe(direction);
                  // Widget'i listeden kaldırma, biz manuel yönetiyoruz
                  return false;
                },
                background: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 80),
                          SizedBox(height: 8),
                          Text(
                            'DOĞRU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                secondaryBackground: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.white, size: 80),
                          SizedBox(height: 8),
                          Text(
                            'YANLIŞ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final screenHeight = MediaQuery.of(context).size.height;
                    // Ekran boyutuna göre kart boyutunu hesapla
                    final cardWidth = screenWidth * 0.85 > 400
                        ? 400.0
                        : screenWidth * 0.85;
                    final cardHeight = screenHeight * 0.55 > 500
                        ? 500.0
                        : screenHeight * 0.55;

                    return SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: GlassContainer(
                        color: Colors.white,
                        opacity: 0.95,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.quiz,
                                  size: 50,
                                  color: Color(0xFF833ab4),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _allCards[_currentIndex].onyuz,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  'Kart ${_currentIndex + 1}/${_allCards.length}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            : const SizedBox.shrink(), // Kartlar bittiğinde boş widget
        // Yönlendirme ikonları
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Icon(
                    Icons.arrow_back,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sola kaydır:\nYANLIŞ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              Column(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sağa kaydır:\nDOĞRU',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
