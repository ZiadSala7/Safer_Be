import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_logo.dart';

class SaferBeSupportChatSheet extends StatefulWidget {
  const SaferBeSupportChatSheet({
    this.initialQuery,
    this.bookingReference,
    super.key,
  });

  final String? initialQuery;
  final String? bookingReference;

  static Future<void> show(
    BuildContext context, {
    String? initialQuery,
    String? bookingReference,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SaferBeSupportChatSheet(
        initialQuery: initialQuery,
        bookingReference: bookingReference,
      ),
    );
  }

  @override
  State<SaferBeSupportChatSheet> createState() => _SaferBeSupportChatSheetState();
}

class _ChatMessage {
  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.actionWidget,
  });

  final String text;
  final bool isUser;
  final String time;
  final Widget? actionWidget;
}

class _SaferBeSupportChatSheetState extends State<SaferBeSupportChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  int _activeTab = 0; // 0: AI Assistant, 1: Live Agent

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    final now = _formatTime(DateTime.now());
    _messages.add(
      _ChatMessage(
        text: 'مرحباً بك في خدمة عملاء سافر بي! 🌟\nأنا مستشارك الذكي للسفر، كيف أقدر أساعدك اليوم في حجوزاتك أو استفساراتك؟',
        isUser: false,
        time: now,
      ),
    );

    if (widget.bookingReference != null && widget.bookingReference!.isNotEmpty) {
      _messages.add(
        _ChatMessage(
          text: 'رقم مرجع الحجز المرتبط: ${widget.bookingReference}',
          isUser: true,
          time: now,
        ),
      );
      _messages.add(
        _ChatMessage(
          text: 'تم استدعاء تفاصيل الحجز #${widget.bookingReference}. جاهزون لمساعدتك في أي تعديل أو استفسار.',
          isUser: false,
          time: now,
        ),
      );
    } else if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _sendMessage(widget.initialQuery!);
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void _sendMessage(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _textController.clear();
    final now = _formatTime(DateTime.now());

    setState(() {
      _messages.add(_ChatMessage(text: clean, isUser: true, time: now));
      _isTyping = true;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _respondTo(clean);
    });
  }

  void _respondTo(String query) {
    final now = _formatTime(DateTime.now());
    final lower = query.toLowerCase();

    String reply;
    Widget? action;

    if (lower.contains('طيران') || lower.contains('تذكرة') || lower.contains('flight')) {
      reply = 'بخصوص حجوزات الطيران: يمكنك تعديل الموعد، إضافة أمتعة إضافية، أو اختيار المقاعد مباشرة. هل ترغب في عرض الرحلات البديلة؟';
      action = _ChatFlightQuickCard(onSelect: () {
        _sendMessage('تأكيد تعديل موعد الرحلة لغد 10:30 صباحاً');
      });
    } else if (lower.contains('فندق') || lower.contains('غرفة') || lower.contains('hotel')) {
      reply = 'جميع حجوزات الفنادق عبر سافر بي مضمونة وموثقة مع الفندق مباشرة. يمكنك طلب تسجيل دخول مبكر أو تعديل الإقامة بسهولة.';
    } else if (lower.contains('نقاط') || lower.contains('ولاء') || lower.contains('جوك') || lower.contains('points')) {
      reply = 'رصيد عضويتك في نادي سافر بي (جوك VIP) يمنحك نقاطاً مضاعفة مع كل حجز، واسترداد نقدي فوري على رحلاتك القادمة!';
    } else if (lower.contains('إلغاء') || lower.contains('استرداد') || lower.contains('cancel')) {
      reply = 'وفقاً لسياسة الضمان الذهبي من سافر بي، يتم فحص شروط الاسترداد الخاصة بالتذكرة أو الإقامة وتنفيذ الإلغاء في أسرع وقت.';
    } else {
      reply = 'شكراً لتواصلك مع سافر بي! تم توثيق طلبك وسيقوم مستشار السفر بمتابعة التفاصيل معك فوراً لضمان تجربة سفر استثنائية. ✈️';
    }

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
        text: reply,
        isUser: false,
        time: now,
        actionWidget: action,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: media.size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.navySoft : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Branded Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.navy,
                  Color(0xFF0C3058),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E3E66), width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Safer Be Brand Avatar
                    const SaferBeBrandAvatar(
                      size: 44,
                      isVerified: true,
                      backgroundColor: AppColors.navy,
                      borderColor: AppColors.teal,
                    ),
                    const SizedBox(width: 12),

                    // Header Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                context.tr('onboardingSupportHeader'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.tealLight,
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  '24/7 VIP',
                                  style: TextStyle(
                                    color: AppColors.tealLight,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF4ADE80),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'مستشار السفر متصل الآن · استجابة فورية',
                                style: TextStyle(
                                  color: Color(0xFF86EFAC),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Close Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Channel Selector Switch
                Container(
                  height: 34,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _activeTab == 0
                                  ? AppColors.teal
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'المساعد الذكي',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _activeTab == 1
                                  ? AppColors.orange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.headset_mic_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'مستشار بشري مباشر',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF081C33) : const Color(0xFFF3F7FB),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _TypingIndicatorBubble();
                  }

                  final msg = _messages[index];
                  return _ChatBubble(message: msg);
                },
              ),
            ),
          ),

          // Quick Topic Chips
          Container(
            height: 38,
            color: isDark ? const Color(0xFF081C33) : const Color(0xFFF3F7FB),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TopicChip(
                  icon: Icons.flight_takeoff_rounded,
                  label: 'تعديل موعد طيران',
                  onTap: () => _sendMessage('أحتاج تعديل موعد رحلة الطيران'),
                ),
                const SizedBox(width: 6),
                _TopicChip(
                  icon: Icons.hotel_rounded,
                  label: 'تأكيد حجز الفندق',
                  onTap: () => _sendMessage('استفسار عن تأكيد حجز الفندق وتفاصيله'),
                ),
                const SizedBox(width: 6),
                _TopicChip(
                  icon: Icons.stars_rounded,
                  label: 'رصيد نقاط جوك VIP',
                  onTap: () => _sendMessage('كم رصيد نقاطي في نادي سافر بي؟'),
                ),
                const SizedBox(width: 6),
                _TopicChip(
                  icon: Icons.receipt_long_rounded,
                  label: 'الفاتورة والضريبة',
                  onTap: () => _sendMessage('أريد الحصول على الفاتورة الضريبية'),
                ),
              ],
            ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              8 + media.viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.navySoft : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E3A5F)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.teal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF071A33)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E3A5F)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _sendMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'اكتب استفسارك لمستشار سافر بي...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_textController.text),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.orange, AppColors.orangeLight],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isUser) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 40),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.teal, Color(0xFF0284C7)],
            ),
            borderRadius: BorderRadius.circular(16).copyWith(
              topRight: const Radius.circular(2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.time,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    color: Color(0xFF93C5FD),
                    size: 13,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Agent message
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal, width: 1.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(3),
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
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navySoft : Colors.white,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    topLeft: const Radius.circular(2),
                  ),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (message.actionWidget != null) ...[
                      const SizedBox(height: 8),
                      message.actionWidget!,
                    ],
                    const SizedBox(height: 3),
                    Align(
                      alignment: AlignmentDirectional.bottomEnd,
                      child: Text(
                        message.time,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatFlightQuickCard extends StatelessWidget {
  const _ChatFlightQuickCard({required this.onSelect});

  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: AppColors.orange,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'الرياض (RUH) ➔ دبي (DXB)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              const Text(
                'مباشر',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'غداً · المغادرة 10:30 ص · الوصول 1:45 م',
            style: TextStyle(fontSize: 10, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSelect,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'تأكيد تعديل الموعد',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.teal),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicatorBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: AppColors.teal,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'مستشار سافر بي يكتب الآن...',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
