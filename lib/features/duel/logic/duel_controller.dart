import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bot_logic_controller.dart' show BotLogicController, DuelResult;
import '../domain/entities/bot_profile.dart';
import '../domain/entities/duel_entities.dart';
import '../data/duel_repository.dart';

// Re-export DuelResult for consumers
export '../domain/bot_logic_controller.dart' show DuelResult;

/// Düello state'i
class DuelState {
  final DuelStatus status;
  final DuelGameType? gameType;
  final BotProfile? botProfile;
  final int userScore;
  final int botScore;
  final int currentQuestionIndex;
  final int totalQuestions;
  final bool? userAnsweredCorrectly;
  final bool? botAnsweredCorrectly;
  final bool isUserTurn;
  final bool isBotAnswering;
  final int? userSelectedIndex;
  final int? botSelectedIndex;
  final String? errorMessage;

  const DuelState({
    this.status = DuelStatus.idle,
    this.gameType,
    this.botProfile,
    this.userScore = 0,
    this.botScore = 0,
    this.currentQuestionIndex = 0,
    this.totalQuestions = 5,
    this.userAnsweredCorrectly,
    this.botAnsweredCorrectly,
    this.isUserTurn = true,
    this.isBotAnswering = false,
    this.userSelectedIndex,
    this.botSelectedIndex,
    this.errorMessage,
  });

  DuelState copyWith({
    DuelStatus? status,
    DuelGameType? gameType,
    BotProfile? botProfile,
    int? userScore,
    int? botScore,
    int? currentQuestionIndex,
    int? totalQuestions,
    bool? userAnsweredCorrectly,
    bool? botAnsweredCorrectly,
    bool? isUserTurn,
    bool? isBotAnswering,
    int? userSelectedIndex,
    int? botSelectedIndex,
    String? errorMessage,
    bool clearUserAnswer = false,
    bool clearBotAnswer = false,
    bool clearSelections = false,
  }) {
    return DuelState(
      status: status ?? this.status,
      gameType: gameType ?? this.gameType,
      botProfile: botProfile ?? this.botProfile,
      userScore: userScore ?? this.userScore,
      botScore: botScore ?? this.botScore,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      userAnsweredCorrectly: clearUserAnswer ? null : (userAnsweredCorrectly ?? this.userAnsweredCorrectly),
      botAnsweredCorrectly: clearBotAnswer ? null : (botAnsweredCorrectly ?? this.botAnsweredCorrectly),
      isUserTurn: isUserTurn ?? this.isUserTurn,
      isBotAnswering: isBotAnswering ?? this.isBotAnswering,
      userSelectedIndex: clearSelections ? null : (userSelectedIndex ?? this.userSelectedIndex),
      botSelectedIndex: clearSelections ? null : (botSelectedIndex ?? this.botSelectedIndex),
      errorMessage: errorMessage,
    );
  }
}

/// Düello controller provider
final duelControllerProvider = StateNotifierProvider<DuelController, DuelState>((ref) {
  return DuelController();
});

/// Düello controller - oyun mantığını yönetir
class DuelController extends StateNotifier<DuelState> {
  DuelController() : super(const DuelState());

  final DuelRepository _repository = DuelRepository();
  final BotLogicController _botLogic = BotLogicController();
  
  List<DuelQuestion> _testQuestions = [];
  List<DuelFillBlankQuestion> _fillBlankQuestions = [];

  // Getters
  List<DuelQuestion> get testQuestions => _testQuestions;
  List<DuelFillBlankQuestion> get fillBlankQuestions => _fillBlankQuestions;
  DuelQuestion? get currentTestQuestion => 
      state.currentQuestionIndex < _testQuestions.length 
          ? _testQuestions[state.currentQuestionIndex] 
          : null;
  DuelFillBlankQuestion? get currentFillBlankQuestion =>
      state.currentQuestionIndex < _fillBlankQuestions.length
          ? _fillBlankQuestions[state.currentQuestionIndex]
          : null;

  /// Oyun türünü seç ve başlat
  Future<void> selectGameType(DuelGameType type) async {
    state = state.copyWith(
      gameType: type,
      status: DuelStatus.searching,
      botProfile: BotProfile.random(),
    );

    if (kDebugMode) debugPrint('🎮 Oyun türü seçildi: $type');
  }

