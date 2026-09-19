import 'package:flutter/material.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Admin modal bottom sheet to inspect and toggle system settings, specifically
/// payment gateway visibility and free purchases mode according to
/// settings_api_documentation.md.
class AdminSettingsSheet extends StatefulWidget {
  const AdminSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AdminSettingsSheet(),
    );
  }

  @override
  State<AdminSettingsSheet> createState() => _AdminSettingsSheetState();
}

class _AdminSettingsSheetState extends State<AdminSettingsSheet> {
  final _adminTokenController = TextEditingController();

  bool _loading = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _adminTokenController.dispose();
    super.dispose();
  }

  Future<void> _togglePaymentGateway(AppController app, bool show) async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    final adminToken = _adminTokenController.text.trim().isNotEmpty
        ? _adminTokenController.text.trim()
        : null;

    try {
      await app.updatePaymentGatewaySetting(
        show,
        adminToken: adminToken,
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _isError = false;
        _statusMessage = context.tr('settingsUpdated');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isError = true;
        _statusMessage = '$e';
      });
    }
  }

  Future<void> _refreshSettings(AppController app) async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    try {
      await app.refreshSettings(forceRefresh: true);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _isError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isError = true;
        _statusMessage = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppControllerScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE6F4EA),
                child: Icon(
                  Icons.settings_suggest_rounded,
                  color: AppColors.teal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('adminSettings'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'POST /api/v1/admin/settings',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black45,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loading ? null : () => _refreshSettings(app),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: context.tr('retry'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Admin token field (optional)
          TextField(
            controller: _adminTokenController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Admin Bearer Token (Optional)',
              hintText: 'Required if session token is not admin',
              prefixIcon: const Icon(Icons.key_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Switch 1: Show Payment Gateway Mobile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('showPaymentGateway'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('showPaymentGatewayDesc'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: app.showPaymentGatewayMobile,
                  activeTrackColor: AppColors.teal,
                  onChanged: _loading
                      ? null
                      : (val) => _togglePaymentGateway(app, val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Switch 2: Free Purchases Mode (Direct toggle)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            context.tr('freePurchases'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: app.isFreePurchase
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              app.isFreePurchase ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: app.isFreePurchase
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('freePurchasesDesc'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: app.isFreePurchase,
                  activeTrackColor: AppColors.orange,
                  onChanged: _loading
                      ? null
                      : (val) => _togglePaymentGateway(app, !val),
                ),
              ],
            ),
          ),

          if (_loading) ...[
            const SizedBox(height: 14),
            const Center(child: CircularProgressIndicator.adaptive()),
          ],

          if (_statusMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isError
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _isError ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
