import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/json_read.dart';
import '../../domain/entities/airport.dart';
import '../../domain/entities/checkout_result.dart';
import '../../domain/entities/flight_booking.dart';
import '../../domain/entities/flight_offer.dart';
import '../../domain/entities/flight_search.dart';
import '../../domain/entities/flight_search_response.dart';
import '../../domain/entities/hotel_booking.dart';
import '../../domain/entities/hotel_booking_details.dart';
import '../../domain/entities/hotel_offer.dart';
import '../../domain/entities/hotel_room.dart';
import '../../domain/entities/hotel_search.dart';
import '../../domain/entities/travel_city.dart';
import '../../domain/repositories/travel_search_repository.dart';

class ApiTravelSearchRepository implements TravelSearchRepository {
  ApiTravelSearchRepository({ApiClient? client})
    : _client = client ?? ApiClient();
  final ApiClient _client;

  @override
  Future<List<Airport>> airports(String query) async {
    final json = await _client.get(
      '/airports/suggest',
      query: {'q': query, 'limit': '10'},
    );
    return apiList(
      json,
    ).map(Airport.fromJson).where((item) => item.code.isNotEmpty).toList();
  }

  @override
  Future<Airport?> airportByCode(String code) async {
    final json = await _client.get('/flights/airports/$code');
    final data = apiData(json);
    if (data is Map) return Airport.fromJson(Map<String, dynamic>.from(data));
    return null;
  }

  @override
  Future<List<Airport>> nearbyAirports({
    required double latitude,
    required double longitude,
    int radius = 100,
    int limit = 10,
  }) async {
    final json = await _client.get(
      '/flights/airports/nearby',
      query: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'limit': limit.toString(),
      },
    );
    return apiList(
      json,
    ).map(Airport.fromJson).where((item) => item.code.isNotEmpty).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> destinationsAutocomplete(
    String query, {
    int limit = 20,
  }) async {
    final json = await _client.get(
      '/destinations/autocomplete',
      query: {'q': query, 'limit': limit.toString()},
    );
    return apiList(json);
  }

  @override
  Future<List<Map<String, dynamic>>> airportsSuggest(
    String query, {
    int limit = 20,
  }) async {
    final json = await _client.get(
      '/airports/suggest',
      query: {'q': query, 'limit': limit.toString()},
    );
    return apiList(json);
  }

