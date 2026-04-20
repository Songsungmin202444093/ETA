import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// 알림 권한 요청 (Android 13+, iOS 모두)
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// N분 후 버스 도착 알림
  Future<void> scheduleArrivalAlert({
    required int id,
    required String stationName,
    required String line,
    required int arrivalMinutes,
  }) async {
    await init();

    final remaining = arrivalMinutes - 1;
    if (remaining <= 0) {
      // 이미 도착 직전: 즉시 알림
      await _showImmediate(
        id: id,
        title: '🚌 $line 버스 곧 도착!',
        body: '$stationName 정류장에 $line번이 약 1분 내 도착합니다.',
      );
      return;
    }

    // 지정 분 전 알림 (타이머 기반 - 테스트 환경에서도 동작)
    await Future.delayed(Duration(minutes: remaining), () async {
      await _showImmediate(
        id: id,
        title: '🚌 $line 버스 1분 전!',
        body: '$stationName 정류장에 $line번 버스가 1분 후 도착합니다. 서두르세요!',
      );
    });
  }

  Future<void> _showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'bus_arrival',
      '버스 도착 알림',
      channelDescription: '버스 도착 예정 시간 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, title, body, details);
  }

  /// 특정 알림 취소
  Future<void> cancel(int id) => _plugin.cancel(id);

  /// 전체 알림 취소
  Future<void> cancelAll() => _plugin.cancelAll();
}
