import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/player.dart';
import 'package:liferpg/data/models/reward.dart';
import 'package:liferpg/providers/inventory_provider.dart';
import 'package:liferpg/providers/player_provider.dart';
import 'package:liferpg/providers/reward_provider.dart';
import 'package:liferpg/ui/screens/shop/shop_screen.dart';

class FakeRewardProvider extends RewardProvider {
  FakeRewardProvider(this.fakeRewards);

  final List<Reward> fakeRewards;

  @override
  List<Reward> get rewards => fakeRewards;

  @override
  bool get isLoading => false;

  @override
  Future<void> loadRewards() async {}
}

class FakePlayerProvider extends PlayerProvider {
  @override
  Player? get player => Player(rewardPoints: 120);
}

class FakeInventoryProvider extends InventoryProvider {
  @override
  Future<void> loadItems() async {}
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

  testWidgets('shop reward card fits a small mobile viewport', (tester) async {
    setViewport(tester, const Size(360, 740));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RewardProvider>.value(
            value: FakeRewardProvider([
              Reward(
                id: 1,
                name: 'Very long reward name for a real-world guild perk',
                description:
                    'A longer reward description should not force the purchase action off screen.',
                priceRp: 30,
              ),
            ]),
          ),
          ChangeNotifierProvider<PlayerProvider>.value(
            value: FakePlayerProvider(),
          ),
          ChangeNotifierProvider<InventoryProvider>.value(
            value: FakeInventoryProvider(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ShopScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('120 RP'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Comprar'), findsOneWidget);
  });
}
