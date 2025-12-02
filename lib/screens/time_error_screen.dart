import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/time_service.dart';

/// Zaman manipülasyonu tespit edildiğinde gösterilen ekran
class TimeErrorScreen extends StatelessWidget {
  final TimeManipulationException exception;

  const TimeErrorScreen({super.key, required this.exception});

  @override
  Widget build(BuildContext context) {
    final minutesDifference = exception.differenceSeconds ~/ 60;

    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Uyarı animasyonu
              Lottie.asset(
                'assets/animation/loading-kum.json',
                width: 200,
                height: 200,
                repeat: true,
              ),
              const SizedBox(height: 32),

              // Başlık
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 16),

              Text(
                'Zaman Hatası Tespit Edildi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Hata mesajı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Cihaz saatiniz ile gerçek zaman arasında $minutesDifference dakika fark tespit edildi.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildTimeInfo(
                      context,
                      'Cihaz Saati',
                      exception.deviceTime,
                      Colors.red.shade700,
                    ),
                    const SizedBox(height: 8),
                    _buildTimeInfo(
                      context,
                      'Gerçek Zaman',
                      exception.realTime,
                      Colors.green.shade700,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Talimatlar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade900),
                        const SizedBox(width: 8),
                        Text(
                          'Nasıl Düzeltilir?',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstruction('1. Cihazınızın ayarlarına gidin'),
                    _buildInstruction('2. Tarih ve Saat ayarlarını bulun'),
                    _buildInstruction(
                      '3. "Otomatik tarih ve saat" seçeneğini açın',
                    ),
                    _buildInstruction('4. Uygulamayı yeniden başlatın'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Yeniden dene butonu
              ElevatedButton.icon(
                onPressed: () {
                  // Uygulamayı yeniden başlatmak için
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Yeniden Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(
    BuildContext context,
    String label,
    DateTime time,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '${time.day}.${time.month}.${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
