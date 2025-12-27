import 'package:flutter/foundation.dart';
import '../data/models/mission.dart';
import '../data/repositories/mission_repository.dart';
import '../data/repositories/skill_repository.dart';
import '../data/repositories/player_repository.dart';

class MissionProvider extends ChangeNotifier {
  final MissionRepository _missionRepo = MissionRepository();
  final SkillRepository _skillRepo = SkillRepository();
  final PlayerRepository _playerRepo = PlayerRepository();

  List<Mission> _missions = [];
  bool _isLoading = false;
  String? _error;

  List<Mission> get missions => _missions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Mission> get activeMissions =>
      _missions.where((m) => m.status == 'active').toList();

  List<Mission> get completedMissions =>
      _missions.where((m) => m.status == 'completed').toList();

  Future<void> loadMissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _missions = await _missionRepo.getAll();
    } catch (e) {
      _error = 'Erro ao carregar missões: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMission(Mission mission) async {
    try {
      final id = await _missionRepo.insert(mission);
      
      // Link skills if any
      if (mission.skillIds.isNotEmpty) {
        await _missionRepo.linkSkills(id, mission.skillIds);
      }
      
      await loadMissions();
    } catch (e) {
      _error = 'Erro ao adicionar missão: $e';
      notifyListeners();
    }
  }

  Future<void> completeMission(int id) async {
    try {
      final mission = await _missionRepo.getWithSkills(id);
      
      await _missionRepo.complete(id);
      
      await _playerRepo.addXP(mission.xpReward);
      
      await _playerRepo.addRewardPoints(mission.rewardPoints);
      
      if (mission.skillIds.isNotEmpty) {
        final xpPerSkill = (mission.xpReward / mission.skillIds.length).round();
        for (final skillId in mission.skillIds) {
          await _skillRepo.addXP(skillId, xpPerSkill);
        }
      }
      
      await loadMissions();
    } catch (e) {
      _error = 'Erro ao completar missão: $e';
      notifyListeners();
    }
  }

  Future<void> updateMission(Mission mission) async {
    try {
      await _missionRepo.update(mission);
      
      if (mission.skillIds.isNotEmpty) {
        await _missionRepo.linkSkills(mission.id!, mission.skillIds);
      }
      
      await loadMissions();
    } catch (e) {
      _error = 'Erro ao atualizar missão: $e';
      notifyListeners();
    }
  }

  Future<void> deleteMission(int id) async {
    try {
      await _missionRepo.delete(id);
      await loadMissions();
    } catch (e) {
      _error = 'Erro ao deletar missão: $e';
      notifyListeners();
    }
  }
}