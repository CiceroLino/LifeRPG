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
  final player = context.read<PlayerProvider>();
  final missions = context.read<MissionProvider>();
  final skills = context.read<SkillProvider>();
  final rewards = context.read<RewardProvider>();
  final inventory = context.read<InventoryProvider>();
  final notebooks = context.read<NotebookProvider>();
  final tomes = context.read<TomeProvider>();
  final tavern = context.read<TavernProvider>();
  final focus = context.read<PomodoroProvider>();
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
