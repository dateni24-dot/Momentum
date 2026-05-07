import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'habit_ready';
  static const _channelName = 'Hábitos completados';
  static const _channelDesc =
      'Aviso cuando un hábito está listo para reclamar';

  static const _messages = [
    '¿Te atreves a reclamar lo que es tuyo?',
    'Algo te espera... ve a por ello.',
    'Tu recompensa está lista 👀',
    'El momento ha llegado.',
    'Has ganado algo. ¿Sabes qué es?',
    'La espera terminó. ¿Y ahora qué?',
    'Está esperando. ¿Cuánto tiempo más?',
  ];

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Solicita permiso al usuario. Devuelve true si fue concedido.
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  /// Programa una notificación para cuando el hábito [habitId] esté listo.
  static Future<void> scheduleHabitReady({
    required int habitId,
    required DateTime fireAt,
  }) async {
    // Si ya pasó el tiempo (ej: app reabierta con hábito ya listo), no programar
    if (fireAt.isBefore(DateTime.now())) return;

    final msg = _messages[habitId % _messages.length];

    await _plugin.zonedSchedule(
      habitId,
      'Momentum',
      msg,
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancela la notificación del hábito (al cancelar o completar el hábito).
  static Future<void> cancel(int habitId) async {
    await _plugin.cancel(habitId);
  }
}
