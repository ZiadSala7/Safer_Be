import '../../../../core/network/json_read.dart';

class FlightBookingPassenger {
  const FlightBookingPassenger({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.type,
    required this.dateOfBirth,
    required this.passportNumber,
    required this.passportExpiry,
    required this.nationality,
    required this.email,
    required this.phone,
    this.phoneCountryCode,
    this.gender = '1',
    this.isLeadPassenger = false,
    this.address = '',
    this.address2,
  });

  final String title;
  final String firstName;
  final String lastName;
  final String type;
  final String dateOfBirth;
  final String passportNumber;
  final String passportExpiry;
  final String nationality;
  final String email;
  final String phone;
  final String? phoneCountryCode;
  final String gender;
  final bool isLeadPassenger;
  final String address;
  final String? address2;

  Map<String, dynamic> toJson() => {
    'title': title,
    'first_name': firstName,
    'last_name': lastName,
    'type': type,
    'date_of_birth': dateOfBirth,
    'passport_number': passportNumber,
    'passport_expiry': passportExpiry,
    'nationality': nationality,
    'email': email,
    'phone': phone,
    if (phoneCountryCode != null && phoneCountryCode!.isNotEmpty)
      'phone_country_code': phoneCountryCode,
    'gender': int.tryParse(gender) ?? 1,
    'is_lead_passenger': isLeadPassenger,
    'address': address,
    if (address2 != null && address2!.isNotEmpty) 'address2': address2,
  };
}

class FlightBookingRequest {
  const FlightBookingRequest({
    required this.resultIndex,
    required this.supplier,
    required this.flightData,
    required this.passengers,
    this.searchId,
    this.currency = 'USD',
    this.journeyType = 1,
    this.callbackUrl,
    this.errorUrl,
  });

  final String resultIndex;
  final String supplier;
  final Map<String, dynamic> flightData;
  final List<FlightBookingPassenger> passengers;
  final String? searchId;
  final String currency;
  final int journeyType;
  final String? callbackUrl;
  final String? errorUrl;

  Map<String, dynamic> toJson() => {
    'result_id': resultIndex,
    if (searchId != null && searchId!.isNotEmpty) 'search_id': searchId,
    'supplier': supplier,
    'currency': currency,
    'flight': flightData,
    'flight_result': flightData,
    'passengers': passengers.map((p) => p.toJson()).toList(),
    'journey_type': journeyType,
    if (callbackUrl != null && callbackUrl!.isNotEmpty)
      'callback_url': callbackUrl,
    if (errorUrl != null && errorUrl!.isNotEmpty) 'error_url': errorUrl,
  };
}

class FlightBookingResult {
  const FlightBookingResult({
    required this.bookingReference,
    required this.pnr,
    required this.status,
    required this.totalPrice,
    required this.currency,
    required this.message,
  });

  final String bookingReference;
  final String pnr;
  final String status;
  final num totalPrice;
  final String currency;
  final String message;

  factory FlightBookingResult.fromJson(dynamic json) {
    final data = apiData(json);
    final booking = data is Map ? data : const {};
    return FlightBookingResult(
      bookingReference: readText(booking, [
        'booking_reference',
        'bookingReference',
      ]),
      pnr: readText(booking, ['pnr']),
      status: readText(booking, ['status'], 'pending'),
      totalPrice: readNumber(booking, ['total_price', 'totalPrice', 'total']),
      currency: readText(booking, ['currency'], 'SAR'),
      message: json is Map
          ? readText(json, ['message'], 'Booking created successfully')
          : 'Booking created successfully',
    );
  }
}
