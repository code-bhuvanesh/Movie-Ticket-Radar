import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../services/background_service.dart';
import '../../services/storage_service.dart';
import '../../models/monitoring_task.dart';

/// Settings tab for app configuration
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // Page Header
              _buildPageHeader(context, colorScheme),
              const SizedBox(height: 32),

              // MONITORING SECTION
              _buildSectionTitle(context, 'MONITORING', Icons.radar),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.notifications_active_outlined,
                title: Platform.isAndroid
                    ? 'Mobile Notification'
                    : 'Desktop Notifications',
                subtitle: 'Get alerts when tickets are found',
                trailing: Switch(
                  value: settings.enableWindowsNotif,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setWindowsNotifEnabled(v),
                ),
              ),

              if (Platform.isAndroid) ...[
                const SizedBox(height: 32),
                _buildSectionTitle(context, 'ANDROID SERVICE', Icons.android),
                const SizedBox(height: 12),
                _buildAndroidServiceInfo(context, colorScheme),
              ],

              const SizedBox(height: 32),

              // APPEARANCE SECTION
              _buildSectionTitle(context, 'APPEARANCE', Icons.palette_outlined),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: settings.isDarkTheme
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Easy on the eyes in the dark',
                trailing: Switch(
                  value: settings.isDarkTheme,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setDarkTheme(v),
                ),
              ),

              const SizedBox(height: 32),

              // DEBUG SECTION (Always visible now)
              _buildSectionTitle(
                context,
                'DEVELOPER TOOLS',
                Icons.bug_report_outlined,
              ),
              const SizedBox(height: 12),
              _buildDebugCard(context, ref, colorScheme),
              const SizedBox(height: 32),

              // ABOUT SECTION
              _buildSectionTitle(context, 'ABOUT', Icons.info_outline),
              const SizedBox(height: 12),
              _buildAboutCard(context, colorScheme),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETTINGS',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Personalize your monitoring experience',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildAndroidServiceInfo(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        _buildSettingCard(
          context: context,
          icon: Icons.battery_charging_full_outlined,
          title: 'Battery Optimization',
          subtitle: 'Required for background monitoring',
          trailing: IconButton(
            onPressed: () =>
                BackgroundService().requestBatteryOptimizationExemption(),
            icon: Icon(Icons.open_in_new, color: colorScheme.primary),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: FutureBuilder<bool>(
            future: BackgroundService().isServiceRunning(),
            builder: (context, snapshot) {
              final isRunning = snapshot.data ?? false;
              return Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isRunning ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isRunning ? Colors.green : Colors.red)
                              .withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isRunning
                        ? 'Monitoring Service Active'
                        : 'Monitoring Service Inactive',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isRunning ? Colors.green : Colors.red,
                    ),
                  ),
                  const Spacer(),
                  if (!isRunning)
                    TextButton(
                      onPressed: () => BackgroundService().runOnce(),
                      child: const Text('RESTART'),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDebugCard(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, color: colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'DEBUG TOOLS',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Test Notif Button
          FilledButton.tonalIcon(
            onPressed: () => _testDesktopNotification(context, ref),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Trigger Test Notification'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Force Notify Toggle
          StatefulBuilder(
            builder: (context, setState) {
              final forceNotify = StorageService().getDebugForceNotify();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Force Notifications',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Bypass duplicate check',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: forceNotify,
                    activeColor: colorScheme.error,
                    onChanged: (value) async {
                      await StorageService().setDebugForceNotify(value);
                      setState(() {});
                      ref
                          .read(logsProvider.notifier)
                          .addLog(
                            value
                                ? '[BUSY] Force notifications ENABLED'
                                : '[IDLE] Force notifications DISABLED',
                          );
                    },
                  ),
                ],
              );
            },
          ),
          const Divider(height: 32),

          // Cache Info
          _buildDebugInfoRow(
            'Notified Cache',
            '${StorageService().getNotifiedSessions().length} items',
          ),
          const SizedBox(height: 8),
          _buildDebugInfoRow(
            'Stored Tasks',
            '${MonitoringTask.decodeList(StorageService().getTasks()).length} tasks',
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () async {
              await StorageService().clearNotifiedSessions();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache Cleared')));
            },
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: const Text('Clear Notified Cache'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.4),
            colorScheme.secondaryContainer.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.movie_filter,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ticket Radar',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
          ),
          const Text(
            'Version 1.0.0',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            'High-performance cinema ticket monitoring system. Built for speed and reliability.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testDesktopNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await NotificationService().showNotification(
        title: '[MOVIE] Test Notification',
        body: 'Ticket Radar is working! You will receive notifications here.',
      );

      ref
          .read(logsProvider.notifier)
          .addLog('[NOTIF] Test desktop notification sent');

      messenger.showSnackBar(
        const SnackBar(
          content: Text('[DONE] Test notification sent!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('[ERROR] Failed to send notification: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
