import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/guid_generator.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    TokenStore? tokens,
    String language = 'en',
    bool? logTraffic,
  }) : _client = client ?? http.Client(),
       _tokens = tokens ?? TokenStore(),
       _language = language,
       _logTraffic = logTraffic ?? kDebugMode;

  final http.Client _client;
  final TokenStore _tokens;
  final String _language;
  final bool _logTraffic;
  static const int _maxLogBodyLength = 12000;

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
    String? customToken,
    Map<String, String>? headers,
    Duration? timeout,
  }) => _send(
    'GET',
    path,
    query: query,
    authenticated: authenticated,
    customToken: customToken,
    headers: headers,
    timeout: timeout,
  );

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? query,
    bool authenticated = true,
    String? customToken,
    Map<String, String>? headers,
    Duration? timeout,
  }) => _send(
    'POST',
    path,
    body: body,
    query: query,
    authenticated: authenticated,
    customToken: customToken,
    headers: headers,
    timeout: timeout,
  );

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _send('PUT', path, body: body, headers: headers);

  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _send('PATCH', path, body: body, headers: headers);

  Future<dynamic> delete(
    String path, {
    Map<String, String>? query,
    Object? body,
    Map<String, String>? headers,
  }) => _send('DELETE', path, query: query, body: body, headers: headers);

  Future<http.Response> getRaw(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
    String? customToken,
    Map<String, String>? headers,
  }) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final baseUrl = ApiConfig.baseUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse(
      '$baseUrl$normalizedPath',
    ).replace(queryParameters: query?.isEmpty ?? true ? null : query);
    final token = customToken ?? (authenticated ? await _tokens.read() : null);
    final reqHeaders = <String, String>{
      'Accept': headers?['Accept'] ?? 'application/pdf, application/json, */*',
      'Accept-Language': _language,
      'X-Request-Id': headers?['X-Request-Id'] ?? generateGuid(),
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    try {
      final request = http.Request('GET', uri)..headers.addAll(reqHeaders);
      _logRequest(request);
      final streamed = await _client.send(request).timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamed);
      _logResponse(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      final decoded = _decode(response);
      throw _buildApiException(response.statusCode, decoded);
    } on ApiException {
      rethrow;
    } catch (exception) {
      _logError('GET', uri, exception);
      throw const ApiException('Unable to retrieve document. Please try again.');
    }
  }

  Future<Uint8List> getBytes(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
    String? customToken,
  }) async {
    final response = await getRaw(
      path,
      query: query,
      authenticated: authenticated,
      customToken: customToken,
    );
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.contains('application/json')) {
      final decoded = _decode(response);
      if (decoded is Map) {
        final url = decoded['url']?.toString() ??
            decoded['download_url']?.toString() ??
            decoded['file']?.toString() ??
            decoded['file_url']?.toString() ??
            decoded['pdf_url']?.toString();
        if (url != null && url.isNotEmpty) {
          final fileRes = await _client.get(Uri.parse(url)).timeout(ApiConfig.timeout);
          return fileRes.bodyBytes;
        }
      }
    }
    return response.bodyBytes;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = true,
    String? customToken,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final baseUrl = ApiConfig.baseUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse(
      '$baseUrl$normalizedPath',
    ).replace(queryParameters: query?.isEmpty ?? true ? null : query);
    final token = customToken ?? (authenticated ? await _tokens.read() : null);
    final reqHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Accept-Language': _language,
      'X-Request-Id': headers?['X-Request-Id'] ?? generateGuid(),
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    try {
      final request = http.Request(method, uri)..headers.addAll(reqHeaders);
      if (body != null) request.body = jsonEncode(body);
      _logRequest(request);
      final effectiveTimeout = timeout ?? ApiConfig.timeout;
      final streamed = await _client.send(request).timeout(effectiveTimeout);
      final response = await http.Response.fromStream(streamed);
      _logResponse(response);
      final decoded = _decode(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw _buildApiException(response.statusCode, decoded);
    } on ApiException {
      rethrow;
    } on FormatException catch (exception) {
      _logError(method, uri, exception);
      throw const ApiException('The server returned an unreadable response.');
    } catch (exception) {
      _logError(method, uri, exception);
      throw const ApiException('Unable to reach Safer Be. Please try again.');
    }
  }

  ApiException _buildApiException(int statusCode, dynamic decoded) {
    if (decoded is! Map) {
      return ApiException('The server could not complete this request.', statusCode: statusCode);
    }

    String message = 'The server could not complete this request.';
    String? code;
    dynamic details;
    String? actionRequired = decoded['action_required']?.toString();
    int? errorCode = decoded['error_code'] is int ? decoded['error_code'] as int : int.tryParse(decoded['error_code']?.toString() ?? '');
    num? oldPrice = decoded['old_price'] is num ? decoded['old_price'] as num : num.tryParse(decoded['old_price']?.toString() ?? '');
    num? newPrice = decoded['new_price'] is num ? decoded['new_price'] as num : num.tryParse(decoded['new_price']?.toString() ?? '');
    String? traceId = decoded['trace_id']?.toString();

    // Shape A: error is object
    if (decoded['error'] is Map) {
      final errorMap = decoded['error'] as Map;
      code = errorMap['code']?.toString();
      message = errorMap['message']?.toString() ?? message;
      details = errorMap['details'];
    } else if (decoded['error'] is String) {
      // Shape B: error is string code
      code = decoded['error'].toString();
      message = decoded['message']?.toString() ?? code;
    } else if (decoded['message'] is String && (decoded['message'] as String).isNotEmpty) {
      message = decoded['message'].toString();
    }

    final errorsMap = _extractErrors(decoded, details);

    return ApiException(
      message,
      statusCode: statusCode,
      code: code,
      errors: errorsMap,
      details: details,
      actionRequired: actionRequired,
      errorCode: errorCode,
      oldPrice: oldPrice,
      newPrice: newPrice,
      traceId: traceId,
    );
  }

  Map<String, List<String>> _extractErrors(Map decoded, dynamic details) {
    final raw = decoded['errors'] ?? (details is Map ? details : null);
    if (raw is! Map) return const {};
    return raw.map((key, value) {
      final messages = value is List ? value : [value];
      return MapEntry(
        key.toString(),
        messages.map((item) => item.toString()).toList(growable: false),
      );
    });
  }

  void _logRequest(http.Request request) {
    if (!_logTraffic) return;
    debugPrint('[Safer Be API] Request');
    debugPrint('[Safer Be API] ${request.method} ${request.url}');
    debugPrint('[Safer Be API] Headers: ${_safeHeaders(request.headers)}');
    if (request.body.isNotEmpty) {
      debugPrint('[Safer Be API] Body: ${_trimForLog(request.body)}');
    }
    debugPrint('[Safer Be API] End request');
  }

  void _logResponse(http.Response response) {
    if (!_logTraffic) return;
    debugPrint('[Safer Be API] Response');
    debugPrint(
      '[Safer Be API] ${response.request?.method ?? 'REQUEST'} ${response.request?.url}',
    );
    debugPrint('[Safer Be API] Status: ${response.statusCode}');
    debugPrint('[Safer Be API] Headers: ${_safeHeaders(response.headers)}');
    debugPrint('[Safer Be API] Body: ${_trimForLog(response.body)}');
    debugPrint('[Safer Be API] End response');
  }

  void _logError(String method, Uri uri, Object exception) {
    if (!_logTraffic) return;
    debugPrint('[Safer Be API] Error');
    debugPrint('[Safer Be API] $method $uri');
    debugPrint('[Safer Be API] $exception');
    debugPrint('[Safer Be API] End error');
  }

  Map<String, String> _safeHeaders(Map<String, String> headers) {
    return headers.map((key, value) {
      final lowerKey = key.toLowerCase();
      if (lowerKey == 'authorization' ||
          lowerKey == 'cookie' ||
          lowerKey == 'set-cookie') {
        return MapEntry(key, '***');
      }
      return MapEntry(key, value);
    });
  }

  String _trimForLog(String value) {
    if (value.length <= _maxLogBodyLength) return value;
    final hidden = value.length - _maxLogBodyLength;
    return '${value.substring(0, _maxLogBodyLength)}... [truncated $hidden chars]';
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    final text = utf8.decode(response.bodyBytes).trim();
    if (text.isEmpty) return null;
    return jsonDecode(text);
  }
}

