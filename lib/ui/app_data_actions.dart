import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/mission_provider.dart';
import '../providers/notebook_provider.dart';
import '../providers/player_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/reward_provider.dart';
import '../providers/skill_provider.dart';
import '../providers/tavern_provider.dart';
import '../providers/tome_provider.dart';
import '../services/app_data_coordinator.dart';

AppDataCoordinator createAppDataCoordinator(BuildContext context) {
  return appDataCoordinatorFor(
    player: context.read<PlayerProvider>(),
    missions: context.read<MissionProvider>(),
    skills: context.read<SkillProvider>(),
    rewards: context.read<RewardProvider>(),
    inventory: context.read<InventoryProvider>(),
    notebooks: context.read<NotebookProvider>(),
    tomes: context.read<TomeProvider>(),
    tavern: context.read<TavernProvider>(),
    focus: context.read<PomodoroProvider>(),
  );
}

AppDataCoordinator appDataCoordinatorFor({
  required PlayerProvider player,
  required MissionProvider missions,
  required SkillProvider skills,
  required RewardProvider rewards,
  required InventoryProvider inventory,
  required NotebookProvider notebooks,
  required TomeProvider tomes,
  required TavernProvider tavern,
  required PomodoroProvider focus,
}) {
  return AppDataCoordinator(
    quiesce: () async {
      focus.pause();
      await tavern.prepareForDataReplacement();
    },
    afterReplacement: () {
      focus.reset();
      notebooks.clearSelection();
    },
    reload: [
      player.loadPlayer,
      missions.loadMissions,
      skills.loadSkills,
      rewards.loadRewards,
      inventory.loadItems,
      notebooks.loadNotebooks,
      tomes.loadTomes,
      tavern.loadTracks,
    ],
  );
}
