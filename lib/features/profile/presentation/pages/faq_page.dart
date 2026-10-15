import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqItem> _getFlightsFaq(bool isAr) => isAr
      ? const [
          _FaqItem(
            q: 'ما هي التذكرة الالكترونية ؟',
            a: 'التذكرة الإلكترونية هي وثيقة سفر رقمية تؤكد حجزك وتتضمن رقم التذكرة والرمز المرجعي للحجز (PNR) وتفاصيل مسار الرحلة والمسافرين، وتغنيك تماماً عن التذاكر الورقية.',
          ),
          _FaqItem(
            q: 'كيف يمكنني إجراء حجز؟',
            a: 'يمكنك اختيار مطار المغادرة والوجهة وتاريخ الرحلة، ثم تحديد الرحلة والدرجة المناسبة، وإدخال بيانات المسافرين وإتمام الدفع الآمن لتأكيد الحجز فورياً.',
          ),
          _FaqItem(
            q: 'كيف أتأكد من حجزي ؟',
            a: 'فور إتمام عملية الدفع ستصلك رسالة تأكيد عبر البريد الإلكتروني والرسائل النصية تحوي تذكرتك الإلكترونية، كما يمكنك عرض التذكرة وتفاصيلها في تبويب "رحلاتي".',
          ),
          _FaqItem(
            q: 'هل بإمكاني تعديل أو إلغاء حجزي عبر تطبيق سافر بي؟',
            a: 'نعم، يتيح لك التطبيق استعراض شروط التذكرة وتقديم طلب التعديل أو الإلغاء مباشرة، أو عبر التواصل مع خدمة العملاء بالواتساب على مدار الساعة وفقاً لسياسة شركة الطيران.',
          ),
          _FaqItem(
            q: 'ما الفرق بين الرحلة المباشرة والرحلات بدون توقف والرحلة المتابعة؟',
            a: 'الرحلة بدون توقف (Non-stop) تطير مباشرة دون أي هبوط. الرحلة المباشرة (Direct) قد تتوقف مؤقتاً للتزود بالوقود دون تغيير الطائرة. رحلة المتابعة (Connecting) تتطلب تغيير الطائرة في مطار ترانزيت.',
          ),
          _FaqItem(
            q: 'كيف أتأكد من إلغاء حجزي؟',
            a: 'يصلك إشعار فوري وبريد إلكتروني يؤكد الإلغاء وتفاصيل المبالغ المستردة، وتتحول حالة الحجز في صفحة "رحلاتي" إلى "ملغاة".',
          ),
          _FaqItem(
            q: 'هل لدي وقت كافي بين الرحلتين في رحلة المتابعة؟',
            a: 'نعم، جميع الرحلات المتاحة على سافر بي تلتزم بالحد الأدنى المعياري لوقت الترانزيت (MCT) المعتمد من قبل شركات الطيران والمطارات لضمان وصولك وأمتعتك بأمان.',
          ),
          _FaqItem(
            q: 'هل يمكنني أن أحجز رحلة مغادرة من بلد آخر غير الذي أتواجد فيه حالياً؟',
            a: 'نعم بكل تأكيد، يمكنك حجز رحلات دولية أو داخلية بين أي وجهتين في العالم بسهولة ودفعها بالريال السعودي أو العملة المفضلة لديك.',
          ),
          _FaqItem(
            q: 'هل تطبيق سافر بي آمن للدفع عبر الانترنت ؟',
            a: 'نعم، نستخدم أعلى معايير التشفير المصرفي المعتمدة (PCI DSS)، وندعم وسائل الدفع الآمنة كـ مدى، فيزا، ماستركارد، وApple Pay.',
          ),
          _FaqItem(
            q: 'كيف يمكنني استخدام كود الخصم؟',
            a: 'يمكنك إدخال كود الخصم في خانة الرمز الترويجي قبل صفحة الدفع، أو تطبيقه من خلال المحفظة وسيتم خصم القيمة فورياً من الإجمالي.',
          ),
          _FaqItem(
            q: 'هل يمكنني حجز أكثر من 9 مقاعد في نفس العملية ؟',
            a: 'وفقاً لأنظمة شركات الطيران العالمية، الحد الأقصى للحجز الفردي هو 9 مسافرين. للحجوزات الجماعية الكبيرة تواصل مع فريق المجموعات عبر الواتساب لتوفير عروض خاصة.',
          ),
          _FaqItem(
            q: 'هل يمكنني إنجاز إجراءات السفر عبر الإنترنت؟',
            a: 'نعم، تفتح معظم شركات الطيران التسجيل عبر الإنترنت قبل 24 إلى 48 ساعة من موعد الإقلاع باستخدام رمز الحجز (PNR) واسم العائلة.',
          ),
        ]
      : const [
          _FaqItem(
            q: 'What is an electronic ticket (e-ticket)?',
            a: 'An e-ticket is a digital flight record containing your booking reference (PNR), passenger details, and itinerary, replacing traditional paper tickets completely.',
          ),
          _FaqItem(
            q: 'How can I make a flight booking?',
            a: 'Choose your origin, destination, and travel dates. Select your preferred airline, enter passenger information, and proceed with secure payment to get instant confirmation.',
          ),
          _FaqItem(
            q: 'How do I confirm my booking?',
            a: 'Immediately upon payment, you will receive an SMS and email with your e-ticket. You can also view it in the "My Trips" tab.',
          ),
          _FaqItem(
            q: 'Can I modify or cancel my booking via Safer Be?',
            a: 'Yes, you can request changes or cancellation directly from your booking details or via 24/7 WhatsApp support, according to the airline fare rules.',
          ),
          _FaqItem(
            q: 'What is the difference between direct, non-stop, and connecting flights?',
            a: 'A non-stop flight flies directly to the destination. A direct flight may make a technical stop without plane change. A connecting flight requires changing planes at a transit airport.',
          ),
          _FaqItem(
            q: 'How do I verify cancellation?',
            a: 'You will receive an official cancellation confirmation email and SMS, and your trip status will update to "Cancelled" in the app.',
          ),
          _FaqItem(
            q: 'Do I have enough transit time between connecting flights?',
            a: 'Yes, all itineraries follow the official Minimum Connecting Time (MCT) enforced by airports and airlines to ensure passengers and luggage transfer smoothly.',
          ),
          _FaqItem(
            q: 'Can I book a flight departing from another country?',
            a: 'Yes, Safer Be supports flight routes worldwide between any two cities, payable in SAR or your local currency.',
          ),
          _FaqItem(
            q: 'Is Safer Be secure for online payments?',
            a: 'Yes, we employ PCI-DSS certified banking grade encryption and support Mada, Visa, Mastercard, and Apple Pay.',
          ),
          _FaqItem(
            q: 'How do I use a discount or promo code?',
            a: 'Enter your promo code on the payment summary screen or redeem it via your Wallet to apply the discount immediately.',
          ),
          _FaqItem(
            q: 'Can I book for more than 9 passengers at once?',
            a: 'Airline systems limit individual bookings to 9 passengers. For larger group bookings, contact our group desk via WhatsApp for special fares.',
          ),
          _FaqItem(
            q: 'Can I complete online check-in?',
            a: 'Yes, most airlines open online check-in 24 to 48 hours before flight departure using your PNR booking reference.',
          ),
        ];

  List<_FaqItem> _getHotelsFaq(bool isAr) => isAr
      ? const [
          _FaqItem(
            q: 'ما هي أوقات تسجيل الوصول والمغادرة في الفنادق؟',
            a: 'عادة ما يبدأ تسجيل الوصول من الساعة 2:00 أو 3:00 مساءً، وتسجيل المغادرة حتى الساعة 12:00 ظهراً، ويمكن طلب تسجيل مبكر أو متأخر حسب إمكانية الفندق.',
          ),
          _FaqItem(
            q: 'هل يشمل سعر الغرفة وجبة الإفطار؟',
            a: 'يتم توضيح ما إذا كان الحجز يشمل الإفطار في تفاصيل الغرفة وتأكيد الحجز قبل إتمام الدفع.',
          ),
          _FaqItem(
            q: 'كيف أعرف ما إذا كان الحجز قابلاً للإلغاء المجاني؟',
            a: 'تظهر علامة "إلغاء مجاني" بوضوح مع تحديد آخر موعد للإلغاء دون أي رسوم بجانب كل غرفة.',
          ),
          _FaqItem(
            q: 'ما هي الوثائق المطلوبة عند تسجيل الدخول في الفندق؟',
            a: 'يلزم إبراز بطاقة الهوية الوطنية أو الإقامة للمواطنين والمقيمين، أو جواز السفر للمسافرين الدوليين، مع إظهار تأكيد حجز سافر بي.',
          ),
        ]
      : const [
          _FaqItem(
            q: 'What are standard hotel check-in and check-out times?',
            a: 'Check-in is typically from 2:00 PM or 3:00 PM, and check-out is by 12:00 PM noon. Early check-in or late check-out can be requested subject to availability.',
          ),
          _FaqItem(
            q: 'Does the room price include breakfast?',
            a: 'Whether breakfast is included is clearly indicated on each room option and on your confirmation voucher.',
          ),
          _FaqItem(
            q: 'How do I know if the reservation offers free cancellation?',
            a: 'A "Free Cancellation" tag with the exact deadline is displayed alongside each eligible room rate.',
          ),
          _FaqItem(
            q: 'What documents are required at hotel check-in?',
            a: 'A valid National ID or Iqama for Saudi citizens and residents, or passport for international visitors, along with your Safer Be booking voucher.',
          ),
        ];

  List<_FaqItem> _getActivitiesFaq(bool isAr) => isAr
      ? const [
          _FaqItem(
            q: 'كيف تعمل خدمة تنقلات المطار؟',
            a: 'يقوم السائق باستقبالك في صالة الوصول حاملاً لوحة باسمك، ويتم إرسال بيانات السائق والتواصل المباشر قبل موعد الرحلة.',
          ),
          _FaqItem(
            q: 'ماذا يحدث إذا تأخرت رحلتي الجوية؟',
            a: 'يقوم فريق التنقلات بتتبع رقم الرحلة تلقائياً لضبط موعد وصول السائق دون أي رسوم إضافية على التأخير.',
          ),
        ]
      : const [
          _FaqItem(
            q: 'How does the airport transfer service work?',
            a: 'Your private driver will greet you at the arrival hall holding a name sign. Driver details and contact info are provided before your flight arrival.',
          ),
          _FaqItem(
            q: 'What happens if my flight is delayed?',
            a: 'Our transfer dispatch monitors your flight number live to adjust driver pickup time automatically without delay fees.',
          ),
        ];

  List<_FaqItem> _filterItems(List<_FaqItem> items) {
    if (_searchQuery.trim().isEmpty) return items;
    final q = _searchQuery.toLowerCase().trim();
    return items
        .where((item) =>
            item.q.toLowerCase().contains(q) || item.a.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final flightsFaq = _filterItems(_getFlightsFaq(isAr));
    final hotelsFaq = _filterItems(_getHotelsFaq(isAr));
    final activitiesFaq = _filterItems(_getActivitiesFaq(isAr));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('frequentlyAskedQuestions'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.navySoft : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: context.tr('searchFaqPlaceholder'),
                  hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.teal,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.teal,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: [
              Tab(text: context.tr('faqTabFlights')),
              Tab(text: context.tr('faqTabHotels')),
              Tab(text: context.tr('faqTabActivities')),
            ],
          ),

          // Tab Views with FAQs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FaqListView(items: flightsFaq),
                _FaqListView(items: hotelsFaq),
                _FaqListView(items: activitiesFaq),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}

class _FaqListView extends StatelessWidget {
  const _FaqListView({required this.items});

  final List<_FaqItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 56, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                context.tr('noMatchingFlightsFound'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('tryDifferentKeywords'),
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Text(
                item.q,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              leading: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.teal,
                size: 20,
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black26
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.a,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
