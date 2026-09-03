abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';

  static const requests = '/requests';
  static const newRequest = '/requests/new';

  static String requestDetail(int id) => '/requests/$id';

  static const users = '/users';
  static const settings = '/settings';
}

abstract final class RouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const requests = 'requests';
  static const newRequest = 'new-request';
  static const requestDetail = 'request-detail';
  static const users = 'users';
  static const settings = 'settings';
}
