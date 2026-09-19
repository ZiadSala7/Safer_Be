import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_read.dart';
import '../../../../core/utils/guid_generator.dart';
import '../../../home/domain/entities/travel_content.dart';
import '../../domain/entities/marketing_offer.dart';
import '../../domain/repositories/offers_repository.dart';
import 'local_offers_repository.dart';

/// Implementation of [OffersRepository] that retrieves publicly available marketing offers
/// from GET /api/v1/offers/available.
///
/// Features:
/// - Public authentication (no Bearer token).
/// - Request tracing header `X-Request-Id` with RFC 4122 v4 GUID.
/// - Response caching with [SharedPreferences] for seamless offline access.
/// - Graceful fallback to cached offers or local fallback repository.
class ApiOffersRepository implements OffersRepository {
  ApiOffersRepository({ApiClient? client, OffersRepository? localFallback})
    : _client = client ?? ApiClient(),
      _localFallback = localFallback ?? LocalOffersRepository();

  final ApiClient _client;
  final OffersRepository _localFallback;
  static const String _cacheKey = 'safer_be_marketing_offers_cache';

  // In-memory cache
  List<MarketingOffer>? _memoryCache;

  @override
  Future<List<MarketingOffer>> getAvailableOffers({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _memoryCache != null && _memoryCache!.isNotEmpty) {
      return _memoryCache!;
    }

    try {
      final json = await _client.get(
        '/offers/available',
        authenticated: false,
        headers: {'X-Request-Id': generateGuid()},
      );

      final list = apiList(json);
      if (list.isNotEmpty) {
        final offers = list.map((item) => MarketingOffer.fromJson(item)).toList();
        _memoryCache = offers;
        await _saveToCache(offers);
        return offers;
      }

      // If data was empty but success is true
      if (json is Map && json['success'] == true) {
        _memoryCache = [];
        return [];
      }
    } catch (e) {
      debugPrint('[ApiOffersRepository] Failed to fetch live offers: $e');
    }

    // Fallback: try reading persisted cache
    final cached = await _loadFromCache();
    if (cached.isNotEmpty) {
      _memoryCache = cached;
      return cached;
    }

    // Secondary fallback: local repository
    final fallback = await _localFallback.getAvailableOffers();
    _memoryCache = fallback;
    return fallback;
  }

  @override
  List<TravelOffer> getAll() => _memoryCache ?? _localFallback.getAll();

  Future<List<MarketingOffer>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((m) => MarketingOffer.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToCache(List<MarketingOffer> offers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(offers.map((o) => o.toJson()).toList()),
      );
    } catch (_) {
      // Ignore cache persistence errors
    }
  }

  /// Clears in-memory and disk cache
  Future<void> clearCache() async {
    _memoryCache = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }
}
