import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/reward.dart';
import 'package:liferpg/providers/reward_provider.dart';
import 'package:liferpg/ui/screens/rewards/reward_form_screen.dart';
import 'package:liferpg/ui/screens/rewards/rewards_screen.dart';

class FakeRewardProvider extends RewardProvider {
  final List<Reward> fakeRewards;

  FakeRewardProvider(this.fakeRewards);

  @override
  List<Reward> get rewards => fakeRewards;

  @override
  bool get isLoading => false;

  @override
  Future<void> loadRewards() async {}
}

class FailingRewardProvider extends FakeRewardProvider {
  FailingRewardProvider() : super([]);
  @override
  String? get error => 'Storage unavailable';
  @override
  Future<void> addReward(Reward reward) async {}
}

void main() {
  testWidgets('shows registered reward price, stock, and admin actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RewardProvider>.value(
            value: FakeRewardProvider([
              Reward(
                id: 1,
                name: 'Cinema',
                priceRp: 30,
                isUnlimitedStock: false,
                stockRemaining: 2,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: RewardsScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('Cinema'), findsOneWidget);
    expect(find.text('30 RP'), findsOneWidget);
    expect(find.text('Estoque: 2'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Nova'), findsOneWidget);
    expect(find.byTooltip('Editar'), findsOneWidget);
    expect(find.byTooltip('Arquivar'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Comprar'), findsNothing);
  });

  testWidgets('failed reward save keeps entered data and shows error', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<RewardProvider>.value(
        value: FailingRewardProvider(),
        child: const MaterialApp(home: RewardFormScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reward-name-field')),
      'Keep me',
    );
    await tester.enterText(find.byKey(const Key('reward-price-field')), '10');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Keep me'), findsOneWidget);
    expect(find.textContaining('Storage unavailable'), findsOneWidget);
  });

  testWidgets('reward form shows fields for a new reward', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<RewardProvider>.value(
        value: FakeRewardProvider(const []),
        child: const MaterialApp(home: RewardFormScreen()),
      ),
    );

    expect(find.text('Nova recompensa'), findsOneWidget);
    expect(find.byKey(const Key('reward-name-field')), findsOneWidget);
    expect(find.byKey(const Key('reward-price-field')), findsOneWidget);
  });

  testWidgets('reward template fills new reward form', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<RewardProvider>.value(
        value: FakeRewardProvider(const []),
        child: const MaterialApp(home: RewardFormScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Break'));
    await tester.pumpAndSettle();

    expect(find.text('Short break'), findsOneWidget);
    expect(
      find.text('A guilt-free pause after finishing a quest.'),
      findsOneWidget,
    );
    expect(find.text('15'), findsOneWidget);
  });
}
