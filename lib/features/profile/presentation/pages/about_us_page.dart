import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_store_badges.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final logoAsset = AppAssets.getLogo(
      isDark: isDark,
      isArabic: isArabic,
      withoutBackground: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('aboutUs'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // App Logo & Version Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.navySoft : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Image.asset(
                      AppAssets.appIcon,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr('appVersion'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF16A34A),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('yourVersionIsLatest'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Legal & Info Group
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _AboutTile(
                  icon: Icons.business_rounded,
                  title: context.tr('companyDetails'),
                  onTap: () => _showCompanyDetailsSheet(context),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _AboutTile(
                  icon: Icons.description_outlined,
                  title: context.tr('termsAndConditions'),
                  onTap: () => _showTextContentSheet(
                    context,
                    title: context.tr('termsAndConditions'),
                    content: isArabic
                        ? 'شروط وأحكام استخدام منصة وتطبيق سافر بي:\n\n'
                            '1. القبول بالشروط: باستخدامك لتطبيق سافر بي، فإنك توافق على الالتزام بجميع الشروط والأحكام المطبقة على حجوزات الطيران والفنادق والتنقلات.\n'
                            '2. شروط الحجز والأسعار: تخضع جميع أسعار التذاكر والغرف لتوفرها في وقت إتمام الدفع. تلتزم سافر بي بعرض السعر النهائي شاملاً ضريبة القيمة المضافة ورسوم الخدمة.\n'
                            '3. التعديل والإلغاء: تطبق السياسات الخاصة بكل شركة طيران أو فندق وفقاً لقواعد التعرفة المختارة.\n'
                            '4. المسؤولية القانونية: منصة سافر بي مرخصة نظامياً بالمملكة العربية السعودية وتخضع لأنظمة الهيئة العامة للطيران المدني ووزارة السياحة.'
                        : 'Terms & Conditions for using Safer Be:\n\n'
                            '1. Acceptance: By using the Safer Be app, you agree to comply with all applicable terms governing flight, hotel, and transfer bookings.\n'
                            '2. Pricing & Availability: All fares and room rates are subject to live availability. Safer Be displays final prices inclusive of VAT and applicable fees.\n'
                            '3. Changes & Cancellations: Individual airline and hotel fare rules apply to any modification or cancellation request.\n'
                            '4. Regulatory Compliance: Safer Be is a fully accredited entity operating under the regulations of the General Authority of Civil Aviation (GACA) and the Ministry of Tourism in Saudi Arabia.',
                  ),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _AboutTile(
                  icon: Icons.shield_outlined,
                  title: context.tr('dataProcessingTerms'),
                  onTap: () => _showTextContentSheet(
                    context,
                    title: context.tr('dataProcessingTerms'),
                    content: isArabic
                        ? 'شروط وأحكام معالجة البيانات:\n\n'
                            'نلتزم في سافر بي بحماية بياناتك الشخصية ومعالجتها وفقاً لنظام حماية البيانات الشخصية بالمملكة العربية السعودية (PDPL).\n'
                            '• يتم جمع البيانات الأساسية (الاسم، البريد، الهاتف، تفاصيل المسافرين) فقط لغرض إصدار التذاكر وإتمام الحجوزات.\n'
                            '• بيانات الدفع والبطاقات البنكية مشفرة بالكامل ولا يتم تخزين أرقام بطاقاتك الحساسة على خوادمنا.\n'
                            '• يحق لك طلب تحديث بياناتك أو حذف حسابك في أي وقت من خلال إعدادات التطبيق.'
                        : 'Data Processing Terms:\n\n'
                            'Safer Be complies strictly with the Saudi Personal Data Protection Law (PDPL).\n'
                            '• We collect basic traveler details solely to execute bookings and issue tickets.\n'
                            '• Payment and card details are encrypted via certified PCI-DSS gateways; sensitive card numbers are never stored on our servers.\n'
                            '• You retain full rights to update your data or delete your account at any time via App Settings.',
                  ),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _AboutTile(
                  icon: Icons.privacy_tip_outlined,
                  title: context.tr('privacyPolicy'),
                  onTap: () => _showTextContentSheet(
                    context,
                    title: context.tr('privacyPolicy'),
                    content: isArabic
                        ? 'سياسة الخصوصية لسافر بي:\n\n'
                            'خصوصيتك أولويتنا القصوى. توضح هذه السياسة كيف نقوم بحماية معلوماتك الشخصية:\n'
                            '• نستخدم بروتوكولات التشفير المتقدمة (TLS 1.3) لضمان سرية الاتصال.\n'
                            '• لا نقوم ببيع أو مشاركة بياناتك مع أي أطراف ثالثة لأغراض تجارية غير مرتبطة برحلتك.\n'
                            '• تقتصر مشاركة بياناتك على مزودي الرحلات المعتمدين (شركات الطيران، الفنادق، وشركات النقل) لإتمام حجزك فقط.'
                        : 'Safer Be Privacy Policy:\n\n'
                            'Your privacy is our top priority. This policy outlines how we safeguard your information:\n'
                            '• Advanced TLS 1.3 encryption protocols protect all communication.\n'
                            '• We never sell or share your personal data with third parties for unrequested marketing purposes.\n'
                            '• Information sharing is strictly confined to confirmed travel suppliers (airlines, hotels, transport providers) to fulfill your booking.',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Rating Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              context.tr('appRating'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _AboutTile(
                  icon: Icons.rate_review_outlined,
                  title: context.tr('shareYourFeedback'),
                  onTap: () => _showFeedbackDialog(context),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _AboutTile(
                  icon: Icons.star_outline_rounded,
                  title: context.tr('rateApp'),
                  onTap: () => ShareAppSheet.show(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompanyDetailsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business_rounded, color: AppColors.teal, size: 26),
                const SizedBox(width: 10),
                Text(
                  context.tr('companyOverviewTitle'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('companyOverviewBody'),
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 20),
            Center(
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  minimumSize: const Size(140, 44),
                ),
                child: Text(context.tr('apply')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextContentSheet(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      content,
                      style: const TextStyle(fontSize: 14, height: 1.6),
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

  void _showFeedbackDialog(BuildContext context) {
    var rating = 5;
    final commentController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.tr('rateUsPrompt'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFFFB23F),
                      size: 32,
                    ),
                    onPressed: () => setState(() => rating = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: context.tr('writeCommentOptional'),
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('feedbackSubmitted')),
                    backgroundColor: AppColors.teal,
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              child: Text(context.tr('submitFeedback')),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.teal, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
      trailing: Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.chevron_left_rounded
            : Icons.chevron_right_rounded,
        color: AppColors.muted,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
