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
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
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

    final primaryAiColor = isDark
        ? const Color(0xFFA78BFA) // soft violet
        : const Color(0xFF7C3AED); // rich purple

    final borderColor = _isFocused
        ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF6366F1))
        : (isDark
            ? const Color(0xFF818CF8).withValues(alpha: 0.35)
            : const Color(0xFF818CF8).withValues(alpha: 0.5));

    final backgroundColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Colors.white;

    final hint = widget.hintText ??
        (widget.placeholderKey != null
            ? context.tr(widget.placeholderKey!)
            : (isArabic
                ? 'أرخص الرحلات المباشرة مع...'
                : 'Cheapest direct flights with...'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Capsule Search Bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.6 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                    : const Color(0xFF6366F1).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              // Sparkle / AI icon (always start side)
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF67E8F9), const Color(0xFFA78BFA)]
                      : [const Color(0xFF7C3AED), const Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),

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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
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
                          ? AppColors.muted
                          : const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),

              // Suffix Actions (Clear button & Powered by AI Badge)
              if (hasText) ...[
                GestureDetector(
                  onTap: _handleClear,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: isDark ? AppColors.muted : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // "مدعوم بالذكاء الاصطناعي ✦"
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryAiColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      context.tr('poweredByAi'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: primaryAiColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Quick AI Suggestion Chips Carousel
        if (widget.showPrompts && widget.prompts.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.prompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final prompt = widget.prompts[index];
                final isSelected = widget.controller.text.trim() == prompt.query.trim();

                return InkWell(
                  onTap: () => _handlePromptTap(prompt),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryAiColor.withValues(alpha: isDark ? 0.28 : 0.14)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? primaryAiColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.4 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryAiColor.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (prompt.icon != null) ...[
                          Icon(
                            prompt.icon,
                            size: 13,
                            color: isSelected
                                ? primaryAiColor
                                : (isDark ? AppColors.tealLight : AppColors.muted),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          prompt.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? (isDark ? Colors.white : primaryAiColor)
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

