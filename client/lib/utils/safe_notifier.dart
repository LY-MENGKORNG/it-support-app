import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that tolerates being notified after it is disposed.
///
/// Every notification in a view model happens after an `await`: the repository
/// call that was in flight when the user popped the screen still lands, and by
/// then the object it lands on is gone. [ChangeNotifier.notifyListeners]
/// asserts in that case, so the answer is to notice and drop the notification —
/// there is nobody left to tell — rather than crash on the way out.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  /// Whether [dispose] has already run. Guard post-`await` work with this.
  bool get isDisposed => _disposed;

  /// [notifyListeners], minus the assertion when this object is already gone.
  void notifySafely() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
