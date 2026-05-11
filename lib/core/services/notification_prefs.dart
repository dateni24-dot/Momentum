import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPrefs {
  static const _keyEnabled = 'notif_daily_enabled';
  static const _keyHour   = 'notif_daily_hour';
  static const _keyMinute = 'notif_daily_minute';

  static Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  static Future<TimeOfDay> getTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour   = prefs.getInt(_keyHour)   ?? 9;
    final minute = prefs.getInt(_keyMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<void> setTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour,   time.hour);
    await prefs.setInt(_keyMinute, time.minute);
  }
}
