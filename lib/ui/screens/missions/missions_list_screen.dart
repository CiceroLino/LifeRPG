import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/mission.dart';
import '../../../providers/mission_provider.dart';
import 'mission_editor_screen.dart';
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
          final missions = provider.missions;

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
              return MissionCard(
                mission: mission,
                isExpanded:
                    mission.id != null && _expandedMissionId == mission.id,
                onToggleExpanded: () => _toggleMission(mission.id),
                onStatusChanged: (status) =>
                    _updateMissionStatus(mission, status),
                onEdit: () => _editMission(mission),
                onAddSubtask: () {},
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
    await context.read<MissionProvider>().updateMissionStatus(
      mission.id!,
      status,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status de "${mission.title}" atualizado para $status.'),
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
}
