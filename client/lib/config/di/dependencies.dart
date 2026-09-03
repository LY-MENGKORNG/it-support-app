import 'package:app/data/services/local/shared_preference_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
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

List<SingleChildWidget> get remoteProviders => [
  //  NOTE: services
  Provider(
    create: (context) => RestClient(),
    dispose: (_, client) => client.dispose(),
  ),
  Provider(create: (context) => const SharedPreferencesService()),

  //  NOTE: endpoints
  Provider(create: (context) => AuthApi(context.read())),
  Provider(create: (context) => RequestApi(context.read())),
  Provider(create: (context) => CommentApi(context.read())),
  Provider(create: (context) => UserApi(context.read())),
  Provider(create: (context) => CategoryApi(context.read())),

  //  NOTE: repositories
  Provider<RequestRepository>(
    create: (context) => RemoteRequestRepository(
      requests: context.read(),
      comments: context.read(),
    ),
  ),
  Provider<UserRepository>(
    create: (context) => RemoteUserRepository(users: context.read()),
  ),
  Provider<CategoryRepository>(
    create: (context) => RemoteCategoryRepository(categories: context.read()),
  ),

  //  NOTE: change notifiers
  ChangeNotifierProvider<SessionRepository>(
    create: (context) {
      final client = context.read<RestClient>();
      final session = RemoteSessionRepository(
        auth: context.read(),
        preferences: context.read(),
      );

      client.authTokenProvider = () => session.accessToken;

      client.onUnauthorized = session.signOut;

      return session;
    },
  ),
];
