import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/ui/core/ui/home_shell.dart';
import 'package:app/ui/requests/view_models/create_request_viewmodel.dart';
import 'package:app/ui/requests/view_models/request_detail_viewmodel.dart';
import 'package:app/ui/requests/view_models/request_list_viewmodel.dart';
import 'package:app/ui/requests/widgets/create_request_screen.dart';
import 'package:app/ui/requests/widgets/request_detail_screen.dart';
import 'package:app/ui/requests/widgets/request_list_screen.dart';
import 'package:app/ui/auth/view_models/login_viewmodel.dart';
import 'package:app/ui/auth/widgets/login_screen.dart';
import 'package:app/ui/auth/widgets/splash_screen.dart';
import 'package:app/ui/settings/view_models/settings_viewmodel.dart';
import 'package:app/ui/settings/widgets/settings_screen.dart';
import 'package:app/ui/users/view_models/user_list_viewmodel.dart';
import 'package:app/ui/users/widgets/user_list_screen.dart';

import 'routes.dart';

/// The app's routes, and the guard that decides which of them you may see.
///
/// [sessionRepository] is passed down to every view model that needs it rather
/// than each resolving its own from the registry. Both would return the same
/// singleton in the running app — but only in the running app: a caller that
/// injects a different session (which is what the tests do) would get a router
/// redirecting on one object while its screens sign in and out of another, and
/// the two would drift with nothing to catch it. Threading the parameter makes
/// them the same object by construction.
GoRouter router(SessionRepository sessionRepository) => GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: sessionRepository,
  redirect: (context, state) => _guard(state, sessionRepository),
  routes: [
    GoRoute(
      path: Routes.splash,
      name: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.login,
      name: RouteNames.login,
      builder: (context, state) => _owned(
        () => LoginViewModel(sessionRepository: sessionRepository),
        (viewModel) => LoginScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: Routes.newRequest,
      name: RouteNames.newRequest,
      builder: (context, state) => _owned(
        () => CreateRequestViewModel(
          requestRepository: Get.find(),
          categoryRepository: Get.find(),
          sessionRepository: sessionRepository,
        ),
        (viewModel) => CreateRequestScreen(viewModel: viewModel),
      ),
    ),
    GoRoute(
      path: '${Routes.requests}/:id',
      name: RouteNames.requestDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return const _InvalidRequestScreen();

        return _owned(
          () => RequestDetailViewModel(
            requestRepository: Get.find(),
            userRepository: Get.find(),
            categoryRepository: Get.find(),
            sessionRepository: sessionRepository,
            requestId: id,
            preview: state.extra is Request ? state.extra! as Request : null,
          ),
          (viewModel) => RequestDetailScreen(viewModel: viewModel),
        );
      },
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.requests,
              name: RouteNames.requests,
              builder: (context, state) => _owned(
                () => RequestListViewModel(
                  requestRepository: Get.find(),
                  categoryRepository: Get.find(),
                  sessionRepository: sessionRepository,
                ),
                (viewModel) => RequestListScreen(viewModel: viewModel),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.users,
              name: RouteNames.users,
              builder: (context, state) => _owned(
                () => UserListViewModel(userRepository: Get.find()),
                (viewModel) => UserListScreen(viewModel: viewModel),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              name: RouteNames.settings,
              builder: (context, state) => _owned(
                () => SettingsViewModel(sessionRepository: sessionRepository),
                (viewModel) => SettingsScreen(viewModel: viewModel),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
);

String? _guard(GoRouterState state, SessionRepository session) {
  final location = state.matchedLocation;

  if (session.isRestoring) {
    return location == Routes.splash ? null : Routes.splash;
  }

  if (location == Routes.splash) {
    return session.isSignedIn ? Routes.requests : Routes.login;
  }

  if (!session.isSignedIn && location != Routes.login) {
    return Routes.login;
  }

  if (session.isSignedIn && location == Routes.login) {
    return Routes.requests;
  }

  return null;
}

/// Gives a route's view model an owner.
///
/// Built inline in a `builder`, as these used to be, a view model has none:
/// nothing ever calls its `dispose`, so its commands, debounce timers and — in
/// [SettingsViewModel]'s case — a listener on the shared [SessionRepository]
/// outlive the screen, and a route visited twice leaves two of them behind.
///
/// This is a plain [StatefulWidget] rather than a `Get.put`: GetX calls no
/// teardown on a [ChangeNotifier], so registering one here would give it a
/// home but still never dispose it — the leak this exists to fix, back again.
Widget _owned<T extends ChangeNotifier>(
  T Function() create,
  Widget Function(T viewModel) build,
) => _Owned<T>(create, build);

class _Owned<T extends ChangeNotifier> extends StatefulWidget {
  const _Owned(this.create, this.build);

  final T Function() create;
  final Widget Function(T viewModel) build;

  @override
  State<_Owned<T>> createState() => _OwnedState<T>();
}

class _OwnedState<T extends ChangeNotifier> extends State<_Owned<T>> {
  /// Assigned in [initState], not by a `late final` field initializer.
  ///
  /// A `late` initializer runs on first *read*, and `dispose` reads it too, so
  /// a route torn down before it ever built would construct a view model in
  /// order to destroy it — running constructor side effects for a screen
  /// nobody saw, and [RequestListViewModel] starts two requests in its. A
  /// throw from `create` would also re-run there, surfacing from inside
  /// `dispose` and masking the original error.
  T? _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.create();
  }

  @override
  Widget build(BuildContext context) => widget.build(_viewModel!);

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }
}

class _InvalidRequestScreen extends StatelessWidget {
  const _InvalidRequestScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request')),
    body: const Center(child: Text('That request id is not valid.')),
  );
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error?.toString() ?? 'This page does not exist.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(Routes.requests),
              child: const Text('Back to requests'),
            ),
          ],
        ),
      ),
    ),
  );
}
