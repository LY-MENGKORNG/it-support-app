import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that tolerates being notified after it is disposed.
///
/// Every notification in a view model happens after an `await`: the repository
/// call that was in flight when the user popped the screen still lands, and by
/// then the object it lands on is gone. [ChangeNotifier.notifyListeners]
/// asserts in that case, so the answer is to notice and drop the notification —
/// there is nobody left to tell — rather than crash on the way out.
///
/// The guard *overrides* [notifyListeners] rather than sitting beside it under
/// another name. A safer method you have to remember to call is one somebody
/// will forget, and every caller that already exists would have to be edited:
/// mixing this in is the entire opt-in, and even a `notifyListeners` tear-off
/// handed to another object comes back guarded.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  /// Whether this object has been disposed.
  ///
  /// True from the moment `dispose` reaches this mixin — which is *after* a
  /// subclass's own `dispose` body, since that body is what calls
  /// `super.dispose()`. Work that resumes after an `await` is always later than
  /// that, which is what this is for: use it to skip the *work*, not just the
  /// notification, once nobody is listening.
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
