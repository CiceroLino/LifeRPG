import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeRPG',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // default dark
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}