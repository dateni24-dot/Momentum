import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'habit_ready';
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
  /// [minutesFromNow] es el tiempo restante en minutos desde este momento.
  static Future<void> scheduleHabitReady({
    required int habitId,
    required int minutesFromNow,
  }) async {
    if (minutesFromNow <= 0) return;

    final msg = _messages[habitId % _messages.length];

    // Usamos UTC para evitar bugs de zona horaria: sumamos el delay desde ahora
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
      // inexact no requiere permiso especial de alarma (SCHEDULE_EXACT_ALARM)
      // puede llegar unos minutos tarde pero funciona en todos los Android
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancela la notificación del hábito (al cancelar o completar el hábito).
  static Future<void> cancel(int habitId) async {
    await _plugin.cancel(habitId);
  }

  /// Programa un recordatorio diario a la hora local indicada.
  /// Usa DateTimeComponents.time para que se repita cada día.
  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    // Convertimos la hora local a UTC sumando el offset del dispositivo
    final offset = DateTime.now().timeZoneOffset;
    final now    = tz.TZDateTime.now(tz.UTC);

    var target = tz.TZDateTime.utc(
      now.year, now.month, now.day,
      time.hour, time.minute,
    ).subtract(offset);

    // Si ya pasó hoy, empezamos mañana
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
