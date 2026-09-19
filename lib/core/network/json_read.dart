dynamic apiData(dynamic json) {
  if (json is Map && json.containsKey('data')) return json['data'];
  return json;
}

List<Map<String, dynamic>> apiList(dynamic json) {
  final data = apiData(json);
  final value = data is Map
      ? data['data'] ??
            data['results'] ??
            data['items'] ??
            data['airports'] ??
            data['cities'] ??
            data['countries'] ??
            data['airlines'] ??
            data['hotels'] ??
            data['rooms'] ??
            data['flights'] ??
            data['flight_types'] ??
            data['journey_types']
      : data;
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String readText(Map data, List<String> keys, [String fallback = '']) {
  for (final key in keys) {
    final value = data[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return fallback;
}

num readNumber(Map data, List<String> keys, [num fallback = 0]) {
  for (final key in keys) {
    final value = data[key];
    if (value is num) return value;
    final parsed = num.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}
