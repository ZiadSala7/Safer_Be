import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'registered_devices_sheet.dart';

class NotificationsSettingsCard extends StatefulWidget {
  const NotificationsSettingsCard({super.key});

  @override
  State<NotificationsSettingsCard> createState() =>
      _NotificationsSettingsCardState();
}

class _NotificationsSettingsCardState extends State<NotificationsSettingsCard> {
  bool _pushLoading = false;
  bool _marketingLoading = false;

  Future<void> _handlePushToggle(bool value, AppController app) async {
    setState(() => _pushLoading = true);
    try {
      final success = await app.setPushNotificationConsent(value);
      if (!success && mounted) {
        if (value) {
          // Show dialog about permission
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(context.tr('permissionDeniedTitle')),
              content: Text(context.tr('permissionDeniedDesc')),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.tr('ok')),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _pushLoading = false);
    }
  }

  Future<void> _handleMarketingToggle(bool value, AppController app) async {
    setState(() => _marketingLoading = true);
    try {
      await app.setMarketingConsent(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _marketingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppControllerScope.of(context);
    final user = app.user;
    final pushEnabled = user?.pushNotificationConsent ?? false;
    final marketingEnabled = user?.marketingConsent ?? false;

    return Card(
      child: Column(
        children: [
          // Push Notifications Switch
          SwitchListTile.adaptive(
            value: pushEnabled,
            onChanged: (app.isGuest || _pushLoading)
                ? null
                : (val) => _handlePushToggle(val, app),
            activeThumbColor: AppColors.teal,
            secondary: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _pushLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.teal,
                      ),
                    )
                  : const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.teal,
                      size: 20,
                    ),
            ),
            title: Text(
              context.tr('pushNotifications'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            subtitle: Text(
              context.tr('pushNotificationsDesc'),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
          const Divider(height: 1),

          // Marketing Emails Switch (Independent)
          SwitchListTile.adaptive(
            value: marketingEnabled,
            onChanged: (app.isGuest || _marketingLoading)
                ? null
                : (val) => _handleMarketingToggle(val, app),
            activeThumbColor: AppColors.orange,
            secondary: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _marketingLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.orange,
                      ),
                    )
                  : const Icon(
                      Icons.mark_email_read_outlined,
                      color: AppColors.orange,
                      size: 20,
                    ),
            ),
            title: Text(
              context.tr('marketingEmails'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            subtitle: Text(
              context.tr('marketingEmailsDesc'),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),

          if (!app.isGuest) ...[
            const Divider(height: 1),
            // View Registered Devices
            ListTile(
              onTap: () => RegisteredDevicesSheet.show(context),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              title: Text(
                context.tr('registeredDevices'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ],
      ),
    );
  }
}
