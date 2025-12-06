import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'database_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Bildirimleri başlatır
  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Timezone verisini yükle
    tz.initializeTimeZones();

    // Android için bildirim izni iste
    await _requestPermissions();
  }

  /// Bildirim iznini ister
  Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Bildirime tıklandığında çalışır
  void _onNotificationTapped(NotificationResponse response) {
    // Bildirime tıklandığında yapılacak işlemler buraya eklenebilir
    // Örneğin: Bildirim ID'sini alıp okundu olarak işaretle
    if (response.payload != null) {
      final int? notificationId = int.tryParse(response.payload!);
      if (notificationId != null) {
        DatabaseHelper().markNotificationAsRead(notificationId);
      }
    }
  }

  /// Bildirim gönderir ve veritabanına kaydeder
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Veritabanına kaydet
    final int notificationId = await DatabaseHelper().insertNotification({
      'title': title,
      'body': body,
      'date': DateTime.now().toIso8601String(),
      'isRead': 0,
    });

    // Bildirimi göster
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'bilgi_avcisi_channel',
          'Bilgi Avcısı Bildirimleri',
          channelDescription: 'Eğitim içerikleri ve güncellemeler',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: notificationId.toString(),
    );
  }

  /// Tüm bildirimleri iptal eder
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Belirli bir bildirimi iptal eder
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // ========== SINAV BİLDİRİMLERİ ==========

  /// Sınav başlangıç bildirimi planla
  /// Sınav başladığında bildirim gönderir
  Future<void> scheduleExamStartNotification({
    required String examId,
    required String examTitle,
    required DateTime startDate,
  }) async {
    // Bildirim ID'si: examId'nin hash'i
    final notificationId = examId.hashCode;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'exam_notifications',
          'Sınav Bildirimleri',
          channelDescription: 'Deneme sınavları ve sonuçları',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Zamanlanmış bildirim
    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Türkiye Geneli Deneme Başladı! 🎯',
      '$examTitle sınavı başladı. Hemen katıl!',
      _convertToTZDateTime(startDate),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'exam_start_$examId',
    );

    // Veritabanına kaydet
    await DatabaseHelper().insertNotification({
      'title': 'Türkiye Geneli Deneme Başladı! 🎯',
      'body': '$examTitle sınavı başladı. Hemen katıl!',
      'date': startDate.toIso8601String(),
      'isRead': 0,
    });
  }

  /// Sonuç açıklama bildirimi planla (Cuma 10:00)
  Future<void> scheduleResultNotification({
    required String examId,
    required String examTitle,
  }) async {
    // Cuma günü 10:00 hesapla
    final now = DateTime.now();
    DateTime resultDate = now;

    // Bir sonraki Cuma'yı bul (5 = Cuma)
    while (resultDate.weekday != DateTime.friday) {
      resultDate = resultDate.add(const Duration(days: 1));
    }

    // Saat 10:00'a ayarla
    resultDate = DateTime(
      resultDate.year,
      resultDate.month,
      resultDate.day,
      10,
      0,
    );

    // Bildirim ID'si: examId + "_result"
    final notificationId = '${examId}_result'.hashCode;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'exam_results',
          'Sınav Sonuçları',
          channelDescription: 'Deneme sınavı sonuçları',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Zamanlanmış bildirim
    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Sonuçlar Açıklandı! 🎉',
      '$examTitle sonuçların hazır. Hemen kontrol et!',
      _convertToTZDateTime(resultDate),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'exam_result_$examId',
    );

    // Veritabanına kaydet
    await DatabaseHelper().insertNotification({
      'title': 'Sonuçlar Açıklandı! 🎉',
      'body': '$examTitle sonuçların hazır. Hemen kontrol et!',
      'date': resultDate.toIso8601String(),
      'isRead': 0,
    });
  }

  /// TZDateTime'a çevir (timezone paketi gerekli)
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  // ========== HOŞGELDİN BİLDİRİMİ ==========

  /// İlk kurulumdan sonra hoşgeldin bildirimi gönderir
  /// @param userName Kullanıcının adı
  /// @param delaySeconds Kaç saniye sonra gönderilecek (varsayılan: 10)
  Future<void> scheduleWelcomeNotification({
    required String userName,
    int delaySeconds = 10,
  }) async {
    final scheduledTime = DateTime.now().add(Duration(seconds: delaySeconds));

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'welcome_channel',
          'Hoşgeldin Bildirimleri',
          channelDescription: 'Yeni kullanıcılar için karşılama bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          styleInformation: BigTextStyleInformation(''),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = 'welcome_$userName'.hashCode;
    final title = '🎉 Hoş Geldin $userName!';
    final body =
        '🚀 Öğrenme macerana hoş geldin!\n\n'
        '📚 Testler, bilgi kartları ve mini oyunlarla öğrenmeyi keşfet.\n'
        '🎮 Tüm ekranları kontrol etmeyi unutma!\n\n'
        '⭐ Şimdi başla ve bilgi avcısı ol!';

    // Zamanlanmış bildirim
    await _notificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      _convertToTZDateTime(scheduledTime),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'welcome_notification',
    );

    // Veritabanına kaydet
    await DatabaseHelper().insertNotification({
      'title': title,
      'body': body,
      'date': scheduledTime.toIso8601String(),
      'isRead': 0,
    });
  }
}
