import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/api_travel_search_repository.dart';
import '../../domain/entities/app_currency.dart';

/// Shows a bottom sheet allowing the user to choose an active currency.
/// Once a currency is chosen, [onSelected] is called immediately with the new currency code.
Future<String?> showCurrencyPickerSheet(
  BuildContext context, {
  required String currentCurrency,
  ValueChanged<String>? onSelected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CurrencyPickerSheet(
      currentCurrency: currentCurrency,
      onSelected: onSelected,
    ),
  );
}

class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({
    required this.currentCurrency,
    this.onSelected,
    super.key,
  });

  final String currentCurrency;
  final ValueChanged<String>? onSelected;

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<AppCurrency> _currencies = AppCurrency.supportedCurrencies;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchLiveCurrencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveCurrencies() async {
    try {
      final repository = ApiTravelSearchRepository();
      final remoteList = await repository.currencies();
      if (remoteList.isNotEmpty && mounted) {
        final parsed = <AppCurrency>[];
        final seenCodes = <String>{};

        for (final item in remoteList) {
          final c = AppCurrency.fromJson(item);
          if (c.code.isNotEmpty && !seenCodes.contains(c.code)) {
            seenCodes.add(c.code);
            parsed.add(c);
          }
        }

        // Add standard ones if not already present
        for (final s in AppCurrency.supportedCurrencies) {
          if (!seenCodes.contains(s.code)) {
            seenCodes.add(s.code);
            parsed.add(s);
          }
        }

        setState(() {
          _currencies = parsed;
        });
      }
    } catch (_) {
      // Keep supported defaults on network failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;

    final filtered = _currencies.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.nameAr.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161C26) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 18,
                offset: Offset(0, -3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Top drag bar & header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.currency_exchange_rounded,
                                color: AppColors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('selectCurrency'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF1E2633),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _query = val.trim()),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('searchCurrency'),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.orange,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF222B3A)
                        : const Color(0xFFF3F6FA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Currency List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final curr = filtered[index];
                    final isSelected = curr.code.toUpperCase() ==
                        widget.currentCurrency.toUpperCase();

                    return Material(
                      color: isSelected
                          ? (isDark
                              ? AppColors.orange.withValues(alpha: 0.18)
                              : const Color(0xFFFFF3E0))
                          : (isDark
                              ? const Color(0xFF1E2633)
                              : const Color(0xFFFAFCFF)),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onSelected?.call(curr.code);
                          Navigator.of(context).pop(curr.code);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.orange
                                  : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.06)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Flag emoji / icon
                              Text(
                                curr.flag,
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 12),

                              // Currency Code Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.orange
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.05)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  curr.code,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name & Symbol
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      curr.localizedName(locale),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E2633),
                                      ),
                                    ),
                                    Text(
                                      'Symbol: ${curr.symbol}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection indicator
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A stylish glassmorphic button to display in AppBar actions or banners.
/// Tapping it opens [showCurrencyPickerSheet].
class GlassCurrencyPickerButton extends StatelessWidget {
  const GlassCurrencyPickerButton({
    required this.currency,
    required this.onSelected,
    this.compact = false,
    this.height,
    super.key,
  });

  final String currency;
  final ValueChanged<String> onSelected;
  final bool compact;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? (compact ? 36.0 : 38.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final selected = await showCurrencyPickerSheet(
            context,
            currentCurrency: currency,
            onSelected: onSelected,
          );
          if (selected != null && selected != currency) {
            onSelected(selected);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: effectiveHeight,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.currency_exchange_rounded,
                size: compact ? 13 : 15,
                color: Colors.white,
              ),
              SizedBox(width: compact ? 4 : 5),
              Text(
                currency.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 11.5 : 12.5,
                  letterSpacing: compact ? 0.2 : 0.3,
                ),
              ),
              SizedBox(width: compact ? 2 : 3),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: compact ? 14 : 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
