import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/config/dependencies.dart';
import 'package:app/main_app.dart';

void main() {
  // Building the dependency graph touches plugin channels (shared_preferences),
  // so the binding has to exist first.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MultiProvider(providers: providersRemote, child: const MainApp()));
}
