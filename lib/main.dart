import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/platform/database_platform.dart';
import 'core/theme/app_theme.dart';
import 'providers/mission_provider.dart';
import 'providers/player_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/reward_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/notebook_provider.dart';
import 'providers/tavern_provider.dart';
import 'providers/tome_provider.dart';
import 'providers/settings_provider.dart';
import 'services/mission_reminder_service.dart';
import 'services/tavern_audio_service.dart';
import 'l10n/app_localizations.dart';
import 'ui/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDatabasePlatform();
  await MissionReminderService.instance.initialize();
  final tavernAudioService = await initTavernAudioService();

  runApp(MyApp(tavernAudioService: tavernAudioService));
}

class MyApp extends StatelessWidget {
  final TavernPlayback tavernAudioService;

  const MyApp({super.key, required this.tavernAudioService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()..loadPlayer()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        ChangeNotifierProvider(create: (_) => RewardProvider()..loadRewards()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()..loadItems()),
        ChangeNotifierProvider(
          create: (_) => MissionProvider()..loadMissions(),
        ),
        ChangeNotifierProvider(create: (_) => SkillProvider()..loadSkills()),
        ChangeNotifierProvider(
          create: (_) => NotebookProvider()..loadNotebooks(),
        ),
        ChangeNotifierProvider(create: (_) => TomeProvider()..loadTomes()),
        ChangeNotifierProvider(
          create: (_) =>
              TavernProvider(playback: tavernAudioService)..loadTracks(),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..initialize()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final locale = AppLocalizations.localeFromCode(settings.language);

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
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
