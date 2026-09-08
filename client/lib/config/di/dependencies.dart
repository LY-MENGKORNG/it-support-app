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
  final session = RemoteSessionRepository(
    auth: Get.find(),
    preferences: Get.find(),
  );
  final client = Get.find<RestClient>();

  client.authTokenProvider = () => session.accessToken;
  client.onUnauthorized = session.signOut;

  Get.put<SessionRepository>(session, permanent: true);
}
