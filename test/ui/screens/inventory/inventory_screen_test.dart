import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/inventory_item.dart';
import 'package:liferpg/providers/inventory_provider.dart';
import 'package:liferpg/ui/screens/inventory/inventory_screen.dart';

class FakeInventoryProvider extends InventoryProvider {
  List<InventoryItem> fakeItems = [
    InventoryItem(id: 1, name: 'Free hour', quantity: 1),
  ];

  @override
  List<InventoryItem> get items => fakeItems;

  @override
  bool get isLoading => false;

  @override
  Future<void> loadItems() async {}

  @override
  Future<void> consumeItem(int id) async {
    fakeItems = [];
    notifyListeners();
  }
}

void main() {
  testWidgets('shows purchased item and removes it after use', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<InventoryProvider>.value(
        value: FakeInventoryProvider(),
        child: const MaterialApp(home: Scaffold(body: InventoryScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('Free hour'), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Usar'));
    await tester.pump();

    expect(find.text('Free hour'), findsNothing);
    expect(find.text('Nenhum item no inventário.'), findsOneWidget);
  });
}
