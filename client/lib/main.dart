import 'package:app/app.dart';
import 'package:app/config/di/dependencies.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerDeps();
  runApp(const App());
}
