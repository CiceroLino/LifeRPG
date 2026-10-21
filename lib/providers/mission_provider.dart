import '../data/database/data_operations.dart';
import 'package:flutter/foundation.dart';
import '../data/models/mission.dart';
import '../data/models/mission_reward_drop.dart';
import '../data/repositories/mission_repository.dart';
import '../data/repositories/mission_reward_drop_repository.dart';
import '../services/mission_completion_service.dart';
import '../services/mission_reminder_service.dart';

enum MissionSortMode {
  recent,
  oldest,
  difficultyDesc,
  priorityDesc,
  rewardDesc,
}

enum MissionFilterMode { plan, all, next, overdue, today, tomorrow }

class MissionProvider extends ChangeNotifier {
  final MissionRepository _missionRepo;
  final MissionRewardDropRepository _dropRepo;
  final MissionCompletionService _completionService;
  final MissionReminderService _reminders;
  String? _warning;
  String? get warning => _warning;

  MissionProvider({
    MissionRepository? repository,
    MissionRewardDropRepository? drops,
    MissionCompletionService? completionService,
    MissionReminderService? reminders,
  }) : _missionRepo = repository ?? MissionRepository(),
       _dropRepo = drops ?? MissionRewardDropRepository(),
       _completionService = completionService ?? MissionCompletionService(),
       _reminders = reminders ?? MissionReminderService.instance;

  List<Mission> _missions = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Set<int> _selectedSkillIds = {};
  MissionSortMode _sortMode = MissionSortMode.recent;
  MissionFilterMode _filterMode = MissionFilterMode.all;
  bool _showCompleted = false;
  MissionCompletionResult? _lastCompletionResult;

  List<Mission> get missions => _missions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  Set<int> get selectedSkillIds => _selectedSkillIds;
  MissionSortMode get sortMode => _sortMode;
  MissionFilterMode get filterMode => _filterMode;
  bool get showCompleted => _showCompleted;
  MissionCompletionResult? get lastCompletionResult => _lastCompletionResult;

  List<Mission> get activeMissions =>
      _missions.where((m) => m.status == 'active').toList();

  List<Mission> get completedMissions =>
      _missions.where((m) => m.status == 'completed').toList();

  List<Mission> get filteredMissions {
    Iterable<Mission> items = _missions;

    items = _applyFilterMode(items);

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

  Iterable<Mission> _applyFilterMode(Iterable<Mission> items) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final dayAfterTomorrowStart = tomorrowStart.add(const Duration(days: 1));

    switch (_filterMode) {
      case MissionFilterMode.plan:
        return items.where((mission) {
          if (_isHiddenCompleted(mission)) return false;
          return mission.status == 'active' && mission.dueDate == null;
        });
      case MissionFilterMode.all:
        return items.where((mission) => !_isHiddenCompleted(mission));
      case MissionFilterMode.next:
        return items.where((mission) {
          if (_isHiddenCompleted(mission)) return false;
          final dueDate = mission.dueDate;
          return mission.status == 'active' &&
              dueDate != null &&
              !dueDate.isBefore(now);
        });
      case MissionFilterMode.today:
        return items.where((mission) {
          if (_isHiddenCompleted(mission) || mission.status != 'active') {
            return false;
          }
          final dueDate = mission.dueDate;
          return dueDate != null &&
              !dueDate.isBefore(todayStart) &&
              dueDate.isBefore(tomorrowStart);
        });
      case MissionFilterMode.tomorrow:
        return items.where((mission) {
          if (_isHiddenCompleted(mission) || mission.status != 'active') {
            return false;
          }
          final dueDate = mission.dueDate;
          return dueDate != null &&
              !dueDate.isBefore(tomorrowStart) &&
              dueDate.isBefore(dayAfterTomorrowStart);
        });
      case MissionFilterMode.overdue:
        return items.where((mission) {
          if (_isHiddenCompleted(mission) || mission.status != 'active') {
            return false;
          }
          final dueDate = mission.dueDate;
          return dueDate != null && dueDate.isBefore(todayStart);
        });
    }
  }

