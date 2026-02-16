import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/models/player.dart';
import 'package:liferpg/ui/widgets/player/player_stats_header.dart';

void main() {
  testWidgets('manual mode allows tapping energy bar', (tester) async {
    int? value;
    final player = Player(
      energyMode: 'manual',
      currentEnergy: 40,
      wakeUpTime: '08:00',
      sleepTime: '22:00',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerStatsHeader(
            player: player,
            onManualEnergyChanged: (newValue) => value = newValue,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('energy-bar')));
    await tester.pump();

    expect(value, isNotNull);
  });

  testWidgets('automatic mode ignores taps on energy bar', (tester) async {
    int calls = 0;
    final player = Player(
      energyMode: 'auto',
      currentEnergy: 40,
      wakeUpTime: '08:00',
      sleepTime: '22:00',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerStatsHeader(
            player: player,
            onManualEnergyChanged: (_) => calls++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('energy-bar')));
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('automatic mode timer label uses minute precision', (
    tester,
  ) async {
    final player = Player(
      energyMode: 'auto',
      currentEnergy: 40,
      wakeUpTime: '08:00',
      sleepTime: '22:00',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlayerStatsHeader(player: player)),
      ),
    );

    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    final hasMinutePrecision = textWidgets.any(
      (text) => RegExp(r'^\d{2}:\d{2} left$').hasMatch(text.data ?? ''),
    );

    expect(hasMinutePrecision, true);
  });
}
