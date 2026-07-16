import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Có thể xử lý khi user tap vào notification
      },
    );

    // Yêu cầu quyền trên Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showTimerCompleteNotification({
    required String stepName,
    int notifId = 0,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Thông báo khi bộ đếm thời gian kết thúc',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final notifDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: notifId,
      title: '⏰ Hết thời gian!',
      body: '$stepName đã hoàn thành. Hãy chuyển sang bước tiếp theo.',
      notificationDetails: notifDetails,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
