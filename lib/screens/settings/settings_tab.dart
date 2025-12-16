import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../services/pvr_api_service.dart';
import '../../services/notification_service.dart';

/// Settings tab for app configuration
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Notifications section
        _buildSectionHeader(
          context,
          Icons.notifications_active,
          'Notification Settings',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          'Choose how you want to be notified when tickets are available.',
          colorScheme,
        ),
        const SizedBox(height: 16),

        // Windows/Desktop notifications
        _buildSettingCard(
          context: context,
          icon: Icons.computer,
          title: 'Desktop Notifications',
          subtitle: 'Shows popup notifications on your screen',
          trailing: Switch(
            value: settings.enableWindowsNotif,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setWindowsNotifEnabled(v),
          ),
        ),

        const SizedBox(height: 8),

        // Test desktop notification button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FilledButton.tonalIcon(
            onPressed: () => _testDesktopNotification(context, ref),
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send Test Desktop Notification'),
          ),
        ),

        const SizedBox(height: 12),

        // Telegram notifications
        _buildSettingCard(
          context: context,
          icon: Icons.send,
          title: 'Telegram Notifications',
          subtitle: 'Send notifications to your Telegram app',
          trailing: Switch(
            value: settings.enableTelegramNotif,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setTelegramNotifEnabled(v),
          ),
        ),

        const SizedBox(height: 32),

        // Telegram setup section
        _buildSectionHeader(
          context,
          Icons.telegram,
          'Telegram Setup (Optional)',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          'Get notified on your phone. Create a bot with @BotFather on Telegram.',
          colorScheme,
        ),
        const SizedBox(height: 16),

        // Bot token
        TextField(
          decoration: const InputDecoration(
            labelText: 'Bot Token',
            hintText: 'Paste your bot token here',
            prefixIcon: Icon(Icons.key),
          ),
          obscureText: true,
          controller: TextEditingController(text: settings.telegramBotToken),
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setTelegramBotToken(v),
        ),

        const SizedBox(height: 16),

        // Chat ID
        TextField(
          decoration: const InputDecoration(
            labelText: 'Chat ID',
            hintText: 'Your Telegram user ID',
            prefixIcon: Icon(Icons.person),
          ),
          controller: TextEditingController(text: settings.telegramChatId),
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setTelegramChatId(v),
        ),

        const SizedBox(height: 16),

        // Test telegram button
        FilledButton.tonalIcon(
          onPressed:
              settings.telegramBotToken.isNotEmpty &&
                  settings.telegramChatId.isNotEmpty
              ? () => _testTelegram(context, ref, settings)
              : null,
          icon: const Icon(Icons.science),
          label: const Text('Send Test Message'),
        ),

        const SizedBox(height: 32),

        // Time range section
        _buildSectionHeader(context, Icons.schedule, 'Show Time Filter'),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          'Only notify for shows within these hours.',
          colorScheme,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Time Range',
            hintText: 'Format: HH:MM-HH:MM (e.g., 08:00-24:00)',
            prefixIcon: Icon(Icons.access_time),
          ),
          controller: TextEditingController(text: settings.timeRange),
          onChanged: (v) => ref.read(settingsProvider.notifier).setTimeRange(v),
        ),

        const SizedBox(height: 32),

        // Appearance section
        _buildSectionHeader(context, Icons.palette, 'Appearance'),
        const SizedBox(height: 16),
        _buildSettingCard(
          context: context,
          icon: settings.isDarkTheme ? Icons.dark_mode : Icons.light_mode,
          title: 'Dark Theme',
          subtitle: settings.isDarkTheme
              ? 'Dark mode enabled'
              : 'Light mode enabled',
          trailing: Switch(
            value: settings.isDarkTheme,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setDarkTheme(v),
          ),
        ),

        const SizedBox(height: 32),

        // About section
        _buildSectionHeader(context, Icons.info_outline, 'About'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.tertiaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.movie_filter,
                    size: 40,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'PVR Cinema Monitor',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor ticket availability for PVR cinemas\nand get instant notifications.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 22, color: colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String text,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
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

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _testTelegram(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final success = await PvrApiService().sendTelegramMessage(
        botToken: settings.telegramBotToken,
        chatId: settings.telegramChatId,
        message: '✅ Test from PVR Monitor - Working!',
      );

      if (success) {
        ref.read(logsProvider.notifier).addLog('📤 Telegram test message sent');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Test message sent successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to send test message'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _testDesktopNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await NotificationService().showNotification(
        title: '🎬 Test Notification',
        body:
            'PVR Monitor is working! You will receive notifications here when tickets are available.',
      );

      ref
          .read(logsProvider.notifier)
          .addLog('🔔 Test desktop notification sent');

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Test notification sent! Check your notification area.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Failed to send notification: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
