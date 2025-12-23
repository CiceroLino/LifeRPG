import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/player.dart';
import '../../../providers/mission_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/skill_provider.dart';
import '../../../data/models/mission.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/common/xp_bar.dart';
import '../../widgets/common/level_badge.dart';
import '../../widgets/mission/mission_card_real.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<MissionProvider>().loadMissions();
          await context.read<PlayerProvider>().loadPlayer();
        },
        child: Consumer2<PlayerProvider, MissionProvider>(
          builder: (context, playerProvider, missionProvider, _) {
            if (playerProvider.isLoading || missionProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final player = playerProvider.player;
            final missions = missionProvider.activeMissions;

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Player Card
                if (player != null) _buildPlayerCard(player, playerProvider),
                
                const SizedBox(height: 24),
                
                // Missions Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Missões Ativas (${missions.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Missions List
                if (missions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhuma missão ativa.\nToque em + para criar uma!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...missions.map((mission) => MissionCardReal(
                        mission: mission,
                        onComplete: () => _completeMission(mission),
                      )),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMissionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Missão'),
      ),
    );
  }

  Widget _buildPlayerCard(Player player, PlayerProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            LevelBadge(level: player.level),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  XPBar(
                    currentXP: provider.xpInCurrentLevel,
                    xpNeeded: provider.xpForNextLevel,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${player.totalXP} XP | ${player.rewardPoints} pts',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeMission(Mission mission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Missão?'),
        content: Text('Você ganhará ${mission.xpReward} XP!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Completar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<MissionProvider>().completeMission(mission.id!);
      await context.read<PlayerProvider>().loadPlayer();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 +${mission.xpReward} XP!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showAddMissionDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Missão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;

              final mission = Mission(
                title: titleController.text.trim(),
                description: descController.text.trim(),
                xpReward: 50,
                rewardPoints: 10,
              );

              await context.read<MissionProvider>().addMission(mission);
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Missão criada!')),
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}