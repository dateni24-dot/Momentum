import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'habit_ready';
  static const _channelName = 'Hábitos completados';
  static const _channelDesc = 'Aviso cuando un hábito está listo para reclamar';

  static const _dailyChannelId   = 'daily_reminder';
  static const _dailyChannelName = 'Recordatorio diario';
  static const _dailyChannelDesc = 'Recordatorio diario para completar hábitos';
  static const _dailyNotifId     = 0;

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

    // Crear los canales explícitamente para que existan cuando el receiver
    // los necesite en background (sin proceso Flutter activo)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _dailyChannelId,
          _dailyChannelName,
          description: _dailyChannelDesc,
          importance: Importance.high,
        ),
      );
    }
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

  /// Muestra una notificación inmediata. Útil para probar que el sistema funciona.
  static Future<void> showTestNotification() async {
    await _plugin.show(
      999,
      'Momentum — Prueba ✅',
      'Las notificaciones funcionan correctamente.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Programa una notificación para cuando el hábito [habitId] esté listo.
  static Future<void> scheduleHabitReady({
    required int habitId,
    required int minutesFromNow,
  }) async {
    if (minutesFromNow <= 0) return;

    final msg = _messages[habitId % _messages.length];
    final tzFireAt = tz.TZDateTime.now(tz.UTC).add(Duration(minutes: minutesFromNow));

    await _plugin.zonedSchedule(
      habitId,
      'Momentum',
      msg,
      tzFireAt,
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

  /// Programa un recordatorio diario a la hora local indicada.
  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    final offset = DateTime.now().timeZoneOffset;
    final now    = tz.TZDateTime.now(tz.UTC);

    var target = tz.TZDateTime.utc(
      now.year, now.month, now.day,
      time.hour, time.minute,
    ).subtract(offset);

    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyNotifId,
      'Momentum',
      'Tus hábitos te están esperando 💪',
      target,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          channelDescription: _dailyChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancela el recordatorio diario.
  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyNotifId);
  }
}
