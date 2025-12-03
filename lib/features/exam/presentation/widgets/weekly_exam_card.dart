import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/weekly_exam_service.dart';
import '../../domain/models/weekly_exam.dart';
import '../screens/weekly_exam_screen.dart';
import '../screens/weekly_exam_result_screen.dart';

/// Haftalık sınav widget'ı - Dersler ekranında gösterilir
class WeeklyExamCard extends ConsumerStatefulWidget {
  const WeeklyExamCard({super.key});

  @override
  ConsumerState<WeeklyExamCard> createState() => _WeeklyExamCardState();
}

class _WeeklyExamCardState extends ConsumerState<WeeklyExamCard> {
  final WeeklyExamService _examService = WeeklyExamService();

  WeeklyExam? _exam;
  ExamRoomStatus _status = ExamRoomStatus.beklemede;
  bool _hasCompleted = false;
  WeeklyExamResult? _userResult;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadExamData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStatus();
    });
  }

  Future<void> _loadExamData() async {
    final exam = await _examService.loadWeeklyExam();
    if (exam != null && mounted) {
      final hasCompleted = await _examService.hasUserCompletedExam(exam.examId);
      final result = hasCompleted
          ? await _examService.getUserExamResult(exam.examId)
          : null;

      setState(() {
        _exam = exam;
        _hasCompleted = hasCompleted;
        _userResult = result;
      });
      _updateStatus();
    }
  }

  void _updateStatus() {
    if (_exam == null) return;

    final weekStart = _examService.getThisWeekMonday();
    final newStatus = _examService.getExamStatus(weekStart);
    final remaining = _examService.getTimeRemaining(weekStart, newStatus);

    if (mounted) {
      setState(() {
        _status = newStatus;
        _remaining = remaining;
      });
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00:00';

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return '$days gün ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_exam == null) {
      return const SizedBox.shrink(); // Sınav yoksa gösterme
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: _getGradient(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getMainColor().withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onCardTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst kısım - Başlık ve ikon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Türkiye Geneli Deneme',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _examService.generateRoomName(
                              _examService.getThisWeekMonday(),
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Durum badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _status.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Motivasyon mesajı
                Text(
                  _getMotivationMessage(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 16),

                // Alt kısım - Geri sayım ve buton
                Row(
                  children: [
                    // Geri sayım
                    if (_status != ExamRoomStatus.sonuclanmis) ...[
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_remaining),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Aksiyon butonu
                    ElevatedButton(
                      onPressed: _onCardTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _getMainColor(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getButtonText(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(_getButtonIcon(), size: 18),
                        ],
                      ),
                    ),
                  ],
                ),

                // Tamamlandıysa puan göster
                if (_hasCompleted && _userResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Doğru',
                          _userResult!.dogru?.toString() ?? '-',
                          Colors.green,
                        ),
                        _buildStatItem(
                          'Yanlış',
                          _userResult!.yanlis?.toString() ?? '-',
                          Colors.red,
                        ),
                        _buildStatItem(
                          'Boş',
                          _userResult!.bos?.toString() ?? '-',
                          Colors.grey,
                        ),
                        _buildStatItem(
                          'Puan',
                          _userResult!.puan?.toString() ?? '-',
                          Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  LinearGradient _getGradient() {
    switch (_status) {
      case ExamRoomStatus.beklemede:
        return LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ExamRoomStatus.aktif:
        return LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ExamRoomStatus.kapali:
        return LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ExamRoomStatus.sonuclanmis:
        return LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getMainColor() {
    switch (_status) {
      case ExamRoomStatus.beklemede:
        return Colors.blue.shade600;
      case ExamRoomStatus.aktif:
        return Colors.green.shade600;
      case ExamRoomStatus.kapali:
        return Colors.orange.shade600;
      case ExamRoomStatus.sonuclanmis:
        return Colors.purple.shade600;
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case ExamRoomStatus.beklemede:
        return Icons.schedule;
      case ExamRoomStatus.aktif:
        return Icons.play_circle_filled;
      case ExamRoomStatus.kapali:
        return Icons.hourglass_top;
      case ExamRoomStatus.sonuclanmis:
        return Icons.emoji_events;
    }
  }

  String _getMotivationMessage() {
    if (_hasCompleted) {
      if (_status == ExamRoomStatus.sonuclanmis) {
        return 'Tüm Türkiye\'de kaçıncı sıradasın, baktın mı? 🏆';
      }
      return 'Sınavı tamamladın! Sonuçlar Pazar 20:00\'da açıklanacak. ⏳';
    }
    return _status.motivationMessage;
  }

  String _getButtonText() {
    if (_hasCompleted) {
      if (_status == ExamRoomStatus.sonuclanmis) {
        return 'Sonuçları Gör';
      }
      return 'Cevaplarım';
    }

    switch (_status) {
      case ExamRoomStatus.beklemede:
        return 'Yakında';
      case ExamRoomStatus.aktif:
        return 'Sınava Gir';
      case ExamRoomStatus.kapali:
        return 'Kaçırdın 😔';
      case ExamRoomStatus.sonuclanmis:
        return 'Sonuçlar';
    }
  }

  IconData _getButtonIcon() {
    if (_hasCompleted) {
      return Icons.visibility;
    }

    switch (_status) {
      case ExamRoomStatus.beklemede:
        return Icons.lock_clock;
      case ExamRoomStatus.aktif:
        return Icons.arrow_forward;
      case ExamRoomStatus.kapali:
        return Icons.lock;
      case ExamRoomStatus.sonuclanmis:
        return Icons.leaderboard;
    }
  }

  void _onCardTap() {
    if (_exam == null) return;

    // Sonuçlar açıklandıysa sonuç ekranına git
    if (_status == ExamRoomStatus.sonuclanmis) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WeeklyExamResultScreen(exam: _exam!, result: _userResult),
        ),
      );
      return;
    }

    // Sınav aktif ve kullanıcı henüz çözmemişse sınav ekranına git
    if (_status == ExamRoomStatus.aktif && !_hasCompleted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WeeklyExamScreen(exam: _exam!)),
      ).then((_) {
        // Sınavdan dönünce verileri yenile
        _loadExamData();
      });
      return;
    }

    // Beklemede veya kapalı ise bilgi göster
    if (_status == ExamRoomStatus.beklemede) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sınav henüz başlamadı. Pazartesi başlayacak!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (_status == ExamRoomStatus.kapali && !_hasCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu haftaki sınavı kaçırdın 😔 Gelecek hafta bekleriz!',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (_hasCompleted && _status != ExamRoomStatus.sonuclanmis) {
      // Sınavı çözdü ama sonuçlar henüz açıklanmadı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sonuçlar Pazar 20:00\'da açıklanacak!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
