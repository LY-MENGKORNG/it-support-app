/// 📦 Reusable types for the whole application.
library;

import 'dart:collection';

/// The type of JSON { }
typedef JsonType = Map<String, dynamic>;

/// Parse a JSON [JsonType] and return as [T]
typedef JsonParse<T> = T Function(JsonType);

typedef ErrorMapper = Exception Function(Object error, StackTrace stackTrace);

typedef Query = Map<String, dynamic>;

typedef Decoder<T> = T Function(Object? payload);

typedef ImmutableLV<T> = UnmodifiableListView<T>;

typedef MyMap<K extends String, V> = Map<K, V>;

/// chanthou.kim5@example.com, password-123
