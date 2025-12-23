import 'package:flutter/material.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/xp_bar.dart';
import '../../widgets/common/level_badge.dart';
import '../../widgets/mission/mission_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final playerData = MockData.playerData;
    final missions = MockData.missions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navegar para settings
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Player Info Card
          _buildPlayerCard(playerData),
          
          const SizedBox(height: 24),
          
          // Missions Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Missões Ativas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Ver todas
                  },
                  child: const Text('Ver todas'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Missions List
          ...missions.map((mission) => MissionCard(
                mission: mission,
                onTap: () {
                  _showMissionDetails(mission);
                },
                onComplete: () {
                  _completeMission(mission);
                },
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddMissionDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Missão'),
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> playerData) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Level Badge
            LevelBadge(level: playerData['level']),
            
            const SizedBox(width: 16),
            
            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerData['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  XPBar(
                    currentXP: playerData['currentXP'],
                    xpNeeded: playerData['xpForNextLevel'],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${playerData['totalXP']} XP',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMissionDetails(MockMission mission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Título
            Text(
              mission.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Descrição
            Text(
              mission.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Info
            _buildInfoRow('XP Reward', '${mission.xpReward} XP'),
            _buildInfoRow('Dificuldade', '${mission.difficulty}/5'),
            _buildInfoRow('Urgência', '${mission.urgency}/5'),
            
            const SizedBox(height: 24),
            
            // Skills
            const Text(
              'Skills',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: mission.skills
                  .map((skill) => Chip(label: Text(skill)))
                  .toList(),
            ),
            
            const Spacer(),
            
            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _completeMission(mission);
                    },
                    child: const Text('Completar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _completeMission(MockMission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Missão Completada!'),
        content: Text('Você ganhou ${mission.xpReward} XP!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddMissionDialog() {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Missão'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Título da missão',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Adicionar missão
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Missão adicionada! (mock)')),
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}