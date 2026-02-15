import 'package:flutter/material.dart';
import 'dart:io' show Platform;

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/theme/app_theme.dart';
import 'providers/mission_provider.dart';
import 'providers/player_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/settings_provider.dart';
import 'l10n/app_localizations.dart';
import 'ui/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(
          create: (_) => MissionProvider()..loadMissions(),
        ),
        ChangeNotifierProvider(create: (_) => SkillProvider()..loadSkills()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..initialize()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          Locale locale = Locale(settings.language);

          return MaterialApp(
            title: 'LifeRPG',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('pt'),
              Locale('es'),
            ],
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