  bool _isHiddenCompleted(Mission mission) {
    return !_showCompleted && mission.status == 'completed';
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

  void setFilterMode(MissionFilterMode mode) {
    if (_filterMode == mode) return;
    _filterMode = mode;
    notifyListeners();
  }

  void setShowCompleted(bool value) {
    if (_showCompleted == value) return;
    _showCompleted = value;
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

  Future<void> loadMissions() => DataOperations.instance.run(() async {
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
  }, readOnly: true);

  Future<int?> addMission(
    Mission mission, {
    bool notificationsEnabled = true,
    List<MissionRewardDrop> rewardDrops = const [],
  }) => DataOperations.instance.run(() async {
    try {
      final id = await _missionRepo.insert(mission);
      if (mission.skillIds.isNotEmpty) {
        await _missionRepo.linkSkills(id, mission.skillIds);
      }
      if (rewardDrops.isNotEmpty) {
        await _dropRepo.replaceForMission(
          id,
          rewardDrops.map((drop) => drop.copyWith(missionId: id)).toList(),
        );
      }
      await _reminders.scheduleForMission(
        mission.copyWith(id: id),
        notificationsEnabled: notificationsEnabled,
      );
      _warning = _reminders.lastWarning;
      await loadMissions();
      return id;
    } catch (e) {
      _error = 'Erro ao adicionar missão: $e';
      notifyListeners();
      return null;
    }
  }, readOnly: false);

  Future<void> completeMission(int id) => DataOperations.instance.run(() async {
    try {
      _lastCompletionResult = await _completionService.completeMission(id);
      final mission = _lastCompletionResult?.mission;
      if (mission != null && mission.status == 'completed') {
        await _reminders.cancelForMission(id);
      } else if (mission != null) {
        await _reminders.scheduleForMission(
          mission,
          notificationsEnabled: true,
        );
      }
      _warning = _reminders.lastWarning;
      await loadMissions();
    } catch (e) {
      _error = 'Erro ao completar missão: $e';
      notifyListeners();
    }
  }, readOnly: false);

  Future<void> updateMissionStatus(int id, String status) =>
      DataOperations.instance.run(() async {
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
          await _reminders.scheduleForMission(updated);
          _warning = _reminders.lastWarning;
          await loadMissions();
        } catch (e) {
          _error = 'Erro ao atualizar status da missão: $e';
          notifyListeners();
        }
      }, readOnly: false);

  Future<void> updateMission(
    Mission mission, {
    bool notificationsEnabled = true,
    List<MissionRewardDrop>? rewardDrops,
  }) => DataOperations.instance.run(() async {
    try {
      await _missionRepo.update(mission);
      await _missionRepo.linkSkills(mission.id!, mission.skillIds);
      if (rewardDrops != null) {
        await _dropRepo.replaceForMission(
          mission.id!,
          rewardDrops
              .map((drop) => drop.copyWith(missionId: mission.id!))
              .toList(),
        );
      }
      await _reminders.scheduleForMission(
        mission,
        notificationsEnabled: notificationsEnabled,
      );
      _warning = _reminders.lastWarning;
      await loadMissions();
    } catch (e) {
      _error = 'Erro ao atualizar missão: $e';
      notifyListeners();
    }
  }, readOnly: false);

  Future<void> deleteMission(int id) => DataOperations.instance.run(() async {
    try {
      await _missionRepo.delete(id);
      await _reminders.reconcile(await _missionRepo.getAll());
      _warning = _reminders.lastWarning;
      await loadMissions();
    } catch (e) {
      _error = 'Erro ao deletar missão: $e';
      notifyListeners();
    }
  }, readOnly: false);

  Future<void> clearCompletedMissions() =>
      DataOperations.instance.run(() async {
        try {
          final completed = await _missionRepo.getByStatus('completed');
          for (final mission in completed) {
            if (mission.id != null) {
              await _missionRepo.delete(mission.id!);
            }
          }
          _warning = _reminders.lastWarning;
          await loadMissions();
        } catch (e) {
          _error = 'Erro ao limpar histórico: $e';
          notifyListeners();
        }
      }, readOnly: false);
}
