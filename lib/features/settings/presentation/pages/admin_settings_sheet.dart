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

          // Switch 1: Online Booking & Payment Mode (show_payment_gateway_mobile: true)
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
                            context.tr('normalBookingMode'),
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
                              color: app.showPaymentGatewayMobile
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              app.showPaymentGatewayMobile ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: app.showPaymentGatewayMobile
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
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

          // Switch 2: WhatsApp Contact Mode (show_payment_gateway_mobile: false)
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
                            context.tr('whatsAppContactMode'),
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
                              color: app.isWhatsAppContactMode
                                  ? const Color(0xFF16A34A).withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              app.isWhatsAppContactMode ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: app.isWhatsAppContactMode
                                    ? const Color(0xFF16A34A)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('whatsAppModeDesc'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: app.isWhatsAppContactMode,
                  activeTrackColor: const Color(0xFF16A34A),
                  onChanged: _loading
                      ? null
                      : (val) => _togglePaymentGateway(app, !val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Status Matrix Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Behavior Matrix (settings_api_documentation.md)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _matrixItem('Price', app.showPaymentGatewayMobile),
                    _matrixItem('Book Now', app.showPaymentGatewayMobile),
                    _matrixItem('Gateway', app.showPaymentGatewayMobile),
                    _matrixItem('WhatsApp', true, isAlwaysActive: !app.showPaymentGatewayMobile),
                  ],
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

  Widget _matrixItem(String label, bool active, {bool isAlwaysActive = false}) {
    final showCheck = isAlwaysActive || active;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: showCheck
                ? (isAlwaysActive
                    ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15))
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            showCheck ? (isAlwaysActive ? 'ACTIVE' : 'SHOW') : 'HIDE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: showCheck
                  ? (isAlwaysActive ? const Color(0xFF16A34A) : Colors.green)
                  : Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}

