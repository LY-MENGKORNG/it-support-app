import 'package:app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';

class ITSupportApp extends StatelessWidget {
  const ITSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'IT Support App';
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromRGBO(0, 0, 0, 10),
        ),
      ),
      home: const HomeScreen(title: appTitle),
    );
  }
}
