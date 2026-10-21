import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/models/reward.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';
import 'package:liferpg/data/repositories/player_repository.dart';
import 'package:liferpg/data/repositories/reward_repository.dart';
import 'package:liferpg/providers/player_provider.dart';
import 'package:liferpg/services/focus_session_service.dart';
import 'package:liferpg/services/mission_completion_service.dart';
import '../../support/test_database.dart';

void main() {
  setUp(resetTestDatabase);

  test('concurrent XP increments are both applied', () async {
    final players = PlayerRepository();
    await Future.wait([players.addXP(25), players.addXP(25)]);
    expect((await players.get()).totalXP, 50);
  });

  test('focus and mission preserve every XP and RP reward', () async {
    final id = await MissionRepository().insert(
      Mission(title: 'Concurrent quest', xpReward: 100, rewardPoints: 25),
    );
    await Future.wait([
      FocusSessionService().completeSession(
        plannedMinutes: 25,
        completedMinutes: 25,
      ),
      MissionCompletionService().completeMission(id),
    ]);
    final player = await PlayerRepository().get();
    expect(player.totalXP, 125);
    expect(player.rewardPoints, 25);
    expect(player.level, 2);
  });

  test('stale energy and profile edits cannot overwrite balances', () async {
    final players = PlayerRepository();
    final provider = PlayerProvider();
    await provider.loadPlayer();
    final stale = provider.player!;
    await players.addXP(25);
    await players.addRewardPoints(40);
    await provider.setManualEnergy(50);
    await provider.updatePlayer(stale.copyWith(name: 'Changed name'));
    final player = await players.get();
    expect(player.totalXP, 25);
    expect(player.rewardPoints, 40);
    expect(player.currentEnergy, 50);
    expect(player.name, 'Changed name');
    provider.dispose();
  });

  test('profile edits preserve the debit of a concurrent purchase', () async {
    final players = PlayerRepository();
    await players.addRewardPoints(100);
    final provider = PlayerProvider();
    await provider.loadPlayer();
    final reward = await RewardRepository().insert(
      Reward(name: 'Tea', priceRp: 30),
    );
    await Future.wait([
      RewardRepository().purchaseReward(reward),
      provider.updatePlayer(provider.player!.copyWith(title: 'Mage')),
    ]);
    final player = await players.get();
    expect(player.rewardPoints, 70);
    expect(player.title, 'Mage');
    provider.dispose();
  });
}
