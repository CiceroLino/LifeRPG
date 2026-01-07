import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/mission.dart';
import '../../../providers/mission_provider.dart';
import '../../widgets/mission/mission_card.dart';

class MissionsListScreen extends StatelessWidget {
  const MissionsListScreen({super.key});

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
                onTap: () {
                  if (mission.id != null) {
                    _completeMission(context, mission);
                  }
                },
                onAddSubtask: () {},
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _completeMission(BuildContext context, Mission mission) async {
    await context.read<MissionProvider>().completeMission(mission.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Missão "${mission.title}" concluída!')),
    );
  }
}
