import 'package:flutter/foundation.dart';
import '../data/models/mission.dart';
import '../data/repositories/mission_repository.dart';
import '../data/repositories/skill_repository.dart';
import '../data/repositories/player_repository.dart';

enum MissionSortMode {
  recent,
  oldest,
  difficultyDesc,
  priorityDesc,
  rewardDesc,
}

class MissionProvider extends ChangeNotifier {
  final MissionRepository _missionRepo = MissionRepository();
  final SkillRepository _skillRepo = SkillRepository();
  final PlayerRepository _playerRepo = PlayerRepository();

  List<Mission> _missions = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Set<int> _selectedSkillIds = {};
  MissionSortMode _sortMode = MissionSortMode.recent;

  List<Mission> get missions => _missions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  Set<int> get selectedSkillIds => _selectedSkillIds;
  MissionSortMode get sortMode => _sortMode;

  List<Mission> get activeMissions =>
      _missions.where((m) => m.status == 'active').toList();

  List<Mission> get completedMissions =>
      _missions.where((m) => m.status == 'completed').toList();

  List<Mission> get filteredMissions {
    Iterable<Mission> items = _missions;

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((mission) {
        final title = mission.title.toLowerCase();
        final description = mission.description.toLowerCase();
        return title.contains(query) || description.contains(query);
      });
    }

    if (_selectedSkillIds.isNotEmpty) {
      items = items.where(
        (mission) =>
            mission.skillIds.any((id) => _selectedSkillIds.contains(id)),
      );
    }

    final sorted = items.toList();
    sorted.sort((a, b) {
      switch (_sortMode) {
        case MissionSortMode.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case MissionSortMode.difficultyDesc:
          return b.difficulty.compareTo(a.difficulty);
        case MissionSortMode.priorityDesc:
          final pa = (a.urgency * 100) + (a.fear * 10) + a.difficulty;
          final pb = (b.urgency * 100) + (b.fear * 10) + b.difficulty;
          return pb.compareTo(pa);
        case MissionSortMode.rewardDesc:
          return b.rewardPoints.compareTo(a.rewardPoints);
        case MissionSortMode.recent:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return sorted;
  }

  void setSearchQuery(String query) {
    final normalized = query.trim();
    if (_searchQuery == normalized) return;
    _searchQuery = normalized;
    notifyListeners();
  }

  void setSortMode(MissionSortMode mode) {
    if (_sortMode == mode) return;
    _sortMode = mode;
    notifyListeners();
  }

  void toggleSkillFilter(int skillId) {
    final next = {..._selectedSkillIds};
    if (next.contains(skillId)) {
      next.remove(skillId);
    } else {
      next.add(skillId);
    }
    _selectedSkillIds = next;
    notifyListeners();
  }

  void setSkillFilters(Set<int> skillIds) {
    _selectedSkillIds = {...skillIds};
    notifyListeners();
  }

  void clearSkillFilters() {
    if (_selectedSkillIds.isEmpty) return;
    _selectedSkillIds = {};
    notifyListeners();
  }

  @visibleForTesting
  void setMissionsForTesting(List<Mission> missions) {
    _missions = missions;
  }

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

  Future<void> updateMissionStatus(int id, String status) async {
    try {
      final mission = await _missionRepo.getWithSkills(id);
      if (mission.status == status) {
        return;
      }

      if (status == 'completed') {
        await completeMission(id);
        return;
      }

      final updated = mission.copyWith(
        status: status,
        completedAt: status == 'completed' ? DateTime.now() : null,
      );
      await _missionRepo.update(updated);
      await loadMissions();
    } catch (e) {
      _error = 'Erro ao atualizar status da missão: $e';
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
