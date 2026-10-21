import 'package:liferpg/services/mission_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/models/note.dart';
import 'package:liferpg/data/models/notebook.dart';
import 'package:liferpg/data/models/reward.dart';
import 'package:liferpg/data/models/skill.dart';
import 'package:liferpg/data/models/tome.dart';
import 'package:liferpg/data/repositories/player_repository.dart';
import 'package:liferpg/providers/inventory_provider.dart';
import 'package:liferpg/providers/mission_provider.dart';
import 'package:liferpg/providers/notebook_provider.dart';
import 'package:liferpg/providers/player_provider.dart';
import 'package:liferpg/providers/pomodoro_provider.dart';
import 'package:liferpg/providers/reward_provider.dart';
import 'package:liferpg/providers/settings_provider.dart';
import 'package:liferpg/providers/skill_provider.dart';
import 'package:liferpg/providers/tavern_provider.dart';
import 'package:liferpg/providers/tome_provider.dart';
import 'package:liferpg/services/tavern_audio_service.dart';
import 'package:liferpg/ui/app_data_actions.dart';
import '../support/test_database.dart';

class ResetPlayback extends UnavailableTavernPlayback {
  int stops = 0;
  @override
  Future<Duration?> load(AudioTrack track) async => null;
  @override
  Future<void> play() async {}
  @override
  Future<void> stop() async {
    stops++;
  }
}

class NoReminders implements ReminderBackend {
  @override
  bool get supportsScheduling => false;
  @override
  Future<bool> initialize() async => false;
  @override
  Future<bool> hasPermission() async => false;
  @override
  Future<bool> requestPermissions() async => false;
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> schedule(Mission mission, {required bool soundEnabled}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'reset and restore replace every live cache and stop sessions',
    () async {
      SharedPreferences.setMockInitialValues({});
      final player = PlayerProvider();
      final reminders = MissionReminderService(backend: NoReminders());
      final missions = MissionProvider(reminders: reminders);
      final skills = SkillProvider();
      final rewards = RewardProvider();
      final inventory = InventoryProvider();
      final notebooks = NotebookProvider();
      final tomes = TomeProvider();
      final playback = ResetPlayback();
      final tavern = TavernProvider(playback: playback);
      final focus = PomodoroProvider();
      final settings = SettingsProvider(reminders: reminders);
      final coordinator = appDataCoordinatorFor(
        player: player,
        missions: missions,
        skills: skills,
        rewards: rewards,
        inventory: inventory,
        notebooks: notebooks,
        tomes: tomes,
        tavern: tavern,
        focus: focus,
      );
      await resetTestDatabase();

      await settings.initialize();

      await PlayerRepository().addXP(123);
      await PlayerRepository().addRewardPoints(100);

      await missions.addMission(Mission(title: 'Quest'));

      await skills.addSkill(Skill(name: 'Skill'));
      await rewards.addReward(Reward(name: 'Item', priceRp: 1));
      await rewards.purchaseReward(rewards.rewards.single.id!);
      final notebookId = await notebooks.addNotebook(Notebook(name: 'Journal'));
      await notebooks.addNote(Note(notebookId: notebookId!, title: 'Note'));
      await tomes.addTome(Tome(title: 'PDF', filePath: '/retained.pdf'));
      await tavern.importTrackFromPath('/retained.mp3');
      await tavern.playTrack(tavern.tracks.single);
      await inventory.loadItems();
      expect(inventory.items, isNotEmpty);

      final backup = await DatabaseHelper().getAllDataForBackup();
      focus.start();
      expect(focus.isRunning, isTrue);

      await coordinator.replaceData(settings.factoryReset);
      expect(player.player!.totalXP, 0);
      expect(missions.missions, isEmpty);
      expect(skills.skills, isEmpty);
      expect(rewards.rewards, isEmpty);
      expect(inventory.items, isEmpty);
      expect(notebooks.notebooks, isEmpty);
      expect(notebooks.notes, isEmpty);
      expect(notebooks.selectedNotebookId, isNull);
      expect(tomes.tomes, isEmpty);
      expect(tavern.tracks, isEmpty);
      expect(tavern.activeTrack, isNull);
      expect(focus.isRunning, isFalse);
      expect(playback.stops, greaterThan(0));
      await coordinator.replaceData(() => DatabaseHelper().restoreData(backup));
      expect(player.player!.totalXP, 123);
      expect(missions.missions, hasLength(1));
      expect(skills.skills, hasLength(1));
      expect(rewards.rewards, hasLength(1));
      expect(inventory.items, hasLength(1));
      expect(notebooks.notebooks, hasLength(1));
      expect(tomes.tomes, hasLength(1));
      expect(tavern.tracks, hasLength(1));
      expect(tavern.activeTrack, isNull);

      for (final provider in [
        player,
        missions,
        skills,
        rewards,
        inventory,
        notebooks,
        tomes,
        tavern,
        focus,
        settings,
      ]) {
        provider.dispose();
      }
    },
  );
}
