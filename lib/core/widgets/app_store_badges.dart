import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';
import 'brand_logo.dart';

abstract final class AppStoreLinks {
  static const String googlePlayUrl =
      'https://play.google.com/store/apps/details?id=com.darkNode.saferBe';

  /// Set this once the iOS App Store build is approved and published.
  static const String? iosAppStoreUrl = null;

  static String getShareMessage(BuildContext context) {
    final isAr = context.l10n.isArabic;
    if (isAr) {
      return 'حمّل تطبيق سافر بي الآن لحجز أرخص رحلات الطيران والفنادق العالمية بأعلى معايير الأمان ✈️🏨:\n$googlePlayUrl';
    } else {
      return 'Download Safer Be app now for the best flight & hotel booking deals worldwide ✈️🏨:\n$googlePlayUrl';
    }
  }

  static Future<void> launchGooglePlay() async {
    final uri = Uri.tryParse(googlePlayUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> launchAppStore(BuildContext context) async {
    if (iosAppStoreUrl != null && iosAppStoreUrl!.isNotEmpty) {
      final uri = Uri.tryParse(iosAppStoreUrl!);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('iosComingSoonMsg')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: context.tr('copyShareLink'),
            textColor: AppColors.orangeLight,
            onPressed: () => copyShareLink(context),
          ),
        ),
      );
    }
  }

  static Future<void> copyShareLink(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: googlePlayUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(context.tr('shareLinkCopied'))),
            ],
          ),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  static Future<void> shareViaWhatsApp(BuildContext context) async {
    final text = getShareMessage(context);
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Google Play Store download badge inspired by official store badges.
class GooglePlayStoreBadge extends StatelessWidget {
  const GooglePlayStoreBadge({
    super.key,
    this.width,
    this.height = 48,
    this.onTap,
  });

  final double? width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAr = context.l10n.isArabic;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? AppStoreLinks.launchGooglePlay,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GooglePlayLogoIcon(size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'احصل عليه من' : 'GET IT ON',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        height: 1.1,
                      ),
                    ),
                    const Text(
                      'Google Play',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Apple App Store download badge inspired by official store badges.
class AppStoreBadge extends StatelessWidget {
  const AppStoreBadge({
    super.key,
    this.width,
    this.height = 48,
    this.onTap,
    this.showComingSoonBadge = true,
  });

  final double? width;
  final double height;
  final VoidCallback? onTap;
  final bool showComingSoonBadge;

  @override
  Widget build(BuildContext context) {
    final isAr = context.l10n.isArabic;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => AppStoreLinks.launchAppStore(context),
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.apple_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            isAr ? 'تنزيل من' : 'Download on the',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (showComingSoonBadge &&
                            AppStoreLinks.iosAppStoreUrl == null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isAr ? 'قريباً' : 'Soon',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Text(
                      'App Store',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering the authentic 4-color Google Play logo.
class _GooglePlayLogoIcon extends StatelessWidget {
  const _GooglePlayLogoIcon({this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.08),
      painter: const _GooglePlayPainter(),
    );
  }
}

class _GooglePlayPainter extends CustomPainter {
  const _GooglePlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final pTopLeft = Offset(0, 0);
    final pBottomLeft = Offset(0, h);
    final pApex = Offset(w, h * 0.5);
    final pCenter = Offset(w * 0.58, h * 0.5);

    // 1. Blue Base Triangle (left)
    final bluePaint = Paint()
      ..color = const Color(0xFF0086F8)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final bluePath = Path()
      ..moveTo(pTopLeft.dx, pTopLeft.dy)
      ..lineTo(pBottomLeft.dx, pBottomLeft.dy)
      ..lineTo(pCenter.dx, pCenter.dy)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green Top Polygon
    final greenPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final greenPath = Path()
      ..moveTo(pTopLeft.dx, pTopLeft.dy)
      ..lineTo(pCenter.dx, pCenter.dy)
      ..lineTo(pApex.dx, pApex.dy)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Red Bottom Polygon
    final redPaint = Paint()
      ..color = const Color(0xFFFF334B)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final redPath = Path()
      ..moveTo(pBottomLeft.dx, pBottomLeft.dy)
      ..lineTo(pCenter.dx, pCenter.dy)
      ..lineTo(pApex.dx, pApex.dy)
      ..close();
    canvas.drawPath(redPath, redPaint);

    // 4. Yellow Right Corner
    final yellowPaint = Paint()
      ..color = const Color(0xFFFFD400)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final yellowPath = Path()
      ..moveTo(w * 0.73, h * 0.27)
      ..lineTo(w * 0.73, h * 0.73)
      ..lineTo(pApex.dx, pApex.dy)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A bottom sheet allowing users to download or share the Safer Be app on Google Play & iOS.
class ShareAppSheet extends StatelessWidget {
  const ShareAppSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShareAppSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.l10n.isArabic;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navySoft : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 42,
            height: 4.5,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Header with Avatar & Title
          Row(
            children: [
              const SaferBeBrandAvatar(
                size: 46,
                isVerified: true,
                backgroundColor: AppColors.navy,
                borderColor: AppColors.teal,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('shareAppTitle'),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr('shareAppSubtitle'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Store Badges Row
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: const [
              GooglePlayStoreBadge(width: 155),
              AppStoreBadge(width: 155),
            ],
          ),
          const SizedBox(height: 18),

          // Share Link Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF071B33) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  color: AppColors.teal,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    AppStoreLinks.googlePlayUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => AppStoreLinks.copyShareLink(context),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: Text(
                    context.tr('copyShareLink'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: WhatsApp Share & Copy
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => AppStoreLinks.shareViaWhatsApp(context),
                  icon: const Icon(Icons.chat_rounded, size: 17),
                  label: Text(
                    context.tr('shareViaWhatsApp'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AppStoreLinks.copyShareLink(context),
                  icon: const Icon(Icons.content_copy_rounded, size: 17),
                  label: Text(
                    isAr ? 'نسخ الرابط' : 'Copy Link',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Download App footer section for the home screen footer or profile.
class AppDownloadFooterSection extends StatelessWidget {
  const AppDownloadFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('downloadOurApp'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => ShareAppSheet.show(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.share_rounded,
                      size: 13,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('shareApp'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('downloadOurAppDesc'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10.5,
                color: AppColors.muted,
                height: 1.3,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            GooglePlayStoreBadge(width: 138),
            AppStoreBadge(width: 138),
          ],
        ),
      ],
    );
  }
}
