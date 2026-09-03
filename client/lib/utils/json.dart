library;

typedef Json = Map<String, dynamic>;

T _require<T>(Json json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw FormatException(
    'Expected "$key" to be $T but got ${value.runtimeType} ($value)',
  );
}

String stringOf(Json json, String key) => _require<String>(json, key);

int intOf(Json json, String key) => _require<int>(json, key);

int? intOrNull(Json json, String key) => json[key] as int?;

String? stringOrNull(Json json, String key) => json[key] as String?;

bool boolOr(Json json, String key, {required bool fallback}) =>
    json[key] as bool? ?? fallback;

DateTime dateOf(Json json, String key) =>
    DateTime.parse(stringOf(json, key)).toLocal();

DateTime? dateOrNull(Json json, String key) {
  final value = json[key];

  if (value == null) return null;
  return DateTime.parse(value as String).toLocal();
}

Json objectOf(Json json, String key) => _require<Json>(json, key);

Json? objectOrNull(Json json, String key) => json[key] as Json?;

List<T> listOf<T>(Json json, String key, T Function(Json) parse) {
  final value = json[key];
  if (value == null) return const [];
  if (value is! List<dynamic>) {
    throw FormatException(
      'Expected "$key" to be a list, got ${value.runtimeType}',
    );
  }
  return value.cast<Json>().map(parse).toList(growable: false);
}
