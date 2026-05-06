import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/reward.dart';
import 'package:liferpg/data/repositories/inventory_repository.dart';
import 'package:liferpg/data/repositories/player_repository.dart';
import 'package:liferpg/data/repositories/reward_repository.dart';
import 'package:liferpg/providers/inventory_provider.dart';
import 'package:liferpg/providers/reward_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
  });

  test(
    'purchaseReward reloads rewards and exposes insufficient balance errors',
    () async {
      final rewardId = await RewardRepository().insert(
        Reward(name: 'Game time', priceRp: 50, isUnlimitedStock: true),
      );
      final provider = RewardProvider();

      await provider.loadRewards();
      await provider.purchaseReward(rewardId);

      expect(provider.error, contains('RP insuficiente'));
      expect(provider.rewards.single.name, 'Game time');
      expect((await PlayerRepository().get()).rewardPoints, 0);
    },
  );

  test(
    'purchaseReward reloads changed stock after successful purchase',
    () async {
      await PlayerRepository().addRewardPoints(100);
      final rewardId = await RewardRepository().insert(
        Reward(
          name: 'Pastry',
          priceRp: 25,
          isUnlimitedStock: false,
          stockRemaining: 2,
        ),
      );
      final provider = RewardProvider();

      await provider.loadRewards();
      await provider.purchaseReward(rewardId);

      expect(provider.error, isNull);
      expect(provider.rewards.single.stockRemaining, 1);
    },
  );

  test('consumeItem refreshes inventory after use', () async {
    await PlayerRepository().addRewardPoints(100);
    final rewardId = await RewardRepository().insert(
      Reward(name: 'Cookie', priceRp: 10, isUnlimitedStock: true),
    );
    await RewardRepository().purchaseReward(rewardId);
    final provider = InventoryProvider();

    await provider.loadItems();
    expect(provider.items, hasLength(1));

    await provider.consumeItem(provider.items.single.id!);

    expect(provider.items, isEmpty);
    expect(await InventoryRepository().getAll(), isEmpty);
  });
}
