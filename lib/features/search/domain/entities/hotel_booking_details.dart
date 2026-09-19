import '../../../../core/network/json_read.dart';

class HotelBookingDetails {
  const HotelBookingDetails({
    required this.bookingReference,
    required this.status,
    this.paymentStatus,
    this.hotelCode = '',
    this.hotelName = '',
    this.checkIn = '',
    this.checkOut = '',
    this.totalPrice = 0,
    this.currency = 'SAR',
    this.supplier = '',
    this.confirmationNumber = '',
    this.supplierBookingId = '',
    this.leadGuestName = '',
    this.email = '',
    this.phone = '',
    this.rooms = const [],
    this.raw = const {},
  });

  final String bookingReference;
  final String status;
  final String? paymentStatus;
  final String hotelCode;
  final String hotelName;
  final String checkIn;
  final String checkOut;
  final num totalPrice;
  final String currency;
  final String supplier;
  final String confirmationNumber;
  final String supplierBookingId;
  final String leadGuestName;
  final String email;
  final String phone;
  final List<dynamic> rooms;
  final Map<String, dynamic> raw;

  bool get isConfirmed {
    final s = status.toLowerCase().trim();
    return s == 'confirmed' || s == 'ticketed' || s == 'success' || s == 'completed';
  }

  bool get isPaid {
    final s = (paymentStatus ?? status).toLowerCase().trim();
    return s == 'paid' || s == 'confirmed' || s == 'success';
  }

  bool get isPending {
    final s = status.toLowerCase().trim();
    final p = (paymentStatus ?? '').toLowerCase().trim();
    return s == 'pending' ||
        s == 'processing' ||
        s == 'pending_payment' ||
        s == 'initiated' ||
        p == 'pending' ||
        s.isEmpty;
  }

  bool get isFailed {
    final s = status.toLowerCase().trim();
    final p = (paymentStatus ?? '').toLowerCase().trim();
    return s == 'failed' ||
        s == 'rejected' ||
        s == 'paid_but_booking_failed' ||
        s == 'payment_failed' ||
        p == 'failed';
  }

  bool get isCancelled {
    final s = status.toLowerCase().trim();
    return s == 'cancelled' || s == 'canceled' || s == 'released';
  }

  /// Can request hotel cancellation if not already cancelled or failed
  bool get canCancel => !isCancelled && !isFailed;

  factory HotelBookingDetails.fromJson(dynamic json) {
    final data = apiData(json);
    final booking = data is Map ? (data['booking'] ?? data['data'] ?? data) : (json is Map ? (json['booking'] ?? json) : const {});
    final map = booking is Map ? Map<String, dynamic>.from(booking) : <String, dynamic>{};

    final guestMap = map['guest_details'] ?? map['guest'] ?? map['lead_guest'];
    String guestName = '';
    String email = readText(map, ['email', 'customer_email']);
    String phone = readText(map, ['phone', 'customer_phone']);

    if (guestMap is Map) {
      final first = readText(guestMap, ['first_name', 'firstName', 'name']);
      final last = readText(guestMap, ['last_name', 'lastName']);
      guestName = '$first $last'.trim();
      if (email.isEmpty) email = readText(guestMap, ['email']);
      if (phone.isEmpty) phone = readText(guestMap, ['phone']);
    }

    final rawRooms = map['rooms'] ?? map['room_details'] ?? map['room'];
    final roomsList = rawRooms is List ? rawRooms : (rawRooms is Map ? [rawRooms] : const []);

    return HotelBookingDetails(
      bookingReference: readText(map, [
        'booking_reference',
        'bookingReference',
        'reference',
        'reference_number',
        'client_reference_number',
        'pnr',
      ]),
      status: readText(map, ['status', 'booking_status'], 'pending'),
      paymentStatus: readText(map, ['payment_status', 'paymentStatus']),
      hotelCode: readText(map, ['hotel_code', 'hotelCode', 'code']),
      hotelName: readText(map, ['hotel_name', 'hotelName', 'name', 'property_name']),
      checkIn: readText(map, ['check_in', 'checkIn', 'check_in_date']),
      checkOut: readText(map, ['check_out', 'checkOut', 'check_out_date']),
      totalPrice: readNumber(map, ['total_price', 'totalPrice', 'price', 'amount', 'total_amount']),
      currency: readText(map, ['currency', 'currency_code'], 'SAR'),
      supplier: readText(map, ['supplier', 'provider']),
      confirmationNumber: readText(map, [
        'confirmation_number',
        'confirmationNumber',
        'supplier_confirmation_number',
        'hotel_confirmation_code',
      ]),
      supplierBookingId: readText(map, [
        'supplier_booking_id',
        'supplierBookingId',
        'booking_id',
        'bookingId',
      ]),
      leadGuestName: guestName,
      email: email,
      phone: phone,
      rooms: roomsList,
      raw: map,
    );
  }
}

class HotelPaymentCallbackResult {
  const HotelPaymentCallbackResult({
    required this.success,
    required this.bookingReference,
    required this.paymentId,
    required this.paymentStatus,
    required this.status,
    required this.message,
    this.raw = const {},
  });

  final bool success;
  final String bookingReference;
  final String paymentId;
  final String paymentStatus;
  final String status;
  final String message;
  final Map<String, dynamic> raw;

  bool get isPaid {
    final ps = paymentStatus.toLowerCase().trim();
    final s = status.toLowerCase().trim();
    return success && (ps == 'paid' || ps == 'captured' || s == 'confirmed' || s == 'paid');
  }

  bool get isConfirmed {
    final s = status.toLowerCase().trim();
    return isPaid && (s == 'confirmed' || s == 'success' || s == 'completed');
  }

  bool get isFailed {
    final ps = paymentStatus.toLowerCase().trim();
    final s = status.toLowerCase().trim();
    return ps == 'failed' || s == 'failed' || s.contains('failed') || !success;
  }

  factory HotelPaymentCallbackResult.fromJson(dynamic json) {
    final data = apiData(json);
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : (json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{});

    final success = json is Map && json['success'] == true;
    final booking = map['booking'] is Map ? Map<String, dynamic>.from(map['booking']) : map;

    return HotelPaymentCallbackResult(
      success: success,
      bookingReference: readText(booking, [
        'booking_reference',
        'bookingReference',
        'reference',
        'reference_number',
      ]),
      paymentId: readText(map, ['paymentId', 'payment_id', 'invoice_id', 'id']),
      paymentStatus: readText(map, ['payment_status', 'paymentStatus', 'InvoiceStatus'], success ? 'Paid' : 'Failed'),
      status: readText(booking, ['status', 'booking_status'], success ? 'confirmed' : 'pending'),
      message: json is Map ? readText(json, ['message']) : '',
      raw: map,
    );
  }
}
