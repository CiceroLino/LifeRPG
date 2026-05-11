import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/daily_time_budget_advisor.dart';
import '../../../data/models/mission.dart';
import '../../../providers/mission_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/skill_provider.dart';
import '../../widgets/common/game_snack_bar.dart';
import 'mission_editor_screen.dart';
import 'mission_form_screen.dart';
import '../../widgets/mission/mission_card.dart';

class MissionsListScreen extends StatefulWidget {
  const MissionsListScreen({super.key});

  @override
  State<MissionsListScreen> createState() => _MissionsListScreenState();
}

class _MissionsListScreenState extends State<MissionsListScreen> {
  int? _expandedMissionId;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<MissionProvider>().loadMissions();
      },
      child: Consumer<MissionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final missions = provider.filteredMissions;

          if (missions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhuma missão encontrada.\nUse o botão + para criar.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];
              final children = provider.missions
                  .where((child) => child.parentMissionId == mission.id)
                  .toList();
              final completedChildren = children
                  .where((child) => child.status == 'completed')
                  .length;
              final progress = children.isEmpty
                  ? 0.0
                  : completedChildren / children.length;
              final timeWarning = _timeWarningForMission(
                mission,
                provider.missions,
              );
              return MissionCard(
                mission: mission,
                isExpanded:
                    mission.id != null && _expandedMissionId == mission.id,
                progress: progress,
                timeWarning: timeWarning,
                onToggleExpanded: () => _toggleMission(mission.id),
                onStatusChanged: (status) =>
                    _updateMissionStatus(mission, status),
                onEdit: () => _editMission(mission),
                onAddSubtask: () => _addSubtask(mission),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleMission(int? missionId) {
    if (missionId == null) return;
    setState(() {
      _expandedMissionId = _expandedMissionId == missionId ? null : missionId;
    });
  }

  Future<void> _updateMissionStatus(Mission mission, String status) async {
    if (mission.id == null) return;
    final missionProvider = context.read<MissionProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final skillProvider = context.read<SkillProvider>();

    await missionProvider.updateMissionStatus(mission.id!, status);
    if (status == 'completed') {
      await Future.wait([
        playerProvider.loadPlayer(),
        skillProvider.loadSkills(),
      ]);
    }
    if (!mounted) return;
    GameSnackBar.show(
      context,
      message: 'Status de "${mission.title}" atualizado para $status.',
      type: status == 'completed'
          ? GameSnackBarType.reward
          : GameSnackBarType.info,
      title: status == 'completed' ? 'Missão Completa' : 'Registro Atualizado',
    );
  }

  Future<void> _addSubtask(Mission mission) async {
    if (mission.id == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MissionFormScreen(initialParentMissionId: mission.id),
      ),
    );
  }

  Future<void> _editMission(Mission mission) async {
    final updated = await Navigator.of(context).push<Mission>(
      MaterialPageRoute(builder: (_) => MissionEditorScreen(initial: mission)),
    );

    if (!mounted || updated == null) return;
    await context.read<MissionProvider>().updateMission(updated);
  }

  String? _timeWarningForMission(Mission mission, List<Mission> allMissions) {
    if (!_isDueToday(mission) || (mission.estimatedDuration ?? 0) <= 0) {
      return null;
    }
    final player = context.read<PlayerProvider>().player;
    if (player == null || player.energyMode != 'auto') return null;
    final result = DailyTimeBudgetAdvisor.assess(
      now: DateTime.now(),
      wakeUpTime: player.wakeUpTime,
      sleepTime: player.sleepTime,
      missions: allMissions,
    );
    return result.exceedsAvailableTime ? result.message : null;
  }

  bool _isDueToday(Mission mission) {
    final dueDate = mission.dueDate;
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }
}
