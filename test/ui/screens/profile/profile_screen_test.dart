import 'package:liferpg/services/app_data_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/player.dart';
import 'package:liferpg/providers/player_provider.dart';
import 'package:liferpg/ui/screens/profile/profile_screen.dart';

class FakePlayerProvider extends PlayerProvider {
  Player _player = Player(
    name: 'A Very Long Hero Name',
    title: 'Chronomancer of Daily Quests',
    description: 'Balances HP, XP, RP, and real-world duties.',
  );

  @override
  Player? get player => _player;

  @override
  Future<void> updatePlayer(Player player) async {
    _player = player;
    notifyListeners();
  }
}

class LatePlayerProvider extends PlayerProvider {
  Player? value;
  @override
  Player? get player => value;
  void emit(Player player) {
    value = player;
    notifyListeners();
  }
}

void main() {
  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('late player hydrates editor and updates preserve dirty input', (
    tester,
  ) async {
    final provider = LatePlayerProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<PlayerProvider>.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pump();
    provider.emit(Player(name: 'Loaded hero', title: 'Mage'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Loaded hero'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved hero');
    provider.emit(Player(name: 'External hero', title: 'Mage', totalXP: 100));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved hero'), findsOneWidget);
    expect(find.text('External hero'), findsNothing);
  });

  testWidgets('replacement clears old draft, rejected restore preserves it', (
    tester,
  ) async {
    final provider = LatePlayerProvider()
      ..value = Player(name: 'Previous data', title: 'Mage');
    await tester.pumpWidget(
      ChangeNotifierProvider<PlayerProvider>.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Previous data draft',
    );
    final coordinator = AppDataCoordinator(
      quiesce: () async {},
      reload: [
        () async {
          provider.emit(Player(name: 'Player', title: 'Adventurer'));
        },
      ],
    );
    await coordinator.replaceData(
      () async => false,
      wasReplaced: (value) => value,
    );
    await tester.pumpAndSettle();
    expect(find.text('Previous data draft'), findsOneWidget);
    await coordinator.replaceData(() async => true);
    await tester.pumpAndSettle();
    expect(find.text('Previous data draft'), findsNothing);
    expect(find.text('Player'), findsOneWidget);
  });

  testWidgets('profile editor fits a small mobile viewport', (tester) async {
    setViewport(tester, const Size(360, 740));

    await tester.pumpWidget(
      ChangeNotifierProvider<PlayerProvider>.value(
        value: FakePlayerProvider(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Título/Classe'), findsOneWidget);
    expect(find.text('Salvar alterações'), findsOneWidget);
  });
}
