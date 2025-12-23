import 'package:flutter/material.dart';
import 'dart:io' show Platform;

import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/theme/app_theme.dart';
import 'providers/mission_provider.dart';
import 'providers/player_provider.dart';
import 'providers/skill_provider.dart';
import 'ui/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Habilita SQLite FFI para desktop (Linux/Windows/macOS).
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()..loadPlayer()),
        ChangeNotifierProvider(create: (_) => MissionProvider()..loadMissions()),
        ChangeNotifierProvider(create: (_) => SkillProvider()..loadSkills()),
      ],
      child: MaterialApp(
        title: 'LifeRPG',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}