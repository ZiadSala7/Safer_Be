import '../../../../core/network/json_read.dart';

class FlightPassengerInfo {
  const FlightPassengerInfo({
    required this.name,
    this.ticketNumber = '',
    this.type = 'Adult',
    this.passportNumber = '',
  });

  final String name;
  final String ticketNumber;
  final String type;
  final String passportNumber;

  factory FlightPassengerInfo.fromJson(dynamic json) {
    if (json is! Map) return FlightPassengerInfo(name: json?.toString() ?? '');
    final first = readText(json, ['first_name', 'firstName', 'name']);
    final last = readText(json, ['last_name', 'lastName']);
    final fullName = '$first $last'.trim().isNotEmpty
        ? '$first $last'.trim()
        : readText(json, ['full_name', 'passenger_name', 'traveler_name'], 'Passenger');
    return FlightPassengerInfo(
      name: fullName,
      ticketNumber: readText(json, ['ticket_number', 'ticketNumber', 'e_ticket', 'ticket_no']),
      type: readText(json, ['type', 'passenger_type', 'ptc'], 'Adult'),
      passportNumber: readText(json, ['passport_number', 'passportNumber', 'passport_no']),
    );
  }
}

class FlightSegmentDetails {
  const FlightSegmentDetails({
    required this.airline,
    required this.airlineCode,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    this.duration = '',
    this.cabinClass = 'Economy',
  });

  final String airline;
  final String airlineCode;
  final String flightNumber;
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String cabinClass;

  factory FlightSegmentDetails.fromJson(dynamic json) {
    if (json is! Map) {
      return const FlightSegmentDetails(
        airline: '',
        airlineCode: '',
        flightNumber: '',
        origin: '',
        destination: '',
        departureTime: '',
        arrivalTime: '',
      );
    }
    return FlightSegmentDetails(
      airline: readText(json, ['airline', 'airline_name', 'carrier']),
      airlineCode: readText(json, ['airline_code', 'carrier_code']),
      flightNumber: readText(json, ['flight_number', 'flightNumber', 'number']),
      origin: readText(json, ['origin', 'from', 'departure_airport', 'departure_airport_code', 'departure_code']),
      destination: readText(json, ['destination', 'to', 'arrival_airport', 'arrival_airport_code', 'arrival_code']),
      departureTime: readText(json, ['departure_time', 'departureTime', 'depart_time', 'departure', 'departure_date']),
      arrivalTime: readText(json, ['arrival_time', 'arrivalTime', 'arrive_time', 'arrival', 'arrival_date']),
      duration: readText(json, ['duration', 'flight_duration']),
      cabinClass: readText(json, ['cabin_class', 'cabinClass', 'cabin', 'class'], 'Economy'),
    );
  }
}

class FlightBookingDetails {
  const FlightBookingDetails({
    required this.bookingReference,
    required this.pnr,
    required this.status,
    required this.totalPrice,
    required this.currency,
    this.ticketNumber = '',
    this.airline = '',
    this.airlineCode = '',
    this.flightNumber = '',
    this.origin = '',
    this.destination = '',
    this.departureTime = '',
    this.arrivalTime = '',
    this.duration = '',
    this.cabinClass = 'Economy',
    this.passengers = const [],
    this.segments = const [],
    this.raw = const {},
  });

  final String bookingReference;
  final String pnr;
  final String status;
  final num totalPrice;
  final String currency;
  final String ticketNumber;
  final String airline;
  final String airlineCode;
  final String flightNumber;
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String cabinClass;
  final List<FlightPassengerInfo> passengers;
  final List<FlightSegmentDetails> segments;
  final Map<String, dynamic> raw;

  bool get isTicketed {
    final s = status.toLowerCase().trim();
    return s == 'ticketed' || ticketNumber.isNotEmpty;
  }

  bool get isConfirmed {
    final s = status.toLowerCase().trim();
    return s == 'confirmed' || s == 'ticketed' || s == 'success' || s == 'completed' || s == 'paid';
  }

  bool get isPending {
    final s = status.toLowerCase().trim();
    return s == 'pending' || s == 'processing' || s == 'hold' || s == 'initiated' || s.isEmpty;
  }

