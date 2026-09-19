import 'package:flutter/foundation.dart';

import '../../data/repositories/api_settings_repository.dart';
import '../../domain/entities/system_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// A reactive [ChangeNotifier] controller managing the free purchases boolean state
/// and payment gateway visibility based on the System Settings API.
///
/// State meanings:
/// - [showPaymentGatewayMobile] == true : Normal payment mode (payment gateway shown).
/// - [isFreePurchase] / [freePurchases] == true : Free purchases mode (payment gateway hidden / bypassed).
class FreePurchasesController extends ChangeNotifier {
  FreePurchasesController({
    SettingsRepository? repository,
  }) : _repository = repository ?? ApiSettingsRepository();

  final SettingsRepository _repository;

  bool _showPaymentGatewayMobile = true;
  bool _isLoading = false;
  String? _error;

  /// Whether external payment gateway (e.g., MyFatoorah) should be displayed.
  bool get showPaymentGatewayMobile => _showPaymentGatewayMobile;

  /// Whether bookings and purchases are free (payment gateway is bypassed / hidden).
  bool get isFreePurchase => !_showPaymentGatewayMobile;

  /// Convenient alias for [isFreePurchase].
  bool get freePurchases => !_showPaymentGatewayMobile;

  /// Indicates if an asynchronous fetch or update operation is in flight.
  bool get isLoading => _isLoading;

  /// Last error message, if any.
  String? get error => _error;

  /// Returns current [SystemSettings] snapshot.
  SystemSettings get currentSettings =>
      SystemSettings(showPaymentGatewayMobile: _showPaymentGatewayMobile);

  /// Loads system settings from the repository and notifies listeners.
  Future<void> load({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final settings = await _repository.getSettings(forceRefresh: forceRefresh);
      _showPaymentGatewayMobile = settings.showPaymentGatewayMobile;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the free purchases mode directly.
  ///
  /// Setting `enabled = true` disables the payment gateway (`showPaymentGatewayMobile = false`).
  /// Setting `enabled = false` enables the payment gateway (`showPaymentGatewayMobile = true`).
  Future<bool> setFreePurchases(bool enabled, {String? adminToken}) async {
    return setShowPaymentGateway(!enabled, adminToken: adminToken);
  }

  /// Updates whether the payment gateway is visible via `POST /api/v1/admin/settings`.
  Future<bool> setShowPaymentGateway(bool show, {String? adminToken}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updateSettings(
        showPaymentGatewayMobile: show,
        adminToken: adminToken,
      );
      _showPaymentGatewayMobile = result.showPaymentGatewayMobile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggles between free purchases mode and paid mode.
  Future<bool> toggleFreePurchases({String? adminToken}) async {
    return setFreePurchases(!isFreePurchase, adminToken: adminToken);
  }

  /// Updates the local in-memory flag without calling the remote API.
  /// Useful for local testing, offline demo, or sandbox modes.
  void setLocalFreePurchase(bool isFree) {
    _showPaymentGatewayMobile = !isFree;
    _error = null;
    notifyListeners();
  }

  /// Updates the local in-memory flag for payment gateway visibility.
  void setLocalShowPaymentGateway(bool show) {
    _showPaymentGatewayMobile = show;
    _error = null;
    notifyListeners();
  }
}
