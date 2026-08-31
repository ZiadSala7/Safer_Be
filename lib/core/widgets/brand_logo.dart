import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';

/// Renders the localized Safer Be logo wordmark.
class SaferBeWordmark extends StatelessWidget {
  const SaferBeWordmark({
    this.height = 36,
    this.width,
    this.fit = BoxFit.contain,
    super.key,
  });

  final double height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.l10n.isArabic;
    return Image.asset(
      isArabic ? AppAssets.logoAr : AppAssets.logoEn,
      height: height,
      width: width,
      fit: fit,
    );
  }
}

/// Renders the circular / squircle Safer Be brand icon badge with an optional verified tick.
class SaferBeBrandAvatar extends StatelessWidget {
  const SaferBeBrandAvatar({
    this.size = 38,
    this.isVerified = true,
    this.backgroundColor,
    this.borderColor,
    this.showBorder = true,
    super.key,
  });

  final double size;
  final bool isVerified;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.navy;
    final border = borderColor ?? AppColors.teal;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(color: border, width: size > 40 ? 2 : 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(size * 0.12),
            child: Image.asset(
              AppAssets.brandSymbol,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Image.asset(
                AppAssets.appIcon,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        if (isVerified)
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                color: const Color(0xFF0284C7),
                size: (size * 0.38).clamp(11.0, 20.0),
              ),
            ),
          ),
      ],
    );
  }
}
