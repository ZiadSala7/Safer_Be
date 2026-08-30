import '../../../../core/network/json_read.dart';
import 'hotel_room.dart';

class HotelBookingGuest {
  const HotelBookingGuest({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.age,
  });

  final String title;
  final String firstName;
  final String lastName;
  final int age;

  Map<String, dynamic> toJson() => {
    'title': title,
    'first_name': firstName,
    'last_name': lastName,
    'age': age,
  };
}

class HotelBookingRequest {
  const HotelBookingRequest({
    required this.hotelCode,
    required this.supplier,
    required this.checkIn,
    required this.checkOut,
    required this.currency,
    required this.room,
    required this.guest,
    required this.email,
    required this.phone,
    required this.nationality,
    this.callbackUrl = 'https://frontend.saferbe.com/payment/success',
    this.errorUrl = 'https://frontend.saferbe.com/payment/failed',
  });

  final String hotelCode;
  final String supplier;
  final DateTime checkIn;
  final DateTime checkOut;
  final String currency;
  final HotelRoom room;
  final HotelBookingGuest guest;
  final String email;
  final String phone;
  final String nationality;
  final String callbackUrl;
  final String errorUrl;

  Map<String, dynamic> toJson() => {
    'supplier': supplier.isNotEmpty ? supplier : 'juniper',
    'hotel_code': hotelCode,
    'check_in': checkIn.toIso8601String().split('T').first,
    'check_out': checkOut.toIso8601String().split('T').first,
    'currency': currency.isNotEmpty ? currency : 'SAR',
    'email': email,
    'phone': phone,
    'nationality': nationality.isNotEmpty ? nationality : 'SA',
    'rooms': [
      {
        'room_id': room.roomId ?? room.code,
        'room_code': room.code,
        if (room.roomTypeCode != null && room.roomTypeCode!.isNotEmpty)
          'room_type_code': room.roomTypeCode,
        'meal_plan': room.mealPlan,
        'total_price': room.price,
        'base_price': room.basePrice ?? room.price,
        'guests': [guest.toJson()],
      },
    ],
    'callback_url': callbackUrl,
    'error_url': errorUrl,
  };
}

class HotelBookingResult {
  const HotelBookingResult({required this.reference, required this.message});

  final String reference;
  final String message;

  factory HotelBookingResult.fromJson(dynamic json) {
    final data = apiData(json);
    final booking = data is Map ? data['booking'] : null;
    final bookingMap = booking is Map ? booking : const {};
    final source = bookingMap.isNotEmpty
        ? bookingMap
        : data is Map
        ? data
        : const {};
    return HotelBookingResult(
      reference: readText(source, [
        'reference',
        'booking_reference',
        'bookingReference',
        'pnr',
      ]),
      message: json is Map
          ? readText(json, ['message'], 'Your booking request was sent.')
          : 'Your booking request was sent.',
    );
  }
}
