library;

typedef JsonType = Map<String, dynamic>;
typedef ParseFn<T> = T Function(JsonType);

class Json {
  final JsonType _json;

  Json(this._json);

  T _require<T>(String key) {
    final value = _json[key];

    if (value is T) return value;
    throw FormatException(
      'Expected "$key" to be $T but got ${value.runtimeType} ($value)',
    );
  }

  String stringOf(String key) => _require<String>(key);
  String? stringOrNull(String key) => _json[key] as String?;

  int intOf(String key) => _require<int>(key);
  int? intOrNull(String key) => _json[key] as int?;

  bool boolOr(String key, {required bool fallback}) {
    return _json[key] as bool? ?? fallback;
  }

  DateTime dateOf(String key) {
    return DateTime.parse(stringOf(key)).toLocal();
  }

  DateTime? dateOrNull(String key) {
    final value = _json[key];

    if (value == null) return null;
    return DateTime.parse(value as String).toLocal();
  }

  JsonType objectOf(String key) => _require<JsonType>(key);
  JsonType? objectOrNull(String key) => _json[key] as JsonType?;

  List<T> listOf<T>(String key, ParseFn<T> parse) {
    final value = _json[key];
    if (value == null) return const [];
    if (value is! List<dynamic>) {
      throw FormatException(
        'Expected "$key" to be a list, got ${value.runtimeType}',
      );
    }
    return value.cast<JsonType>().map(parse).toList(growable: false);
  }
}