  bool get isReleased {
    final s = status.toLowerCase().trim();
    return s == 'released';
  }

  bool get isRefunded {
    final s = status.toLowerCase().trim();
    return s == 'refunded' || s == 'refund_requested';
  }

  bool get isCancelled {
    final s = status.toLowerCase().trim();
    return s == 'cancelled' || s == 'canceled' || s == 'released';
  }

  bool get isFailed {
    final s = status.toLowerCase().trim();
    return s == 'failed' || s == 'payment_success_booking_failed';
  }

  /// Only pending + not ticketed bookings are eligible for release (Owner Endpoint 3)
  bool get canRelease => isPending && !isTicketed && !isReleased;

  /// Ticketed and non-released bookings are eligible to request refund (Owner Endpoint 4)
  bool get canRefund => isTicketed && !isRefunded && !isReleased;

  /// E-ticket PDF can be downloaded once ticketed (Owner Endpoint 6)
  bool get canDownloadTicket => isTicketed;

  /// Flight invoice PDF can be downloaded for confirmed/paid/ticketed bookings (Owner Endpoint 5)
  bool get canDownloadInvoice => isConfirmed || isTicketed || totalPrice > 0;

  factory FlightBookingDetails.fromJson(dynamic json) {
    final data = apiData(json);
    final booking = data is Map
        ? (data['booking'] ?? data['data'] ?? data)
        : (json is Map ? (json['booking'] ?? json['data'] ?? json) : const {});
    final map = booking is Map ? Map<String, dynamic>.from(booking) : <String, dynamic>{};

    final rawPassengers = map['passengers'] ?? map['passenger_details'] ?? map['travelers'];
    final passengersList = rawPassengers is List
        ? rawPassengers.map(FlightPassengerInfo.fromJson).toList()
        : <FlightPassengerInfo>[];

    final flightDetails = map['flight_details'] is Map ? map['flight_details'] as Map : null;
    final rawSegments = map['segments'] ?? (flightDetails != null ? flightDetails['segments'] : null);
    final segmentsList = rawSegments is List
        ? rawSegments.map(FlightSegmentDetails.fromJson).toList()
        : <FlightSegmentDetails>[];

    final airline = readText(flightDetails ?? map, ['airline', 'airline_name', 'provider']);
    final airlineCode = readText(flightDetails ?? map, ['airline_code', 'carrier_code']);
    final flightNumber = readText(flightDetails ?? map, ['flight_number', 'flightNumber']);
    final origin = readText(flightDetails ?? map, ['origin', 'from', 'departure_airport', 'origin_code']);
    final destination = readText(flightDetails ?? map, ['destination', 'to', 'arrival_airport', 'destination_code']);
    final departureTime = readText(flightDetails ?? map, ['departure_time', 'departureTime', 'departure', 'date']);
    final arrivalTime = readText(flightDetails ?? map, ['arrival_time', 'arrivalTime', 'arrival']);
    final duration = readText(flightDetails ?? map, ['duration', 'flight_duration']);
    final cabinClass = readText(flightDetails ?? map, ['cabin_class', 'cabinClass', 'cabin', 'class'], 'Economy');

    return FlightBookingDetails(
      bookingReference: readText(map, [
        'booking_reference',
        'bookingReference',
        'reference',
        'reference_number',
      ]),
      pnr: readText(map, ['pnr', 'pnr_code']),
      status: readText(map, ['status', 'booking_status'], 'pending'),
      totalPrice: readNumber(map, ['total_price', 'totalPrice', 'price', 'amount', 'total_amount']),
      currency: readText(map, ['currency', 'currency_code'], 'SAR'),
      ticketNumber: readText(map, ['ticket_number', 'ticketNumber', 'e_ticket']),
      airline: airline,
      airlineCode: airlineCode,
      flightNumber: flightNumber,
      origin: origin,
      destination: destination,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      duration: duration,
      cabinClass: cabinClass,
      passengers: passengersList,
      segments: segmentsList,
      raw: map,
    );
  }
}
