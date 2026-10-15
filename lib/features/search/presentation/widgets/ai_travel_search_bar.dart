import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class AiSearchPromptChip {
  const AiSearchPromptChip({
    required this.label,
    required this.query,
    this.icon,
  });

  final String label;
  final String query;
  final IconData? icon;
}

/// A search bar styled like the Almosafer AI search bar with:
/// - Rounded pill / capsule border with subtle indigo/purple tint
/// - AI sparkle icon
/// - Live natural language typing
/// - "مدعوم بالذكاء الاصطناعي ✦" badge
/// - Instant clear button
/// - Quick interactive AI suggestions carousel
class AiTravelSearchBar extends StatefulWidget {
  const AiTravelSearchBar({
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.hintText,
    this.placeholderKey,
    this.prompts = const [],
    this.onClear,
    this.showPrompts = true,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final String? hintText;
  final String? placeholderKey;
  final List<AiSearchPromptChip> prompts;
  final VoidCallback? onClear;
  final bool showPrompts;

  @override
  State<AiTravelSearchBar> createState() => _AiTravelSearchBarState();
}

class _AiTravelSearchBarState extends State<AiTravelSearchBar> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _onTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(AiTravelSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _handleClear() {
    widget.controller.clear();
    widget.onChanged('');
    if (widget.onClear != null) {
      widget.onClear!();
    }
    setState(() {});
  }

  void _handlePromptTap(AiSearchPromptChip prompt) {
    final current = widget.controller.text.trim();
    if (current == prompt.query.trim()) {
      // Toggle off if already selected
      _handleClear();
    } else {
      widget.controller.text = prompt.query;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: prompt.query.length),
      );
      widget.onChanged(prompt.query);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasText = widget.controller.text.trim().isNotEmpty;


    final borderColor = _isFocused
        ? (isDark ? AppColors.orange : AppColors.teal)
        : (isDark
            ? AppColors.orange.withValues(alpha: 0.35)
            : AppColors.teal.withValues(alpha: 0.22));

    final backgroundColor = isDark
        ? const Color(0xFF071E36)
        : Colors.white;

    final hint = widget.hintText ??
        (widget.placeholderKey != null
            ? context.tr(widget.placeholderKey!)
            : (isArabic
                ? 'ابحث عن رحلة، وجهة، أو شركة طيران...'
                : 'Search flight, destination, or airline...'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Premium Squircle Search Bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    ? (isDark ? AppColors.orange : AppColors.teal)
                        .withValues(alpha: isDark ? 0.3 : 0.16)
                    : (isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : const Color(0xFF0F172A).withValues(alpha: 0.06)),
                blurRadius: _isFocused ? 14 : 10,
                offset: const Offset(0, 3),
                spreadRadius: _isFocused ? 1 : 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // Dedicated Squircle Search Icon Anchor Badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isFocused
                      ? (isDark ? AppColors.orange : AppColors.teal)
                      : (isDark
                          ? AppColors.orange.withValues(alpha: 0.2)
                          : const Color(0xFF0284C7).withValues(alpha: 0.09)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: _isFocused
                      ? Colors.white
                      : (isDark ? AppColors.orangeLight : AppColors.teal),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),

              // Search Text Input
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (val) {
                    widget.onChanged(val);
                    setState(() {});
                  },
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.navy,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),

              // Clear Button (Interactive circular button when text is entered)
              if (hasText)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleClear,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        // Quick Suggestion Chips Carousel
        if (widget.showPrompts && widget.prompts.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.prompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = widget.prompts[index];
                final isSelected = widget.controller.text.trim() == prompt.query.trim();

                return InkWell(
                  onTap: () => _handlePromptTap(prompt),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [AppColors.teal, Color(0xFF0275B1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? const Color(0xFF0C2442)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.teal
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.4 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.28),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.03,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (prompt.icon != null) ...[
                          Icon(
                            prompt.icon,
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFF38BDF8) : AppColors.teal),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          prompt.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : AppColors.navy),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Polished empty state card displayed when smart search / filter has no matches
class AiSearchEmptyState extends StatelessWidget {
  const AiSearchEmptyState({
    required this.title,
    required this.message,
    required this.onClear,
    this.accentColor,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onClear;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = accentColor ?? (isDark ? AppColors.teal : AppColors.orange);

    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.travel_explore_rounded,
              size: 40,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              context.tr('clearSearch'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

