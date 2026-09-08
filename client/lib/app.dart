import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/routing/router.dart';
import 'package:app/ui/core/themes/theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final session = Get.find<SessionRepository>();
    _router = router(session);

    session.restore();
  }

  @override
  Widget build(context) {
    return MaterialApp.router(
      title: '🚨 IT Support',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}
