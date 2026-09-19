part of 'profile_page.dart';

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({this.name, this.email});

  final String? name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final isGuest = name == null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navySoft,
            AppColors.teal.withValues(alpha: .85),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: .2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle Safer Be Logo Watermark in Background
          Positioned(
            right: -15,
            bottom: -20,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                AppAssets.brandSymbol,
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .3),
                    width: 2,
                  ),
                ),
                child: isGuest
                    ? Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white.withValues(alpha: .7),
                        size: 30,
                      )
                    : Center(
                        child: Text(
                          name!.isNotEmpty ? name![0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isGuest
                                ? context.tr('guest')
                                : name ?? context.tr('traveler'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (!isGuest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'VIP جوك',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isGuest)
                      Text(
                        context.tr('guestBody'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .72),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      )
                    else ...[
                      Text(
                        email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .72),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: .9),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                context.tr('loggedIn'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