  @override
  Future<List<TravelCity>> cities(String query) async {
    final json = await _client.get(
      '/cities',
      query: {'search': query, 'limit': '20'},
    );
    return apiList(
      json,
    ).map(TravelCity.fromJson).where((item) => item.code.isNotEmpty).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> currencies() async {
    final json = await _client.get('/currencies');
    return apiList(json);
  }

  @override
  Future<List<FlightOffer>> flights(FlightSearch search) async {
    final response = await searchFlights(search);
    return response.offers;
  }

  @override
  Future<FlightSearchResponse> searchFlights(FlightSearch search) async {
    try {
      final json = await _client.post('/flights/search', body: search.toJson());
      return FlightSearchResponse.fromJson(json);
    } on ApiException catch (exception) {
      if (_isSoftEmptyFlightSearchStatus(exception.statusCode)) {
        return FlightSearchResponse.empty;
      }
      rethrow;
    }
  }

  @override
  Future<List<FlightOffer>> cheapestFlights(
    FlightSearch search, {
    int limit = 3,
  }) async {
    try {
      final json = await _client.post(
        '/flights/cheapest',
        body: search.toJson(),
        query: {'limit': limit.toString()},
      );
      return FlightSearchResponse.fromJson(json).offers;
    } on ApiException catch (exception) {
      if (_isSoftEmptyFlightSearchStatus(exception.statusCode)) return const [];
      rethrow;
    }
  }

  @override
  Future<List<FlightOffer>> fastestFlights(
    FlightSearch search, {
    int limit = 3,
  }) async {
    try {
      final json = await _client.post(
        '/flights/fastest',
        body: search.toJson(),
        query: {'limit': limit.toString()},
      );
      return FlightSearchResponse.fromJson(json).offers;
    } on ApiException catch (exception) {
      if (_isSoftEmptyFlightSearchStatus(exception.statusCode)) return const [];
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fareQuote({
    required String resultIndex,
    String? referenceIndex,
    String? searchId,
    String supplier = 'tbo',
    String currency = 'USD',
  }) async {
    final json = await _client.post(
      '/flights/fare-quote',
      body: {
        'result_index': resultIndex,
        if (referenceIndex != null && referenceIndex.isNotEmpty)
          'reference_index': referenceIndex,
        if (searchId != null && searchId.isNotEmpty) 'search_id': searchId,
        'supplier': supplier,
        'currency': FlightSearch.normalizeCurrency(currency),
      },
    );
    final data = apiData(json);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  @override
  Future<List<Map<String, dynamic>>> zones() async {
    final json = await _client.get('/flights/zones');
    return apiList(json);
  }

  @override
  Future<Map<String, dynamic>> detectZone({
    double? latitude,
    double? longitude,
    String? airportCode,
  }) async {
    final json = await _client.post(
      '/flights/detect-zone',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'airport_code': airportCode,
      },
    );
    final data = apiData(json);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  @override
  Future<List<Map<String, dynamic>>> flightTypes() async {
    final json = await _client.get('/flights/flight-types');
    return apiList(json);
  }

  @override
  Future<List<Map<String, dynamic>>> airlines({
    String? search,
    int limit = 50,
  }) async {
    final query = <String, String>{'limit': limit.toString(), 'locale': 'en'};
    final path = search != null && search.trim().length >= 2
        ? '/airlines/autocomplete'
        : '/airlines';
    if (search != null && search.trim().isNotEmpty) query['q'] = search.trim();
    final json = await _client.get(path, query: query);
    return apiList(json);
  }

  @override
  Future<List<Map<String, dynamic>>> topHotelDestinations({
    String? countryCode,
  }) async {
    final query = <String, String>{};
    if (countryCode != null && countryCode.isNotEmpty) {
      query['country_code'] = countryCode;
    }
    final json = await _client.get(
      '/hotels/reference/top-destinations',
      query: query.isNotEmpty ? query : null,
    );
    return apiList(json);
  }

  @override
  Future<List<HotelOffer>> hotels(HotelSearch search) async {
    try {
      final json = await _client.post('/hotels/search', body: search.toJson());
      return apiList(json).map(HotelOffer.fromJson).toList();
    } on ApiException catch (e) {
      if (_isSoftEmptyFlightSearchStatus(e.statusCode)) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<List<HotelRoom>> hotelRooms({
    required HotelOffer offer,
    required HotelSearch search,
  }) async {
    try {
      final json = await _client.post(
        '/hotels/${Uri.encodeComponent(offer.code)}/rooms',
        body: {
          'supplier': offer.supplier.isNotEmpty ? offer.supplier : 'juniper',
          if (offer.ratePlanCode.isNotEmpty)
            'rate_plan_code': offer.ratePlanCode,
          'hotel_code': offer.code,
          'check_in': search.checkIn.toIso8601String().split('T').first,
          'check_out': search.checkOut.toIso8601String().split('T').first,
          'currency': search.currency,
          'guests': [
            {'adults': search.adults, 'children': search.children},
          ],
        },
      );
      final data = apiData(json);
      final value = data is Map
          ? data['rooms'] ?? data['data'] ?? data['results'] ?? data['items']
          : data;
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((item) => HotelRoom.fromJson(Map<String, dynamic>.from(item)))
          .where((room) => room.code.isNotEmpty)
          .toList();
    } on ApiException catch (e) {
      if (_isSoftEmptyFlightSearchStatus(e.statusCode)) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<HotelBookingResult> bookHotel(HotelBookingRequest request) async {
    final json = await _client.post('/hotels/book', body: request.toJson());
    return HotelBookingResult.fromJson(json);
  }

  @override
  Future<FlightBookingResult> bookFlight(FlightBookingRequest request) async {
    final json = await _client.post('/flights/book', body: request.toJson());
    return FlightBookingResult.fromJson(json);
  }

  @override
  Future<CheckoutResult> initiateFlightCheckout(
    FlightBookingRequest request,
  ) async {
    final json = await _client.post(
      '/flights/checkout/initiate',
      body: request.toJson(),
    );
    return CheckoutResult.fromJson(json);
  }

  @override
  Future<CheckoutResult> initiateHotelCheckout(
    HotelBookingRequest request,
  ) async {
    final json = await _client.post(
      '/hotels/checkout/initiate',
      body: request.toJson(),
    );
    return CheckoutResult.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> getFlightBooking(String reference) async {
    final json = await _client.get('/flights/booking/$reference');
    final data = apiData(json);
    return data is Map
        ? Map<String, dynamic>.from(data)
        : (json is Map ? Map<String, dynamic>.from(json) : {});
  }

  @override
  Future<Map<String, dynamic>> getHotelBooking(String reference) async {
    final json = await _client.get('/hotels/booking/$reference');
    final data = apiData(json);
    return data is Map
        ? Map<String, dynamic>.from(data)
        : (json is Map ? Map<String, dynamic>.from(json) : {});
  }

  @override
  Future<HotelBookingDetails> getHotelBookingDetails(String reference) async {
    final json = await _client.get('/hotels/booking/$reference');
    return HotelBookingDetails.fromJson(json);
  }

  @override
  Future<HotelPaymentCallbackResult> verifyHotelPaymentCallback(
    String paymentId,
  ) async {
    final json = await _client.get(
      '/hotels/checkout/callback',
      query: {'paymentId': paymentId},
    );
    return HotelPaymentCallbackResult.fromJson(json);
  }

  @override
  Future<HotelPaymentCallbackResult> verifyFlightPaymentCallback(
    String paymentId,
  ) async {
    final json = await _client.get(
      '/flights/checkout/callback',
      query: {'paymentId': paymentId},
    );
    return HotelPaymentCallbackResult.fromJson(json);
  }

  @override
  Future<void> releaseFlightBooking(String reference) async {
    await _client.post('/flights/booking/$reference/release');
  }

  @override
  Future<Map<String, dynamic>> ticketFlight({
    String? pnr,
    String? bookingReference,
  }) async {
    final json = await _client.post(
      '/flights/ticket',
      body: {
        if (pnr != null && pnr.isNotEmpty) 'pnr': pnr,
        if (bookingReference != null && bookingReference.isNotEmpty)
          'booking_reference': bookingReference,
      },
    );
    final data = apiData(json);
    return data is Map
        ? Map<String, dynamic>.from(data)
        : (json is Map ? Map<String, dynamic>.from(json) : {});
  }

  @override
  Future<Map<String, dynamic>> refundFlightBooking(String reference) async {
    final json = await _client.post('/flights/booking/$reference/refund');
    final data = apiData(json);
    return data is Map
        ? Map<String, dynamic>.from(data)
        : (json is Map ? Map<String, dynamic>.from(json) : {});
  }

  @override
  Future<Map<String, dynamic>> getFlightTicket(String reference) async {
    final json = await _client.get('/flights/booking/$reference/ticket');
    final data = apiData(json);
    return data is Map
        ? Map<String, dynamic>.from(data)
        : (json is Map ? Map<String, dynamic>.from(json) : {});
  }

  @override
  Future<void> cancelHotelBooking(String reference, [String? reason]) async {
    await _client.post(
      '/hotels/booking/$reference/cancel',
      body: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
    );
  }

  bool _isSoftEmptyFlightSearchStatus(int? statusCode) =>
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504 ||
      statusCode == 404;
}
