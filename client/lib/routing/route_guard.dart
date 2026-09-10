import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/routing/route.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Guards the app's routes based on the current session state.
String? guard(GoRouterState state, SessionRepository session) {
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


/// Wraps a widget in a ChangeNotifierProvider, and disposes the notifier when the widget is removed from the tree.
Widget owned<T extends ChangeNotifier>(
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

/// Disposes the notifier when the widget is removed from the tree.
class _OwnedState<T extends ChangeNotifier> extends State<_Owned<T>> {
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
