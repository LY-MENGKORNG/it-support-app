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
import 'package:app/data/services/api/api_client.dart';
import 'package:app/data/services/shared_preferences_service.dart';

/// NOTE: The object graph, built once at startup.
///
/// Registering repositories by their **abstract** type is the point: every
/// `context.read<RequestRepository>()` is satisfied by whichever implementation
/// is listed here, so swapping in a local or fake one is a change to this file
/// alone — no view model or widget knows the difference.
///
/// Order matters: a provider can only `read()` something declared above it.
List<SingleChildWidget> get providersRemote => [
  // --- NOTE: services: one per external data source, no state
  Provider(
    create: (context) => ApiClient(),
    dispose: (_, client) => client.dispose(),
  ),
  Provider(create: (context) => const SharedPreferencesService()),

  // --- NOTE: repositories: the source of truth for each kind of data
  Provider<RequestRepository>(
    create: (context) => RequestRepositoryRemote(apiClient: context.read()),
  ),
  Provider<UserRepository>(
    create: (context) => UserRepositoryRemote(apiClient: context.read()),
  ),
  Provider<CategoryRepository>(
    create: (context) => CategoryRepositoryRemote(apiClient: context.read()),
  ),
  // The session is a ChangeNotifier because it holds app-wide state that both
  // the router and several view models listen to.
  ChangeNotifierProvider<SessionRepository>(
    create: (context) {
      final apiClient = context.read<ApiClient>();
      final session = SessionRepositoryRemote(
        apiClient: apiClient,
        preferences: context.read(),
      );

      // The two halves of authentication, tied together here and nowhere else.
      //
      // The client cannot own the token (that is session state, and the router
      // has to react to it) and the session cannot own the header (that is
      // transport, and every request needs it). So each is given a way to ask
      // the other, in the one file that already knows about both. Everything
      // else in the app — repositories, view models, widgets — stays unaware
      // that requests are authenticated at all.
      apiClient.authTokenProvider = () => session.accessToken;

      // A rejected token ends the session wherever it is noticed, so an expired
      // login lands on the login screen instead of failing one screen at a
      // time. The router is listening, so no navigation is needed here.
      apiClient.onUnauthorized = session.signOut;

      return session;
    },
  ),
];
