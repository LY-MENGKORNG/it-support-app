import 'package:get/get.dart';
import 'package:app/data/services/local/shared_preference_service.dart';
import 'package:app/data/repositories/category/category_repository.dart';
import 'package:app/data/repositories/category/category_repository_remote.dart';
import 'package:app/data/repositories/request/request_repository.dart';
import 'package:app/data/repositories/request/request_repository_remote.dart';
import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/data/repositories/session/session_repository_remote.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/data/repositories/user/user_repository_remote.dart';
import 'package:app/data/services/api/auth_api.dart';
import 'package:app/data/services/api/category_api.dart';
import 'package:app/data/services/api/comment_api.dart';
import 'package:app/data/services/api/request_api.dart';
import 'package:app/data/services/api/rest_client.dart';
import 'package:app/data/services/api/user_api.dart';

/// Registers the app's object graph into GetX's global registry.
///
/// Order is load-bearing, unlike the provider list this replaced: `Get.put` is
/// eager, and a `Get.find()` sitting in an argument list is resolved at
/// registration time. Moving a line above its dependency — an alphabetical
/// tidy-up of what now reads like a sorted list — crashes on launch with
/// `"CategoryApi" not found`, so the grouping below is the dependency order and
/// not a filing scheme.
///
/// Every registration is `permanent`. `Get.lazyPut` would restore provider's
/// laziness, but only with `fenix`, which lets an instance be dropped and
/// rebuilt — and the session wiring at the bottom binds *these two instances*
/// to each other for the life of the app. A rebuilt [RestClient] would come
/// back without its token provider, and every request after that would go out
/// unauthenticated.
void registerDeps() {
  // NOTE: services
  Get.put(RestClient(), permanent: true);
  Get.put(const SharedPreferencesService(), permanent: true);

  // NOTE: endpoints
  Get.put(AuthApi(Get.find()), permanent: true);
  Get.put(CategoryApi(Get.find()), permanent: true);
  Get.put(CommentApi(Get.find()), permanent: true);
  Get.put(RequestApi(Get.find()), permanent: true);
  Get.put(UserApi(Get.find()), permanent: true);

  // NOTE: repos
  Get.put<CategoryRepository>(
    RemoteCategoryRepository(categories: Get.find()),
    permanent: true,
  );
  Get.put<RequestRepository>(
    RemoteRequestRepository(requests: Get.find(), comments: Get.find()),
    permanent: true,
  );
  Get.put<UserRepository>(
    RemoteUserRepository(users: Get.find()),
    permanent: true,
  );

  // NOTE: change notifiers
  //
  // `RestClient.dispose()` is unreachable now: provider's `dispose:` callback
  // closed the `http.Client`, and GetX calls no teardown on a plain object —
  // `permanent` additionally exempts this one from `Get.delete`. Accepted
  // rather than making the transport a `GetxService` to get the hook back: the
  // client lives as long as the process and dies with it, and the tests that
  // care build their own.
  final session = RemoteSessionRepository(
    auth: Get.find(),
    preferences: Get.find(),
  );
  final client = Get.find<RestClient>();

  client.authTokenProvider = () => session.accessToken;
  client.onUnauthorized = session.signOut;

  Get.put<SessionRepository>(session, permanent: true);
}
