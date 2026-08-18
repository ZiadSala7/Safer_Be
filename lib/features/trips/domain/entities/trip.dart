class Trip {
  const Trip({
    required this.route,
    required this.date,
    required this.provider,
    this.reference = '',
    this.type = 'flight',
    this.status = 'confirmed',
  });

  final String route;
  final String date;
  final String provider;
  final String reference;
  final String type;
  final String status;

  Map<String, dynamic> toJson() => {
    'route': route,
    'date': date,
    'provider': provider,
    'reference': reference,
    'type': type,
    'status': status,
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    route: json['route']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    provider: json['provider']?.toString() ?? '',
    reference: json['reference']?.toString() ?? '',
    type: json['type']?.toString() ?? 'flight',
    status: json['status']?.toString() ?? 'confirmed',
  );
}
