import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liferpg/ui/widgets/common/app_drawer.dart';

void main() {
  testWidgets('groups navigation destinations by RPG workflow', (tester) async {
    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDrawer(
            selectedIndex: 0,
            onItemSelected: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('QUEST LOG'), findsOneWidget);
    expect(find.text('CHARACTER'), findsOneWidget);
    expect(find.text('LOOT & ECONOMY'), findsOneWidget);
    expect(find.text('Focus Quest'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('SYSTEM'),
      80,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('LORE & TAVERN'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Shop'),
      -80,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Shop'));
    await tester.pump();

    expect(selectedIndex, 10);
  });
}
