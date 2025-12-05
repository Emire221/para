import 'package:flutter/foundation.dart';
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
  bool _isLoading = true;

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
      if (_exam != null && !_isLoading) {
        _updateStatus();
      }
    });
  }

  Future<void> _loadExamData() async {
    setState(() => _isLoading = true);

    try {
      final exam = await _examService.loadWeeklyExam();

      if (exam != null && mounted) {
        // Sınavı yükle - artık hafta kontrolü YAPMIYORUZ
        // Sınav her zaman gösterilecek, sadece durum değişecek
        final hasCompleted = await _examService.hasUserCompletedExam(
          exam.examId,
        );
        final result = hasCompleted
            ? await _examService.getUserExamResult(exam.examId)
            : null;

        if (mounted) {
          setState(() {
            _exam = exam;
            _hasCompleted = hasCompleted;
            _userResult = result;
            _isLoading = false;
          });
          _updateStatus();
        }

        if (kDebugMode) {
          debugPrint(
            'Sınav yüklendi: ${exam.examId}, Tamamlandı: $hasCompleted',
          );
        }
      } else {
        // Sınav yok - kart yine de gösterilecek
        setState(() {
          _exam = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Sınav yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    // Yükleniyor durumu
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Sınav yoksa "Henüz sınav yayınlanmadı" kartı göster
    if (_exam == null) {
      return _buildNoExamCard();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: _getGradient(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getMainColor().withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Dekoratif daireler
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Ana içerik
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onCardTap,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst kısım - Başlık ve ikon
                      Row(
                        children: [
                          // Trophy ikonu
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
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
                                const Text(
                                  '🏆 Türkiye Geneli Deneme',
                                  style: TextStyle(
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
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Durum badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _hasCompleted ? '✓ Tamamlandı' : _status.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Motivasyon mesajı
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getMotivationMessage(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Alt kısım - Geri sayım ve buton
                      Row(
                        children: [
                          // Geri sayım
                          if (_status != ExamRoomStatus.sonuclanmis) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDuration(_remaining),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const Spacer(),

                          // Aksiyon butonu
                          ElevatedButton(
                            onPressed: _canTakeAction() ? _onCardTap : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _getMainColor(),
                              disabledBackgroundColor: Colors.white.withValues(
                                alpha: 0.5,
                              ),
                              disabledForegroundColor: Colors.grey,
                              elevation: 4,
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getButtonText(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
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
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
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
          ],
        ),
      ),
    );
  }

  /// Sınav yokken gösterilecek kart
  Widget _buildNoExamCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade500, Colors.grey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Dekoratif daireler
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.event_busy,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🏆 Türkiye Geneli Deneme',
                              style: TextStyle(
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '⏳ Bekleniyor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Henüz bu hafta için sınav yayınlanmadı. Yakında burada olacak! 📚',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  /// Kullanıcı bir aksiyon alabilir mi?
  bool _canTakeAction() {
    if (_isLoading || _exam == null) return false;

    // Sınav tamamlandıysa ve sonuçlar açıklandıysa -> sonuçları görebilir
    if (_hasCompleted && _status == ExamRoomStatus.sonuclanmis) {
      return true;
    }

    // Sınav tamamlandıysa ve sonuçlar henüz açıklanmadıysa -> HİÇBİR AKSİYON YOK
    if (_hasCompleted) {
      return false;
    }

    // Sınav aktifse ve tamamlanmamışsa -> sınava girebilir
    if (_status == ExamRoomStatus.aktif) {
      return true;
    }

    // Sonuçlar açıklandıysa ve tamamlanmamışsa -> sonuçları görebilir
    if (_status == ExamRoomStatus.sonuclanmis) {
      return true;
    }

    // Beklemede veya kapalı -> aksiyon yok
    return false;
  }

  LinearGradient _getGradient() {
    // Sınav tamamlandıysa ve sonuçlar açıklanmadıysa özel renk
    if (_hasCompleted && _status != ExamRoomStatus.sonuclanmis) {
      return LinearGradient(
        colors: [Colors.teal.shade400, Colors.teal.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

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
    // Sınav tamamlandıysa ve sonuçlar açıklanmadıysa özel renk
    if (_hasCompleted && _status != ExamRoomStatus.sonuclanmis) {
      return Colors.teal.shade600;
    }

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
    // Sınav tamamlandıysa check ikonu
    if (_hasCompleted) {
      return Icons.check_circle;
    }

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
      return 'Sınavı tamamladın! Sonuçlar Pazar 12:00\'da açıklanacak. ⏳';
    }
    return _status.motivationMessage;
  }

  String _getButtonText() {
    if (_hasCompleted) {
      if (_status == ExamRoomStatus.sonuclanmis) {
        return 'Sonuçları Gör';
      }
      return 'Bekle...';
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
      if (_status == ExamRoomStatus.sonuclanmis) {
        return Icons.visibility;
      }
      return Icons.hourglass_empty;
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

    // ÖNCELİK 1: Sınav tamamlandıysa ve sonuçlar HENÜZ açıklanmadıysa -> ENGELLE
    if (_hasCompleted && _status != ExamRoomStatus.sonuclanmis) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu sınavı zaten tamamladın! Sonuçlar Pazar 12:00\'da açıklanacak.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // ÖNCELİK 2: Sonuçlar açıklandıysa sonuç ekranına git
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
          content: Text('Sonuçlar Pazar 12:00\'da açıklanacak!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
