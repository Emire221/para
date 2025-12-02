import 'package:flutter/material.dart';
import '../../domain/entities/bot.dart';
import '../../domain/entities/arena_question.dart';
import '../../domain/controllers/bot_controller.dart';

/// Arena düello ekranı
class ArenaScreen extends StatefulWidget {
  final Bot selectedBot;
  final List<ArenaQuestion>? questions;

  const ArenaScreen({super.key, required this.selectedBot, this.questions});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late Bot _selectedBot;
  late BotController _botController;

  int _playerScore = 0;
  int _botScore = 0;
  final int _targetScore = 5;

  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _isGameActive = false;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    _selectedBot = widget.selectedBot;
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // Parametreden gelen soruları kullan
    if (widget.questions != null && widget.questions!.isNotEmpty) {
      setState(() {
        _questions = widget.questions!.map((q) => q.toMap()).toList()
          ..shuffle();
      });
      return;
    }

    // Fallback: Mock sorular (parametrede soru yoksa)
    await Future.delayed(const Duration(milliseconds: 300));

    // Sabit mock sorular
    final mockQuestions = [
      {
        'questionText': 'Türkiye\'nin başkenti neresidir?',
        'optionA': 'İstanbul',
        'optionB': 'Ankara',
        'optionC': 'İzmir',
        'optionD': 'Bursa',
        'correctAnswer': 'Ankara',
      },
      {
        'questionText': '3 x 4 kaçtır?',
        'optionA': '7',
        'optionB': '10',
        'optionC': '12',
        'optionD': '15',
        'correctAnswer': '12',
      },
      {
        'questionText': 'Dünyanın en büyük okyanusu hangisidir?',
        'optionA': 'Atlas Okyanusu',
        'optionB': 'Büyük Okyanus',
        'optionC': 'Hint Okyanusu',
        'optionD': 'Kuzey Buz Denizi',
        'correctAnswer': 'Büyük Okyanus',
      },
      {
        'questionText': '100 + 50 işleminin sonucu kaçtır?',
        'optionA': '140',
        'optionB': '150',
        'optionC': '160',
        'optionD': '170',
        'correctAnswer': '150',
      },
      {
        'questionText': 'Hangi gezegen Güneş\'e en yakındır?',
        'optionA': 'Venüs',
        'optionB': 'Mars',
        'optionC': 'Merkür',
        'optionD': 'Dünya',
        'correctAnswer': 'Merkür',
      },
      {
        'questionText': 'Bir üçgenin kaç kenarı vardır?',
        'optionA': '2',
        'optionB': '3',
        'optionC': '4',
        'optionD': '5',
        'correctAnswer': '3',
      },
      {
        'questionText': 'Hangi hayvan memeli değildir?',
        'optionA': 'Balina',
        'optionB': 'Yunus',
        'optionC': 'Köpekbalığı',
        'optionD': 'Fok',
        'correctAnswer': 'Köpekbalığı',
      },
      {
        'questionText': '24 ÷ 6 işleminin sonucu kaçtır?',
        'optionA': '3',
        'optionB': '4',
        'optionC': '5',
        'optionD': '6',
        'correctAnswer': '4',
      },
      {
        'questionText': 'Hangi renk birincil renk değildir?',
        'optionA': 'Kırmızı',
        'optionB': 'Mavi',
        'optionC': 'Yeşil',
        'optionD': 'Sarı',
        'correctAnswer': 'Yeşil',
      },
      {
        'questionText': 'Türkiye\'nin en uzun nehri hangisidir?',
        'optionA': 'Sakarya',
        'optionB': 'Kızılırmak',
        'optionC': 'Fırat',
        'optionD': 'Dicle',
        'correctAnswer': 'Kızılırmak',
      },
      {
        'questionText': '7 x 8 işleminin sonucu kaçtır?',
        'optionA': '54',
        'optionB': '56',
        'optionC': '58',
        'optionD': '60',
        'correctAnswer': '56',
      },
      {
        'questionText': 'Bir yılda kaç ay vardır?',
        'optionA': '10',
        'optionB': '11',
        'optionC': '12',
        'optionD': '13',
        'correctAnswer': '12',
      },
      {
        'questionText': 'Hangi element\'in sembolü H\'dir?',
        'optionA': 'Helyum',
        'optionB': 'Hidrojen',
        'optionC': 'Hafniyum',
        'optionD': 'Holmiyum',
        'correctAnswer': 'Hidrojen',
      },
      {
        'questionText': '15 - 7 işleminin sonucu kaçtır?',
        'optionA': '6',
        'optionB': '7',
        'optionC': '8',
        'optionD': '9',
        'correctAnswer': '8',
      },
      {
        'questionText': 'Hangi mevsim en sıcaktır?',
        'optionA': 'İlkbahar',
        'optionB': 'Yaz',
        'optionC': 'Sonbahar',
        'optionD': 'Kış',
        'correctAnswer': 'Yaz',
      },
      {
        'questionText': 'Bir dikdörtgenin kaç köşesi vardır?',
        'optionA': '2',
        'optionB': '3',
        'optionC': '4',
        'optionD': '5',
        'correctAnswer': '4',
      },
      {
        'questionText': '9 + 9 işleminin sonucu kaçtır?',
        'optionA': '16',
        'optionB': '17',
        'optionC': '18',
        'optionD': '19',
        'correctAnswer': '18',
      },
      {
        'questionText': 'Hangi organ kanı pompalar?',
        'optionA': 'Akciğer',
        'optionB': 'Karaciğer',
        'optionC': 'Kalp',
        'optionD': 'Böbrek',
        'correctAnswer': 'Kalp',
      },
      {
        'questionText': '50 ÷ 5 işleminin sonucu kaçtır?',
        'optionA': '8',
        'optionB': '9',
        'optionC': '10',
        'optionD': '11',
        'correctAnswer': '10',
      },
      {
        'questionText': 'Hangi gezegen halkalara sahiptir?',
        'optionA': 'Mars',
        'optionB': 'Jüpiter',
        'optionC': 'Satürn',
        'optionD': 'Neptün',
        'correctAnswer': 'Satürn',
      },
    ];

