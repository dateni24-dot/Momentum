import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/notification_prefs.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _enabled    = false;
  TimeOfDay _time  = const TimeOfDay(hour: 9, minute: 0);
  bool _loading    = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await NotificationPrefs.getEnabled();
    final time    = await NotificationPrefs.getTime();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _time    = time;
        _loading = false;
      });
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    setState(() => _enabled = value);
    await NotificationPrefs.setEnabled(value);
    if (value) {
      await NotificationService.scheduleDailyReminder(_time);
    } else {
      await NotificationService.cancelDailyReminder();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onSurface: AppColors.textPrimary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _time = picked);
    await NotificationPrefs.setTime(picked);
    if (_enabled) {
      await NotificationService.scheduleDailyReminder(picked);
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Tarjeta principal ─────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Toggle
                      _Row(
                        icon: Icons.notifications_outlined,
                        label: 'Recordatorio diario',
                        trailing: Switch(
                          value: _enabled,
                          onChanged: _toggleEnabled,
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),

                      if (_enabled) ...[
                        Divider(
                          height: 1,
                          color: AppColors.primary.withValues(alpha: 0.08),
                          indent: 54,
                        ),
                        // Time picker
                        _Row(
                          icon: Icons.access_time_rounded,
                          label: 'Hora del recordatorio',
                          trailing: GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.30),
                                ),
                              ),
                              child: Text(
                                _formatTime(_time),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Descripción
                Text(
                  _enabled
                      ? 'Recibirás un recordatorio cada día a las ${_formatTime(_time)} para no olvidar tus hábitos.'
                      : 'Activa el recordatorio diario para recibir un aviso y no olvidar tus hábitos.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Prueba de notificación ────────────────────────────────
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'DIAGNÓSTICO',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await NotificationService.showTestNotification();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Notificación enviada — comprueba el panel de notificaciones'),
                          backgroundColor: AppColors.surface,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_active_outlined,
                              color: AppColors.primary, size: 20),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Enviar notificación de prueba',
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 15),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: AppColors.textSecondary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Si aparece la notificación, el sistema funciona correctamente. Si no aparece, ve a Ajustes del móvil > Batería > Optimización de batería y excluye Momentum.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _Row({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
