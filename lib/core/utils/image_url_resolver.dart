import '../config/api_config.dart';

/// Resolves raw image URLs from API payloads, local assets, or relative paths
/// into fully qualified, loadable image strings.
String resolveOfferImageUrl(String? rawUrl) {
  if (rawUrl == null) return '';
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return '';

  // Fully qualified web URLs
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  // Protocol-relative URLs
  if (trimmed.startsWith('//')) {
    return 'https:$trimmed';
  }

  // Flutter local asset paths
  if (trimmed.startsWith('assets/')) {
    return trimmed;
  }

  // Derive origin from ApiConfig.baseUrl
  String origin = 'https://backend.saferbe.com';
  try {
    final uri = Uri.parse(ApiConfig.baseUrl);
    if (uri.hasScheme && uri.host.isNotEmpty) {
      origin =
          '${uri.scheme}://${uri.host}${uri.hasPort && uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    }
  } catch (_) {}

  if (trimmed.startsWith('/')) {
    return '$origin$trimmed';
  }

  return '$origin/$trimmed';
}
