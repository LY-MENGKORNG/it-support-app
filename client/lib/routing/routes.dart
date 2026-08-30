/// Every route path in the app, in one place.
///
/// Screens navigate with `context.go(Routes.requests)` rather than a string
/// literal, so renaming a path is a single edit and a typo is a compile error
/// instead of a blank screen at runtime.
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';

  static const requests = '/requests';
  static const newRequest = '/requests/new';

  /// Detail paths carry the id, so a request is linkable and refreshable.
  static String requestDetail(int id) => '/requests/$id';

  static const users = '/users';
  static const settings = '/settings';
}

/// Named routes, used where a name reads better than a path.
abstract final class RouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const requests = 'requests';
  static const newRequest = 'new-request';
  static const requestDetail = 'request-detail';
  static const users = 'users';
  static const settings = 'settings';
}
