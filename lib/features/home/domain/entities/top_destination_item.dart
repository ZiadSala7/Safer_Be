class TopDestinationItem {
  const TopDestinationItem({
    required this.cityId,
    required this.cityCode,
    required this.cityName,
    required this.countryCode,
    required this.countryName,
    required this.rank,
    required this.destinationCode,
    required this.imageUrl,
    required this.flagUrl,
  });

  final int cityId;
  final String cityCode;
  final String cityName;
  final String countryCode;
  final String countryName;
  final int rank;
  final String destinationCode;
  final String imageUrl;
  final String flagUrl;

  String localizedCityName(bool isAr) {
    if (!isAr) return cityName;
    final lower = cityName.toLowerCase();
    if (lower.contains('amman')) return 'عمّان';
    if (lower.contains('bahrain')) return 'البحرين';
    if (lower.contains('manama')) return 'المنامة';
    if (lower.contains('salalah')) return 'صلالة';
    if (lower.contains('san francisco')) return 'سان فرانسيسكو';
    if (lower.contains('nice')) return 'نيس';
    if (lower.contains('dubai')) return 'دبي';
    if (lower.contains('delhi')) return 'نيودلهي';
    if (lower.contains('riyadh')) return 'الرياض';
    if (lower.contains('jeddah')) return 'جدة';
    if (lower.contains('cairo')) return 'القاهرة';
    if (lower.contains('alula')) return 'العلا';
    if (lower.contains('salzburg')) return 'سالزبورغ';
    if (lower.contains('sarajevo')) return 'سراييفو';
    if (lower.contains('tunis')) return 'تونس';
    if (lower.contains('beirut')) return 'بيروت';
    if (lower.contains('casablanca')) return 'الدار البيضاء';
    return cityName;
  }

  String localizedCountryName(bool isAr) {
    if (!isAr) return countryName;
    final code = countryCode.toUpperCase();
    switch (code) {
      case 'JO':
        return 'الأردن';
      case 'BH':
        return 'البحرين';
      case 'OM':
        return 'عُمان';
      case 'US':
        return 'الولايات المتحدة';
      case 'FR':
        return 'فرنسا';
      case 'AE':
        return 'الإمارات';
      case 'IN':
        return 'الهند';
      case 'SA':
        return 'المملكة العربية السعودية';
      case 'EG':
        return 'مصر';
      case 'AT':
        return 'النمسا';
      case 'BA':
        return 'البوسنة والهرسك';
      case 'TN':
        return 'تونس';
      case 'LB':
        return 'لبنان';
      case 'MA':
        return 'المغرب';
      default:
        return countryName;
    }
  }

  factory TopDestinationItem.fromJson(Map<String, dynamic> json) {
    final cityName = (json['city_name'] ?? json['cityName'] ?? '').toString();
    final rawCityId = json['city_id'] ?? json['cityId'] ?? 0;
    final cityId = rawCityId is num ? rawCityId.toInt() : (int.tryParse(rawCityId.toString()) ?? 0);
    final cityCode = (json['city_code'] ?? json['cityCode'] ?? '').toString();
    final countryCode = (json['country_code'] ?? json['countryCode'] ?? '').toString();
    final countryName = (json['country_name'] ?? json['countryName'] ?? '').toString();
    final rawRank = json['rank'] ?? 0;
    final rank = rawRank is num ? rawRank.toInt() : (int.tryParse(rawRank.toString()) ?? 0);
    final destinationCode = (json['destination_code'] ?? json['destinationCode'] ?? cityCode).toString();

    final image = resolveDestinationImage(cityName, cityId);
    final trimmedCode = countryCode.trim().toLowerCase();
    final flag = trimmedCode.length == 2
        ? 'https://flagcdn.com/w80/$trimmedCode.png'
        : '';

    return TopDestinationItem(
      cityId: cityId,
      cityCode: cityCode,
      cityName: cityName,
      countryCode: countryCode,
      countryName: countryName,
      rank: rank,
      destinationCode: destinationCode,
      imageUrl: image,
      flagUrl: flag,
    );
  }

  static String resolveDestinationImage(String cityName, int cityId) {
    final key = cityName.split('/').first.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (_destinationImages.containsKey(key)) {
      return _destinationImages[key]!;
    }
    for (final entry in _destinationImages.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return _fallbackImages[cityId.abs() % _fallbackImages.length];
  }

  static const Map<String, String> _destinationImages = {
    'amman': 'https://images.unsplash.com/photo-1580837119756-563d608dd119?w=900&h=700&fit=crop&q=80',
    'bahrain': 'https://images.unsplash.com/photo-1578895101408-1a36b834405b?w=900&h=700&fit=crop&q=80',
    'manama': 'https://images.unsplash.com/photo-1578895101408-1a36b834405b?w=900&h=700&fit=crop&q=80',
    'salalah': 'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?w=900&h=700&fit=crop&q=80',
    'san francisco': 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=900&h=700&fit=crop&q=80',
    'nice': 'https://images.unsplash.com/photo-1491161215050-bb07925f60f4?w=900&h=700&fit=crop&q=80',
    'dubai': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=900&h=700&fit=crop&q=80',
    'new delhi': 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=900&h=700&fit=crop&q=80',
    'delhi': 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=900&h=700&fit=crop&q=80',
    'riyadh': 'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=900&h=700&fit=crop&q=80',
    'jeddah': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900&h=700&fit=crop&q=80',
    'cairo': 'https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=900&h=700&fit=crop&q=80',
    'addis ababa': 'https://images.unsplash.com/photo-1523805009345-7448845a9e53?w=900&h=700&fit=crop&q=80',
    'florence': 'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=900&h=700&fit=crop&q=80',
    'guangzhou': 'https://images.unsplash.com/photo-1571945171673-e4c0f8635d44?w=900&h=700&fit=crop&q=80',
    'johannesburg': 'https://images.unsplash.com/photo-1577948000111-9c970dfe3743?w=900&h=700&fit=crop&q=80',
    'krabi': 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=900&h=700&fit=crop&q=80',
    'langkawi': 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=900&h=700&fit=crop&q=80',
    'manila': 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?w=900&h=700&fit=crop&q=80',
    'mauritius': 'https://images.unsplash.com/photo-1505881402582-c5bc11054f91?w=900&h=700&fit=crop&q=80',
    'moscow': 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=900&h=700&fit=crop&q=80',
    'petaling jaya': 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=900&h=700&fit=crop&q=80',
    'puncak': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=900&h=700&fit=crop&q=80',
    'salzburg': 'https://images.unsplash.com/photo-1516550893923-42d28e5677af?w=900&h=700&fit=crop&q=80',
    'sarajevo': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900&h=700&fit=crop&q=80',
    'tunis': 'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=900&h=700&fit=crop&q=80',
    'zell am see': 'https://images.unsplash.com/photo-1519904981063-b0cf448d479e?w=900&h=700&fit=crop&q=80',
    'beirut': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=900&h=700&fit=crop&q=80',
    'cameron highlands': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=900&h=700&fit=crop&q=80',
    'casablanca': 'https://images.unsplash.com/photo-1539020140153-e479b8c22e70?w=900&h=700&fit=crop&q=80',
  };

  static const List<String> _fallbackImages = [
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900&h=700&fit=crop&q=80',
    'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=900&h=700&fit=crop&q=80',
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=900&h=700&fit=crop&q=80',
    'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900&h=700&fit=crop&q=80',
    'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=900&h=700&fit=crop&q=80',
    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900&h=700&fit=crop&q=80',
  ];
}
