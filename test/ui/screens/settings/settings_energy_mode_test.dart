import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/player.dart';
import 'package:liferpg/l10n/app_localizations.dart';
import 'package:liferpg/providers/player_provider.dart';
import 'package:liferpg/providers/settings_provider.dart';
import 'package:liferpg/ui/screens/settings/settings_screen.dart';

class FakeSettingsProvider extends SettingsProvider {
  @override
  bool get isLoading => false;

  @override
  Future<void> initialize() async {}
}

class FakePlayerProvider extends PlayerProvider {
  int setEnergyModeCalls = 0;
  String? lastEnergyMode;

  Player _player = Player(
    energyMode: 'manual',
    wakeUpTime: '08:00',
    sleepTime: '22:00',
  );

  @override
  Player? get player => _player;

  @override
  Future<void> setEnergyMode(String mode) async {
    setEnergyModeCalls++;
    lastEnergyMode = mode;
    _player = _player.copyWith(energyMode: mode);
    notifyListeners();
  }
}

void main() {
  testWidgets('shows wake/sleep controls only in automatic mode', (
    tester,
  ) async {
    final player = FakePlayerProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(
            value: FakeSettingsProvider(),
          ),
          ChangeNotifierProvider<PlayerProvider>.value(value: player),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Energy Mode'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('Energy Mode'), findsOneWidget);
    expect(find.text('Wake Up Time'), findsNothing);
    expect(find.text('Sleep Time'), findsNothing);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic').last);
    await tester.pumpAndSettle();

    expect(player.setEnergyModeCalls, 1);
    expect(player.lastEnergyMode, 'auto');
    expect(find.text('Wake Up Time'), findsOneWidget);
    expect(find.text('Sleep Time'), findsOneWidget);
  });
}
