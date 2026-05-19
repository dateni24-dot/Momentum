import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Servicio de notificaciones locales.
//
// PATRÓN GENERAL: todas las llamadas al plugin van envueltas en
// `try { ... } catch (_) {}` con `.timeout(_timeout)` (5s).
//
// El motivo: las APIs nativas de notificaciones en Android son
// inconsistentes entre OEMs (Xiaomi, Huawei, OnePlus, etc. tienen
// implementaciones agresivas de battery saver que pueden bloquear,
// fallar o tardar segundos en responder). Una excepción aquí no debe
// nunca colgar el UI ni romper el flujo principal (ej: completar un
// hábito). El coste es que si una notificación NO se programa por un
// bug real, el usuario simplemente no recibe aviso y no hay traza.
//
// Si en el futuro empiezan a llegar reports de "no me suenan las
// notificaciones", lo primero es quitar temporalmente estos catch
// para ver qué falla — son una caja negra a propósito.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'habit_ready';
  static const _channelName = 'Hábitos completados';
  static const _channelDesc = 'Aviso cuando un hábito está listo para reclamar';

  static const _dailyChannelId   = 'daily_reminder';
  static const _dailyChannelName = 'Recordatorio diario';
  static const _dailyChannelDesc = 'Recordatorio diario para completar hábitos';
  static const _dailyNotifId     = 0;
  static const _testNotifId      = 8888;

  static const _timeout = Duration(seconds: 5);

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

  static Future<void> showTestNotification() async {
    try {
      await _plugin.show(
        999,
        'Momentum — Prueba ',
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
      ).timeout(_timeout);
    } catch (_) {}
  }

  /// Programa una notificación de prueba en 30 segundos.
  /// Devuelve cadena vacía si OK, o el error.
  static Future<String> scheduleTestIn30s() async {
    final fireAt = tz.TZDateTime.now(tz.UTC).add(const Duration(seconds: 30));
    return _trySchedule(
      id:    _testNotifId,
      title: 'Momentum — Test programado ⏰',
      body:  'Esta notificación se programó hace 30 segundos.',
      fireAt: fireAt,
    );
  }

  /// SOLO usar bajo demanda — esta API puede ser lenta o colgar en algunos OEMs.
  /// Tiene timeout de 5 seg para que nunca cuelgue el UI.
  static Future<int> pendingCount() async {
    try {
      final pending = await _plugin.pendingNotificationRequests().timeout(_timeout);
      return pending.length;
    } catch (_) {
      return -1; // marker de "error/timeout"
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll().timeout(_timeout);
    } catch (_) {}
  }

  static Future<void> scheduleHabitReady({
    required int habitId,
    required int minutesFromNow,
  }) async {
    if (minutesFromNow <= 0) return;
    final msg = _messages[habitId % _messages.length];
    final fireAt = tz.TZDateTime.now(tz.UTC).add(Duration(minutes: minutesFromNow));
    await _trySchedule(
      id: habitId, title: 'Momentum', body: msg, fireAt: fireAt,
    );
  }

  static Future<void> cancel(int habitId) async {
    try {
      await _plugin.cancel(habitId).timeout(_timeout);
    } catch (_) {}
  }

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

    await _trySchedule(
      id:      _dailyNotifId,
      title:   'Momentum',
      body:    'Tus hábitos te están esperando 💪',
      fireAt:  target,
      isDaily: true,
      repeats: true,
    );
  }

  static Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(_dailyNotifId).timeout(_timeout);
    } catch (_) {}
  }

  /// Intenta programar con `inexactAllowWhileIdle` (más compatible).
  /// Si falla, intenta `exactAllowWhileIdle`. Con timeout 5 seg.
  static Future<String> _trySchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime fireAt,
    bool isDaily = false,
    bool repeats = false,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        isDaily ? _dailyChannelId   : _channelId,
        isDaily ? _dailyChannelName : _channelName,
        channelDescription: isDaily ? _dailyChannelDesc : _channelDesc,
        importance: Importance.high,
        priority:   Priority.high,
        category:   AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    // Inexact primero — funciona en todos los Android sin permisos especiales
    try {
      await _plugin.zonedSchedule(
        id, title, body, fireAt, details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeats ? DateTimeComponents.time : null,
      ).timeout(_timeout);
      return '';
    } catch (e) {
      // Fallback a exact
      try {
        await _plugin.zonedSchedule(
          id, title, body, fireAt, details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: repeats ? DateTimeComponents.time : null,
        ).timeout(_timeout);
        return '';
      } catch (e2) {
        return '$e2';
      }
    }
  }
}
