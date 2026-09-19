import 'package:flutter/foundation.dart';

/// Represents system-level configuration flags returned by `/api/v1/settings`.
@immutable
class SystemSettings {
  const SystemSettings({
    this.showPaymentGatewayMobile = true,
  });

  /// Whether the mobile app should show external payment gateway (e.g. MyFatoorah).
  ///
  /// - `true`: Normal paid mode with payment gateway checkout.
  /// - `false`: Free purchases mode (payment gateway is hidden / bypassed).
  final bool showPaymentGatewayMobile;

  /// Inverse convenience flag for "Free Purchases" mode.
  ///
  /// When true, bookings/purchases are completed directly for free without
  /// redirecting to the payment gateway.
  bool get isFreePurchase => !showPaymentGatewayMobile;

  /// Alias for [isFreePurchase].
  bool get freePurchases => !showPaymentGatewayMobile;

  /// Default settings instance with standard paid flow enabled.
  static const SystemSettings defaults = SystemSettings(showPaymentGatewayMobile: true);

  /// Factory constructor to parse settings from various API response shapes:
  ///
  /// 1. Public endpoint `/api/v1/settings`:
  ///    `{"success": true, "data": {"show_payment_gateway_mobile": true}}`
  /// 2. Admin endpoint `/api/v1/admin/settings`:
  ///    `{"success": true, "data": [{"key": "show_payment_gateway_mobile", "value": "1"}]}`
  /// 3. Direct map or nested payload.
  factory SystemSettings.fromJson(dynamic json) {
    if (json == null) return defaults;

    if (json is Map) {
      final data = json['data'] ?? json;

      // Case A: data is a list of key-value objects (Admin response format)
      if (data is List) {
        return _fromKeyValueList(data);
      }

      // Case B: data is a map (Public endpoint format)
      if (data is Map) {
        if (data.containsKey('show_payment_gateway_mobile')) {
          return SystemSettings(
            showPaymentGatewayMobile: _parseBool(data['show_payment_gateway_mobile']),
          );
        }
      }
    } else if (json is List) {
      return _fromKeyValueList(json);
    }

    return defaults;
  }

  static SystemSettings _fromKeyValueList(List<dynamic> list) {
    for (final item in list) {
      if (item is Map) {
        final key = item['key']?.toString();
        if (key == 'show_payment_gateway_mobile') {
          return SystemSettings(
            showPaymentGatewayMobile: _parseBool(item['value']),
          );
        }
      }
    }
    return defaults;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    final str = value.toString().trim().toLowerCase();
    if (str == '1' || str == 'true' || str == 'yes' || str == 'on') return true;
    if (str == '0' || str == 'false' || str == 'no' || str == 'off') return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'show_payment_gateway_mobile': showPaymentGatewayMobile,
  };

  SystemSettings copyWith({bool? showPaymentGatewayMobile}) => SystemSettings(
    showPaymentGatewayMobile: showPaymentGatewayMobile ?? this.showPaymentGatewayMobile,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemSettings &&
          runtimeType == other.runtimeType &&
          showPaymentGatewayMobile == other.showPaymentGatewayMobile;

  @override
  int get hashCode => showPaymentGatewayMobile.hashCode;

  @override
  String toString() =>
      'SystemSettings(showPaymentGatewayMobile: $showPaymentGatewayMobile, isFreePurchase: $isFreePurchase)';
}
