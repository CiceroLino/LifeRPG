import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/player.dart';
import 'package:liferpg/l10n/app_localizations.dart';
import 'package:liferpg/providers/mission_provider.dart';
import 'package:liferpg/providers/player_provider.dart';
import 'package:liferpg/providers/settings_provider.dart';
import 'package:liferpg/providers/skill_provider.dart';
import 'package:liferpg/ui/screens/settings/settings_screen.dart';

class FakeMissionProvider extends MissionProvider {
  int loadMissionsCalls = 0;

  @override
  Future<void> loadMissions() async {
    loadMissionsCalls++;
  }
}

class FakeSkillProvider extends SkillProvider {
  int loadSkillsCalls = 0;

  @override
  Future<void> loadSkills() async {
    loadSkillsCalls++;
  }
}

class FakePlayerProvider extends PlayerProvider {
  final Player _player = Player(
    energyMode: 'manual',
    wakeUpTime: '08:00',
    sleepTime: '22:00',
  );

  @override
  Player? get player => _player;

  int loadPlayerCalls = 0;

  @override
  Future<void> loadPlayer() async {
    loadPlayerCalls++;
  }
}

class FakeSettingsProvider extends SettingsProvider {
  int factoryResetCalls = 0;
  int resetCharacterCalls = 0;
  String _language = 'en';

  @override
  bool get isLoading => false;

  @override
  String get language => _language;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
  }

  @override
  Future<void> factoryReset() async {
    factoryResetCalls++;
  }

  @override
  Future<void> resetCharacter() async {
    resetCharacterCalls++;
  }
}

Widget _settingsHarness({
  required SettingsProvider settings,
  required MissionProvider mission,
  required SkillProvider skill,
  required PlayerProvider player,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<MissionProvider>.value(value: mission),
      ChangeNotifierProvider<SkillProvider>.value(value: skill),
      ChangeNotifierProvider<PlayerProvider>.value(value: player),
    ],
    child: Consumer<SettingsProvider>(
      builder: (context, settings, _) => MaterialApp(
        locale: AppLocalizations.localeFromCode(settings.language),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SettingsScreen()),
      ),
    ),
  );
}

void main() {
  testWidgets('character profile reset reloads player data after confirmation', (
    tester,
  ) async {
    final settings = FakeSettingsProvider();
    final player = FakePlayerProvider();

    await tester.pumpWidget(
      _settingsHarness(
        settings: settings,
        mission: FakeMissionProvider(),
        skill: FakeSkillProvider(),
        player: player,
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Reset Character Profile'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(
      find.widgetWithText(ListTile, 'Reset Character Profile'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Reset Character Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'RESET'));
    await tester.pumpAndSettle();

    expect(settings.resetCharacterCalls, 1);
    expect(player.loadPlayerCalls, 1);
  });

  testWidgets('factory reset recarrega providers de dados', (tester) async {
    final settings = FakeSettingsProvider();
    final mission = FakeMissionProvider();
    final skill = FakeSkillProvider();
    final player = FakePlayerProvider();

    await tester.pumpWidget(
      _settingsHarness(
        settings: settings,
        mission: mission,
        skill: skill,
        player: player,
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Factory Reset / Wipe All'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(
      find.widgetWithText(ListTile, 'Factory Reset / Wipe All'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Factory Reset / Wipe All'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'WIPE ALL DATA'));
    await tester.pumpAndSettle();

    expect(settings.factoryResetCalls, 1);
    expect(player.loadPlayerCalls, 1);
    expect(mission.loadMissionsCalls, 1);
    expect(skill.loadSkillsCalls, 1);
  });

  testWidgets('language selector supports English, pt_BR, and Spanish only', (
    tester,
  ) async {
    final settings = FakeSettingsProvider();
    await tester.pumpWidget(
      _settingsHarness(
        settings: settings,
        mission: FakeMissionProvider(),
        skill: FakeSkillProvider(),
        player: FakePlayerProvider(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Language'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsWidgets);
    expect(find.text('Português (Brasil)'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('Français'), findsNothing);

    await tester.tap(find.text('Português (Brasil)'));
    await tester.pumpAndSettle();

    expect(settings.language, 'pt_BR');
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Português (Brasil)'), findsOneWidget);
  });
}