  /// Soruları yükle
  Future<bool> loadQuestions() async {
    try {
      if (state.gameType == DuelGameType.test) {
        _testQuestions = await _repository.getTestQuestions(count: 5);
        if (kDebugMode) debugPrint('📚 ${_testQuestions.length} test sorusu yüklendi');
      } else {
        _fillBlankQuestions = await _repository.getFillBlankQuestions(count: 5);
        if (kDebugMode) debugPrint('📚 ${_fillBlankQuestions.length} cümle tamamlama sorusu yüklendi');
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Soru yükleme hatası: $e');
      state = state.copyWith(errorMessage: 'Sorular yüklenemedi');
      return false;
    }
  }

  /// Rakip bulundu - oyuna başla
  void startGame() {
    _botLogic.reset();
    state = state.copyWith(
      status: DuelStatus.playing,
      userScore: 0,
      botScore: 0,
      currentQuestionIndex: 0,
      isUserTurn: true,
      clearUserAnswer: true,
      clearBotAnswer: true,
      clearSelections: true,
    );
    
    // Bot cevabını başlat
    _startBotAnswering();
  }

  /// Bot cevaplama sürecini başlat
  void _startBotAnswering() {
    if (state.status != DuelStatus.playing) return;
    
    state = state.copyWith(isBotAnswering: true);
    
    // Bot rastgele süre sonra cevap verecek
    final delay = _botLogic.getBotAnswerDelay();
    
    Future.delayed(delay, () {
      if (state.status == DuelStatus.playing && state.isBotAnswering) {
        _botAnswer();
      }
    });
  }

  /// Bot cevap verir
  void _botAnswer() {
    if (state.status != DuelStatus.playing) return;

    final shouldBeCorrect = _botLogic.shouldBotAnswerCorrectly();
    
    int botSelectedIndex;
    int correctIndex;
    
    if (state.gameType == DuelGameType.test) {
      final question = currentTestQuestion;
      if (question == null) return;
      correctIndex = question.correctIndex;
    } else {
      final question = currentFillBlankQuestion;
      if (question == null) return;
      correctIndex = question.options.indexOf(question.answer);
    }

    if (shouldBeCorrect) {
      botSelectedIndex = correctIndex;
    } else {
      // Yanlış bir seçenek seç
      final optionCount = state.gameType == DuelGameType.test 
          ? currentTestQuestion!.options.length 
          : currentFillBlankQuestion!.options.length;
      do {
        botSelectedIndex = DateTime.now().microsecond % optionCount;
      } while (botSelectedIndex == correctIndex);
    }

    _botLogic.updateBotScore(shouldBeCorrect);

    state = state.copyWith(
      botAnsweredCorrectly: shouldBeCorrect,
      botSelectedIndex: botSelectedIndex,
      botScore: _botLogic.botScore,
      isBotAnswering: false,
    );

    if (kDebugMode) {
      debugPrint('🤖 Bot cevapladı: ${shouldBeCorrect ? "DOĞRU" : "YANLIŞ"} (Skor: ${_botLogic.botScore})');
    }

    // Eğer kullanıcı da cevap verdiyse sonraki soruya geç
    _checkAndProceed();
  }

  /// Kullanıcı cevap verir
  void userAnswer(int selectedIndex, bool isCorrect) {
    if (state.status != DuelStatus.playing || state.userAnsweredCorrectly != null) return;

    _botLogic.updateUserScore(isCorrect);

    state = state.copyWith(
      userAnsweredCorrectly: isCorrect,
      userSelectedIndex: selectedIndex,
      userScore: _botLogic.userScore,
    );

    if (kDebugMode) {
      debugPrint('👤 Kullanıcı cevapladı: ${isCorrect ? "DOĞRU" : "YANLIŞ"} (Skor: ${_botLogic.userScore})');
    }

    // Eğer bot da cevap verdiyse sonraki soruya geç
    _checkAndProceed();
  }

  /// Her iki taraf da cevapladıysa sonraki soruya geç
  void _checkAndProceed() {
    if (state.userAnsweredCorrectly != null && state.botAnsweredCorrectly != null) {
      // 1.5 saniye bekle ve sonraki soruya geç
      Future.delayed(const Duration(milliseconds: 1500), () {
        _nextQuestion();
      });
    }
  }

  /// Sonraki soruya geç
  void _nextQuestion() {
    final nextIndex = state.currentQuestionIndex + 1;
    final totalQuestions = state.gameType == DuelGameType.test 
        ? _testQuestions.length 
        : _fillBlankQuestions.length;

    if (nextIndex >= totalQuestions) {
      // Oyun bitti
      state = state.copyWith(
        status: DuelStatus.finished,
        currentQuestionIndex: nextIndex,
      );
      if (kDebugMode) debugPrint('🏁 Oyun bitti! Kullanıcı: ${state.userScore}, Bot: ${state.botScore}');
    } else {
      // Sonraki soru
      _botLogic.nextQuestion();
      state = state.copyWith(
        currentQuestionIndex: nextIndex,
        clearUserAnswer: true,
        clearBotAnswer: true,
        clearSelections: true,
      );
      
      // Bot yeni soru için cevaplama sürecini başlat
      _startBotAnswering();
    }
  }

  /// Sonucu al
  DuelResult getResult() {
    return _botLogic.getResult();
  }

  /// Oyunu sıfırla
  void reset() {
    _botLogic.reset();
    _testQuestions = [];
    _fillBlankQuestions = [];
    state = const DuelState();
  }
}
