import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/device_token.dart';
import '../../services/notification_service.dart';

class RegisteredDevicesSheet extends StatefulWidget {
  const RegisteredDevicesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const RegisteredDevicesSheet(),
    );
  }

  @override
  State<RegisteredDevicesSheet> createState() => _RegisteredDevicesSheetState();
}

class _RegisteredDevicesSheetState extends State<RegisteredDevicesSheet> {
  final _service = NotificationService.instance;
  bool _loading = true;
  String? _error;
  List<DeviceToken> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _service.listDevices();
      if (mounted) {
        setState(() {
          _devices = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(DeviceToken device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('unregisterDevice')),
        content: Text(context.tr('unregisterDeviceConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.deleteDevice(device.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('deviceUnregistered'))),
          );
          _loadDevices();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.devices_rounded, color: AppColors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('registeredDevices'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('registeredDevicesSubtitle'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.teal),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _loadDevices,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.tr('retry')),
                    ),
                  ],
                ),
              )
            else if (_devices.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    context.tr('noRegisteredDevices'),
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isApple = device.platform.toLowerCase() == 'ios';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isApple ? Icons.apple_rounded : Icons.android_rounded,
                            size: 28,
                            color: isApple ? Colors.grey : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      device.platform.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    if (device.appVersion != null && device.appVersion!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        'v${device.appVersion}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (device.tokenHint != null && device.tokenHint!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    device.tokenHint!,
                                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                            onPressed: () => _confirmDelete(device),
                            tooltip: context.tr('unregisterDevice'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