    if (mounted) {
      setState(() {
        _questions = List.from(mockQuestions)..shuffle();
      });
    }
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _playerScore = 0;
      _botScore = 0;
      _currentQuestionIndex = 0;
      _selectedAnswer = null;
      _gameEnded = false;
    });

    _botController = BotController(
      targetScore: _targetScore,
      speedRange: _selectedBot.speedRange,
      onScoreUpdate: (score) {
        setState(() {
          _botScore = score;
        });
        _checkWinCondition();
      },
      onWin: () {
        _endGame(false);
      },
    );

    _botController.start();
  }

  void _answerQuestion(String answer) {
    if (!_isGameActive || _gameEnded) return;

    final correctAnswer =
        _questions[_currentQuestionIndex]['correctAnswer'] as String;
    final isCorrect = answer == correctAnswer;

    setState(() {
      _selectedAnswer = answer;
    });

    if (isCorrect) {
      setState(() {
        _playerScore++;
      });
      _checkWinCondition();
    }

    // Bir sonraki soruya geç
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswer = null;
        });
      }
    });
  }

  void _checkWinCondition() {
    if (_playerScore >= _targetScore) {
      _endGame(true);
    } else if (_botScore >= _targetScore) {
      _endGame(false);
    }
  }

  void _endGame(bool playerWon) {
    setState(() {
      _gameEnded = true;
      _isGameActive = false;
    });
    _botController.stop();

    Future.delayed(const Duration(milliseconds: 500), () {
      _showResultDialog(playerWon);
    });
  }

  void _showResultDialog(bool playerWon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          playerWon ? '🎉 Kazandın!' : '😔 Kaybettin',
          style: const TextStyle(fontSize: 24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              playerWon
                  ? '${_selectedBot.name} botunu yendin!'
                  : '${_selectedBot.name} seni geçti!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text(
                      'Sen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('$_playerScore', style: const TextStyle(fontSize: 32)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      _selectedBot.avatar,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text('$_botScore', style: const TextStyle(fontSize: 32)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Çıkış'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _botController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arena Düello')),
      body: _questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildScoreBoard(),
                if (!_isGameActive && !_gameEnded)
                  Expanded(
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 24,
                          ),
                        ),
                        child: const Text(
                          'Başla!',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                if (_isGameActive && !_gameEnded)
                  Expanded(
                    child: SingleChildScrollView(child: _buildQuestionArea()),
                  ),
              ],
            ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade300, Colors.blue.shade300],
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildPlayerProgress()),
          const SizedBox(width: 16),
          const Text(
            'VS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildBotProgress()),
        ],
      ),
    );
  }

  Widget _buildPlayerProgress() {
    return Column(
      children: [
        const Text(
          'Sen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _playerScore / _targetScore,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          minHeight: 20,
        ),
        const SizedBox(height: 4),
        Text(
          '$_playerScore / $_targetScore',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildBotProgress() {
    return Column(
      children: [
        Text(_selectedBot.avatar, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _botScore / _targetScore,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
          minHeight: 20,
        ),
        const SizedBox(height: 4),
        Text(
          '$_botScore / $_targetScore',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildQuestionArea() {
    if (_currentQuestionIndex >= _questions.length) {
      return const Center(child: Text('Sorular bitti!'));
    }

    final question = _questions[_currentQuestionIndex];
    final questionText = question['questionText'] as String;
    final options = [
      question['optionA'],
      question['optionB'],
      question['optionC'],
      question['optionD'],
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Soru ${_currentQuestionIndex + 1}',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              questionText,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ...options.map((option) => _buildOptionButton(option as String)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option) {
    final isSelected = _selectedAnswer == option;
    final correctAnswer =
        _questions[_currentQuestionIndex]['correctAnswer'] as String;
    final isCorrect = option == correctAnswer;

    Color? backgroundColor;
    if (_selectedAnswer != null) {
      if (isSelected) {
        backgroundColor = isCorrect ? Colors.green : Colors.red;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: _selectedAnswer == null
            ? () => _answerQuestion(option)
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: backgroundColor,
        ),
        child: Text(option, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
