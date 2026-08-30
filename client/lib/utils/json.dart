/// Small helpers for reading JSON.
///
/// `jsonDecode` hands back `Map<String, dynamic>`, so every field access is
/// `dynamic` — which switches off static checking. These functions put the cast
/// in one place and fail with a message naming the field, instead of a bare
/// `type 'Null' is not a subtype of type 'String'` from somewhere in a factory.
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

/// Dates cross the wire as UTC ISO-8601 strings; the UI wants local time.
DateTime dateOf(Json json, String key) =>
    DateTime.parse(stringOf(json, key)).toLocal();

DateTime? dateOrNull(Json json, String key) {
  final value = json[key];
  // Note the explicit null check. Writing `value ? ... : null` compiles here
  // because `value` is dynamic, then throws at runtime — dynamic silences the
  // analyzer, it does not make the code correct.
  if (value == null) return null;
  return DateTime.parse(value as String).toLocal();
}

Json objectOf(Json json, String key) => _require<Json>(json, key);

Json? objectOrNull(Json json, String key) => json[key] as Json?;

List<T> listOf<T>(Json json, String key, T Function(Json) parse) {
  final value = json[key];
  if (value == null) return const [];
  if (value is! List) {
    throw FormatException(
      'Expected "$key" to be a list, got ${value.runtimeType}',
    );
  }
  return value.cast<Json>().map(parse).toList(growable: false);
}
