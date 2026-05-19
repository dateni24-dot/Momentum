import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    ).timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  // La app ya tiene lo mínimo (env + Supabase) para pintar el primer frame.
  // Las notificaciones se inicializan en background — algunos OEMs Android
  // (Xiaomi/Huawei/OnePlus) bloquean varios segundos en NotificationService.init
  // y eso retrasaba visiblemente el splash. No afectan al render, así que
  // se arrancan sin await.
  runApp(const ProviderScope(child: MomentumApp()));

  unawaited(_initNotificationsInBackground());
}

Future<void> _initNotificationsInBackground() async {
  await NotificationService.init();
  // Restaurar recordatorio diario si el usuario lo tenía activado
  if (await NotificationPrefs.getEnabled()) {
    final time = await NotificationPrefs.getTime();
    await NotificationService.scheduleDailyReminder(time);
  }
}

class MomentumApp extends ConsumerWidget {
  const MomentumApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Momentum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}