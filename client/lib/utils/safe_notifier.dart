import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that tolerates being notified after it is disposed.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  /// Whether this object has been disposed.
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
