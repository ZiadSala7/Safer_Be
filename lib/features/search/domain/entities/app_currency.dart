import '../../../../core/network/json_read.dart';

class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.name,
    required this.nameAr,
    required this.symbol,
    required this.flag,
    this.decimalPrecision = 2,
    this.isDefault = false,
  });

  final String code;
  final String name;
  final String nameAr;
  final String symbol;
  final String flag;
  final int decimalPrecision;
  final bool isDefault;

  String localizedName(String languageCode) =>
      languageCode == 'ar' ? nameAr : name;

  factory AppCurrency.fromJson(Map<String, dynamic> json) {
    final code = readText(json, ['code', 'currency_code', 'currencyCode', 'currency']).toUpperCase();
    final fallback = fromCode(code);
    return AppCurrency(
      code: code,
      name: readText(json, ['name', 'currency_name'], fallback.name),
      nameAr: readText(json, ['name_ar', 'nameAr'], fallback.nameAr),
      symbol: readText(json, ['symbol', 'currency_symbol'], fallback.symbol),
      flag: fallback.flag,
      decimalPrecision: readNumber(json, ['decimal_precision', 'decimalPrecision'], fallback.decimalPrecision).toInt(),
      isDefault: json['is_default'] == true,
    );
  }

  static AppCurrency fromCode(String code) {
    final normalized = code.trim().toUpperCase();
    return supportedCurrencies.firstWhere(
      (c) => c.code == normalized,
      orElse: () => AppCurrency(
        code: normalized,
        name: normalized,
        nameAr: normalized,
        symbol: normalized,
        flag: '🌐',
      ),
    );
  }

  static const List<AppCurrency> supportedCurrencies = [
    AppCurrency(
      code: 'SAR',
      name: 'Saudi Riyal',
      nameAr: 'ريال سعودي',
      symbol: 'ر.س',
      flag: '🇸🇦',
      isDefault: true,
    ),
    AppCurrency(
      code: 'USD',
      name: 'US Dollar',
      nameAr: 'دولار أمريكي',
      symbol: '\$',
      flag: '🇺🇸',
    ),
    AppCurrency(
      code: 'AED',
      name: 'UAE Dirham',
      nameAr: 'درهم إماراتي',
      symbol: 'د.إ',
      flag: '🇦🇪',
    ),
    AppCurrency(
      code: 'EGP',
      name: 'Egyptian Pound',
      nameAr: 'جنيه مصري',
      symbol: 'ج.م',
      flag: '🇪🇬',
    ),
    AppCurrency(
      code: 'EUR',
      name: 'Euro',
      nameAr: 'يورو',
      symbol: '€',
      flag: '🇪🇺',
    ),
    AppCurrency(
      code: 'GBP',
      name: 'British Pound',
      nameAr: 'جنيه إسترليني',
      symbol: '£',
      flag: '🇬🇧',
    ),
    AppCurrency(
      code: 'KWD',
      name: 'Kuwaiti Dinar',
      nameAr: 'دينار كويتي',
      symbol: 'د.ك',
      flag: '🇰🇼',
    ),
    AppCurrency(
      code: 'QAR',
      name: 'Qatari Riyal',
      nameAr: 'ريال قطري',
      symbol: 'ر.ق',
      flag: '🇶🇦',
    ),
    AppCurrency(
      code: 'BHD',
      name: 'Bahraini Dinar',
      nameAr: 'دينار بحريني',
      symbol: 'د.ب',
      flag: '🇧🇭',
    ),
    AppCurrency(
      code: 'OMR',
      name: 'Omani Rial',
      nameAr: 'ريال عماني',
      symbol: 'ر.ع',
      flag: '🇴🇲',
    ),
  ];

  static const Map<String, double> _sarRates = {
    'SAR': 1.0,
    'USD': 3.75,
    'AED': 1.02,
    'EUR': 4.10,
    'GBP': 4.90,
    'KWD': 12.25,
    'QAR': 1.03,
    'BHD': 9.95,
    'OMR': 9.75,
    'EGP': 0.076,
    'TRY': 0.11,
    'JOD': 5.29,
  };

  /// Converts an amount from one currency to another using official pegged and market rates.
  static num convert(num amount, {required String from, required String to}) {
    final f = from.trim().toUpperCase();
    final t = to.trim().toUpperCase();
    if (f == t || amount <= 0) return amount;
    final rateFrom = _sarRates[f] ?? 1.0;
    final rateTo = _sarRates[t] ?? 1.0;
    final inSar = amount * rateFrom;
    final inTarget = inSar / rateTo;
    return inTarget;
  }
}
