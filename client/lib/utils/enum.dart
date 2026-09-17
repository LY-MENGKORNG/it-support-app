import 'package:json_annotation/json_annotation.dart';

/// A domain enum with a stable over-the-wire spelling.
abstract interface class WireEnum {
  String get wire;
}

extension WireValues<T extends WireEnum> on List<T> {
  T? tryByWire(String? wire) {
    for (final value in this) {
      if (value.wire == wire) return value;
    }
    return null;
  }

  /// [label] names the enum in the failure, so a bad payload says which field
  /// it came from rather than just that some enum did not match.
  T byWire(String wire, {required String label}) {
    return tryByWire(wire) ?? (throw FormatException('Unknown $label: $wire'));
  }
}

/// Bridges a [WireEnum] into the generated `fromJson`.
abstract class WireConverter<T extends WireEnum>
    implements JsonConverter<T, String> {
  const WireConverter();

  @override
  String toJson(T object) => object.wire;
}
