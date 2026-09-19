class Trip {
  const Trip({
    required this.route,
    required this.date,
    required this.provider,
    this.reference = '',
    this.type = 'flight',
    this.status = 'confirmed',
    this.pnr = '',
    this.price = 0,
    this.currency = 'SAR',
  });

  final String route;
  final String date;
  final String provider;
  final String reference;
  final String type;
  final String status;
  final String pnr;
  final num price;
  final String currency;

  Map<String, dynamic> toJson() => {
    'route': route,
    'date': date,
    'provider': provider,
    'reference': reference,
    'type': type,
    'status': status,
    'pnr': pnr,
    'price': price,
    'currency': currency,
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    route: json['route']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    provider: json['provider']?.toString() ?? '',
    reference: json['reference']?.toString() ?? '',
    type: json['type']?.toString() ?? 'flight',
    status: json['status']?.toString() ?? 'confirmed',
    pnr: json['pnr']?.toString() ?? '',
    price: json['price'] is num ? json['price'] as num : (num.tryParse(json['price']?.toString() ?? '') ?? 0),
    currency: json['currency']?.toString() ?? 'SAR',
  );
}
