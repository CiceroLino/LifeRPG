import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/reward.dart';
import 'package:liferpg/data/repositories/inventory_repository.dart';
import 'package:liferpg/data/repositories/player_repository.dart';
import 'package:liferpg/data/repositories/reward_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RewardRepository rewards;
  late InventoryRepository inventory;
  late PlayerRepository players;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    rewards = RewardRepository();
    inventory = InventoryRepository();
    players = PlayerRepository();
  });

  test('creates, updates, lists, and archives rewards', () async {
    final id = await rewards.insert(
      Reward(
        name: 'Coffee',
        description: 'Buy a coffee',
        priceRp: 25,
        isUnlimitedStock: false,
        stockRemaining: 3,
        icon: 'local_cafe',
      ),
    );

    var stored = await rewards.getById(id);
    expect(stored!.name, 'Coffee');
    expect(stored.priceRp, 25);
    expect(stored.stockRemaining, 3);

    await rewards.update(stored.copyWith(name: 'Better coffee', priceRp: 30));
    stored = await rewards.getById(id);
    expect(stored!.name, 'Better coffee');
    expect(stored.priceRp, 30);

    expect(await rewards.getActive(), hasLength(1));
    await rewards.archive(id);
    expect(await rewards.getActive(), isEmpty);
    expect((await rewards.getById(id))!.isActive, isFalse);
  });

  test(
    'purchase debits RP, decrements finite stock, creates inventory and history',
    () async {
      await players.addRewardPoints(100);
      final rewardId = await rewards.insert(
        Reward(
          name: 'Movie night',
          description: 'Rent a movie',
          priceRp: 40,
          isUnlimitedStock: false,
          stockRemaining: 2,
          icon: 'movie',
        ),
      );

      final result = await rewards.purchaseReward(rewardId);

      expect(result.rewardId, rewardId);
      expect((await players.get()).rewardPoints, 60);
      expect((await rewards.getById(rewardId))!.stockRemaining, 1);

      final items = await inventory.getAll();
      expect(items, hasLength(1));
      expect(items.single.rewardId, rewardId);
      expect(items.single.name, 'Movie night');
      expect(items.single.quantity, 1);

      final history = await rewards.getRedemptions();
      expect(history, hasLength(1));
      expect(history.single.rewardNameSnapshot, 'Movie night');
      expect(history.single.pricePaidRp, 40);
      expect(history.single.inventoryItemId, items.single.id);
    },
  );

  test('purchase of unlimited reward does not decrement stock', () async {
    await players.addRewardPoints(100);
    final rewardId = await rewards.insert(
      Reward(name: 'Walk break', priceRp: 10, isUnlimitedStock: true),
    );

    await rewards.purchaseReward(rewardId);
    await rewards.purchaseReward(rewardId);

    final reward = await rewards.getById(rewardId);
    expect(reward!.isUnlimitedStock, isTrue);
    expect(reward.stockRemaining, isNull);
    expect((await players.get()).rewardPoints, 80);
    expect((await inventory.getAll()).single.quantity, 2);
  });

  test('purchase without enough RP has no partial effects', () async {
    final rewardId = await rewards.insert(
      Reward(
        name: 'Dinner',
        priceRp: 50,
        isUnlimitedStock: false,
        stockRemaining: 1,
      ),
    );

    expect(
      () => rewards.purchaseReward(rewardId),
      throwsA(isA<InsufficientRewardPointsException>()),
    );

    expect((await players.get()).rewardPoints, 0);
    expect((await rewards.getById(rewardId))!.stockRemaining, 1);
    expect(await inventory.getAll(), isEmpty);
    expect(await rewards.getRedemptions(), isEmpty);
  });

  test('purchase without stock has no partial effects', () async {
    await players.addRewardPoints(100);
    final rewardId = await rewards.insert(
      Reward(
        name: 'Snack',
        priceRp: 20,
        isUnlimitedStock: false,
        stockRemaining: 0,
      ),
    );

    expect(
      () => rewards.purchaseReward(rewardId),
      throwsA(isA<RewardOutOfStockException>()),
    );

    expect((await players.get()).rewardPoints, 100);
    expect(await inventory.getAll(), isEmpty);
    expect(await rewards.getRedemptions(), isEmpty);
  });

  test(
    'consuming inventory decrements quantity and removes empty item',
    () async {
      await players.addRewardPoints(100);
      final rewardId = await rewards.insert(
        Reward(name: 'Tea', priceRp: 10, isUnlimitedStock: true),
      );
      await rewards.purchaseReward(rewardId);
      await rewards.purchaseReward(rewardId);

      var item = (await inventory.getAll()).single;
      await inventory.consumeItem(item.id!);
      item = (await inventory.getAll()).single;
      expect(item.quantity, 1);

      await inventory.consumeItem(item.id!);
      expect(await inventory.getAll(), isEmpty);
    },
  );

  test(
    'backup and restore preserve rewards, inventory, and redemptions',
    () async {
      await players.addRewardPoints(100);
      final rewardId = await rewards.insert(
        Reward(name: 'Book time', priceRp: 15, isUnlimitedStock: true),
      );
      await rewards.purchaseReward(rewardId);

      final backup = await DatabaseHelper().getAllDataForBackup();
      expect(backup['rewards'], hasLength(1));
      expect(backup['inventory_items'], hasLength(1));
      expect(backup['reward_redemptions'], hasLength(1));

      await DatabaseHelper().restoreData(backup);

      expect(await rewards.getActive(), hasLength(1));
      expect((await inventory.getAll()).single.name, 'Book time');
      expect(
        (await rewards.getRedemptions()).single.rewardNameSnapshot,
        'Book time',
      );
    },
  );
}
