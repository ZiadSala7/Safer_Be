class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.errors = const {},
    this.details,
    this.actionRequired,
    this.errorCode,
    this.oldPrice,
    this.newPrice,
    this.traceId,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, List<String>> errors;
  final dynamic details;
  final String? actionRequired;
  final int? errorCode;
  final num? oldPrice;
  final num? newPrice;
  final String? traceId;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isPriceConflict => statusCode == 409 || actionRequired == 'confirm_new_price';
  bool get isExpiredSession => statusCode == 410 || actionRequired == 'search_again';
  bool get isValidationError => statusCode == 422;
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => message;
}

