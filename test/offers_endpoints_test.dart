import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safer_be_project/core/localization/app_localizations.dart';
import 'package:safer_be_project/core/network/api_client.dart';
import 'package:safer_be_project/core/network/token_store.dart';
import 'package:safer_be_project/core/utils/guid_generator.dart';
import 'package:safer_be_project/core/utils/image_url_resolver.dart';
import 'package:safer_be_project/features/home/presentation/widgets/offer_card.dart';
import 'package:safer_be_project/features/offers/data/repositories/api_offers_repository.dart';
import 'package:safer_be_project/features/offers/domain/entities/marketing_offer.dart';
import 'package:safer_be_project/features/offers/presentation/pages/offers_page.dart';
import 'package:safer_be_project/features/offers/presentation/widgets/offer_details_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GUID Generator', () {
    test('generates valid RFC 4122 v4 GUID strings', () {
      final guid1 = generateGuid();
      final guid2 = generateGuid();

      expect(guid1, isNotEmpty);
      expect(guid2, isNotEmpty);
      expect(guid1, isNot(equals(guid2)));

      // RFC 4122 UUID v4 regex: 8-4-4-4-12 hex with '4' as version and [89ab] as variant
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(guid1), isTrue);
      expect(uuidRegex.hasMatch(guid2), isTrue);
    });
  });

  group('MarketingOffer Entity & Model (Offers_API-v2.md)', () {
    test('parses Summer Flight Sale offer with percentage discount', () {
      final json = {
        'id': 101,
        'title': 'Summer Flight Sale',
        'description': 'Get 15% off on all flights to DXB.',
        'code': 'SUMMER15',
        'discount_type': 'percentage',
        'discount_value': 15,
        'valid_from': '2026-09-01T00:00:00Z',
        'valid_until': '2026-09-30T23:59:59Z',
        'image_url': 'https://example.com/images/offers/summer-sale.png',
      };

      final offer = MarketingOffer.fromJson(json);

      expect(offer.id, 101);
      expect(offer.titleKey, 'Summer Flight Sale');
      expect(offer.subtitleKey, 'Get 15% off on all flights to DXB.');
      expect(offer.code, 'SUMMER15');
      expect(offer.discountType, 'percentage');
      expect(offer.discount, 15);
      expect(offer.formattedDiscount, '15%');
      expect(offer.category, 'flights');
      expect(offer.image, 'https://example.com/images/offers/summer-sale.png');
      expect(offer.validFrom, DateTime.parse('2026-09-01T00:00:00Z'));
      expect(offer.validUntil, DateTime.parse('2026-09-30T23:59:59Z'));
      expect(offer.isExpired, isFalse);
    });

    test('parses Welcome Hotel Bonus offer with fixed discount and null valid_until', () {
      final json = {
        'id': 102,
        'title': 'Welcome Hotel Bonus',
        'description': 'Save \$50 on your first hotel booking.',
        'code': 'WELCOME50',
        'discount_type': 'fixed',
        'discount_value': 50,
        'currency': 'USD',
        'valid_from': '2026-01-01T00:00:00Z',
        'valid_until': null,
        'image_url': 'https://example.com/images/offers/welcome-hotel.png',
      };

      final offer = MarketingOffer.fromJson(json);

      expect(offer.id, 102);
      expect(offer.titleKey, 'Welcome Hotel Bonus');
      expect(offer.code, 'WELCOME50');
      expect(offer.discountType, 'fixed');
      expect(offer.discount, 50);
      expect(offer.currency, 'USD');
      expect(offer.formattedDiscount, '50 USD');
      expect(offer.category, 'hotels');
      expect(offer.validUntil, isNull);
      expect(offer.isExpired, isFalse);
    });

    test('correctly infers categories from title and description keywords', () {
      expect(
        MarketingOffer.inferCategory('Transfer to Airport', 'Reliable chauffeur ride'),
        'transfers',
      );
      expect(
        MarketingOffer.inferCategory('AlUla Weekend Getaway', 'Explore Saudi heritage'),
        'domestic',
      );
      expect(
        MarketingOffer.inferCategory('Fly to London', 'Summer flights promotion'),
        'flights',
      );
      expect(
        MarketingOffer.inferCategory('Luxury Resort Stay', 'Enjoy boutique suites'),
        'hotels',
      );
      expect(
        MarketingOffer.inferCategory('Global Travel Pass', 'Explore worldwide'),
        'all',
      );
    });

    test('serializes to JSON and deserializes back faithfully', () {
      final original = MarketingOffer.fromJson({
        'id': 103,
        'title': 'Private Chauffeur Service',
        'description': 'Safe private airport transfer',
        'code': 'RIDE20',
        'discount_type': 'percentage',
        'discount_value': 20,
        'image_url': 'https://example.com/transfer.png',
      });

      final map = original.toJson();
      final recreated = MarketingOffer.fromJson(map);

      expect(recreated.id, original.id);
      expect(recreated.code, original.code);
      expect(recreated.discount, original.discount);
      expect(recreated.category, original.category);
    });

    test('parses complete Postman collection offer schema with conditions, gallery, and limits', () {
      final json = {
        'id': 301,
        'name': 'Summer DXB 10%',
        'type': 'destination',
        'discount_type': 'percentage',
        'discount_value': 10,
        'max_discount': 200,
        'min_booking_amount': 500,
        'priority': 100,
        'status': 'draft',
        'starts_at': '2026-06-01',
        'ends_at': '2026-09-01',
        'usage_limit': 1000,
        'per_user_limit': 2,
        'conditions': [
          {
            'condition_type': 'destination',
            'condition_value': 'DXB',
          }
        ],
        'gallery': [
          {
            'image_url': 'https://cdn.example.com/offers/summer.jpg',
            'alt_text': 'Summer offer',
            'is_primary': true,
            'sort_order': 0,
          }
        ],
      };

      final offer = MarketingOffer.fromJson(json);

      expect(offer.id, 301);
      expect(offer.titleKey, 'Summer DXB 10%');
      expect(offer.type, 'destination');
      expect(offer.category, 'flights'); // Inferred from destination DXB
      expect(offer.discount, 10);
      expect(offer.formattedDiscount, '10%');
      expect(offer.maxDiscount, 200);
      expect(offer.minBookingAmount, 500);
      expect(offer.priority, 100);
      expect(offer.status, 'draft');
      expect(offer.usageLimit, 1000);
      expect(offer.perUserLimit, 2);
      expect(offer.validFrom, DateTime.parse('2026-06-01'));
      expect(offer.validUntil, DateTime.parse('2026-09-01'));
      expect(offer.conditions.length, 1);
      expect(offer.conditions.first.conditionType, 'destination');
      expect(offer.conditions.first.conditionValue, 'DXB');
      expect(offer.gallery.length, 1);
      expect(offer.gallery.first.imageUrl, 'https://cdn.example.com/offers/summer.jpg');
      expect(offer.gallery.first.isPrimary, isTrue);
      expect(offer.image, 'https://cdn.example.com/offers/summer.jpg');
      expect(offer.allImageUrls, contains('https://cdn.example.com/offers/summer.jpg'));
    });

    test('resolveOfferImageUrl correctly resolves relative paths and CDN URLs', () {
      expect(resolveOfferImageUrl(''), '');
      expect(resolveOfferImageUrl(null), '');
      expect(resolveOfferImageUrl('https://cdn.saferbe.com/banner.png'), 'https://cdn.saferbe.com/banner.png');
      expect(resolveOfferImageUrl('http://cdn.saferbe.com/banner.png'), 'http://cdn.saferbe.com/banner.png');
      expect(resolveOfferImageUrl('//cdn.saferbe.com/banner.png'), 'https://cdn.saferbe.com/banner.png');
      expect(resolveOfferImageUrl('assets/images/destinations/alula_hero.png'), 'assets/images/destinations/alula_hero.png');
      expect(resolveOfferImageUrl('/storage/offers/summer.jpg'), startsWith('https://backend.saferbe.com/storage/offers/summer.jpg'));
      expect(resolveOfferImageUrl('storage/offers/summer.jpg'), startsWith('https://backend.saferbe.com/storage/offers/summer.jpg'));
    });
  });

  group('ApiOffersRepository Contract & Offline Fallback', () {
    test('calls public GET /offers/available with X-Request-Id and parses response', () async {
      late http.Request captured;

      final mockClient = MockClient((request) async {
        captured = request;
        final responsePayload = {
          'success': true,
          'data': [
            {
              'id': 101,
              'title': 'Summer Flight Sale',
              'description': 'Get 15% off on all flights to DXB.',
              'code': 'SUMMER15',
              'discount_type': 'percentage',
              'discount_value': 15,
              'valid_from': '2026-09-01T00:00:00Z',
              'valid_until': '2026-09-30T23:59:59Z',
              'image_url': 'https://example.com/images/offers/summer-sale.png',
            },
            {
              'id': 102,
              'title': 'Welcome Hotel Bonus',
              'description': 'Save \$50 on your first hotel booking.',
              'code': 'WELCOME50',
              'discount_type': 'fixed',
              'discount_value': 50,
              'currency': 'USD',
              'valid_from': '2026-01-01T00:00:00Z',
              'valid_until': null,
              'image_url': 'https://example.com/images/offers/welcome-hotel.png',
            },
          ],
          'message': 'Available offers retrieved successfully.',
        };

        return http.Response(
          jsonEncode(responsePayload),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        tokens: TokenStore(),
        language: 'en',
      );

      final repo = ApiOffersRepository(client: apiClient);
      final offers = await repo.getAvailableOffers(forceRefresh: true);

      // Verify request specification from Offers_API-v2.md
      expect(captured.method, 'GET');
      expect(
        captured.url.toString(),
        'https://backend.saferbe.com/api/v1/offers/available',
      );
      expect(captured.headers['Accept'], 'application/json');
      expect(captured.headers['Accept-Language'], 'en');
      expect(captured.headers['Authorization'], isNull); // Public endpoint
      expect(captured.headers['X-Request-Id'], isNotNull);

      // Verify returned offers
      expect(offers.length, 2);
      expect(offers[0].code, 'SUMMER15');
      expect(offers[0].category, 'flights');
      expect(offers[1].code, 'WELCOME50');
      expect(offers[1].category, 'hotels');
    });

    test('returns empty list without unlinked mock data on 500 error when cache is empty', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'An unexpected error occurred while retrieving offers.',
            'error_code': 'INTERNAL_SERVER_ERROR',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ApiOffersRepository(client: apiClient);

      final offers = await repo.getAvailableOffers(forceRefresh: true);

      // Gracefully returns empty list rather than fake unlinked mock offers
      expect(offers, isEmpty);
      expect(offers.any((o) => o.code == 'ALULA15'), isFalse);
    });

    test('falls back to persisted API cache on network failure when cache exists', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 10,
                  'title': 'Real API Deal',
                  'code': 'REAL10',
                  'discount_value': 10,
                  'discount_type': 'percentage',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          return http.Response('Internal error', 500);
        }
      });

      final repo = ApiOffersRepository(client: ApiClient(client: mockClient));
      final initialOffers = await repo.getAvailableOffers(forceRefresh: true);
      expect(initialOffers.length, 1);
      expect(initialOffers.first.code, 'REAL10');

      // Second call fails with 500, should fall back to cached real API offers
      final newRepo = ApiOffersRepository(client: ApiClient(client: mockClient));
      final fallbackOffers = await newRepo.getAvailableOffers(forceRefresh: true);
      expect(fallbackOffers.length, 1);
      expect(fallbackOffers.first.code, 'REAL10');
    });
  });

  group('OffersPage & OfferCard Widget Tests', () {
    testWidgets('OffersPage loads and renders offer cards with copy action', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        final payload = {
          'success': true,
          'data': [
            {
              'id': 201,
              'title': 'Red Sea Escape',
              'description': 'Enjoy 20% off Red Sea luxury resorts.',
              'code': 'REDSEA20',
              'discount_type': 'percentage',
              'discount_value': 20,
              'image_url': 'https://example.com/red-sea.png',
            },
          ],
        };
        return http.Response(
          jsonEncode(payload),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = ApiOffersRepository(client: ApiClient(client: mockClient));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          locale: const Locale('en'),
          home: Scaffold(body: OffersPage(repository: repo)),
        ),
      );

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Loaded content
      expect(find.text('Red Sea Escape'), findsOneWidget);
      expect(find.text('REDSEA20'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);

      // Tap to copy code via the Copy Code button
      await tester.tap(find.text('Copy Code'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('REDSEA20'), findsWidgets);

      // Tap on the OfferCard -> opens OfferDetailsSheet
      await tester.tap(find.byType(OfferCard));
      await tester.pumpAndSettle();

      expect(find.byType(OfferDetailsSheet), findsOneWidget);
      expect(find.text('Offer Details'), findsOneWidget);

      // Close the sheet via the close icon button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Sheet is dismissed
      expect(find.byType(OfferDetailsSheet), findsNothing);
    });
  });
}
