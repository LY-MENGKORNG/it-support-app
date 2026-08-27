import 'package:app/src/app/theme.dart';
import 'package:app/src/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';

class ITSupportApp extends StatelessWidget {
  const ITSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'IT Support App';
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(title: appTitle),
      routes: const {},
    );
  }
}
