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

void main() {
  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

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
