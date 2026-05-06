List<T> parseList<T>(dynamic json, T Function(Map<String, dynamic>) fromJson) {
  final data = switch (json) {
    {'items': final List items} => items,
    {'data': final List data} => data,
    {'results': final List results} => results,
    final List items => items,
    _ => const [],
  };

  return data
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

Map<String, dynamic> parseObject(dynamic json) {
  if (json is Map<String, dynamic>) return json;
  if (json is Map) return Map<String, dynamic>.from(json);
  return <String, dynamic>{};
}
