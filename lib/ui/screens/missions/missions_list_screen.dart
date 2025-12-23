import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/mission.dart';
import '../../../providers/mission_provider.dart';
import '../../widgets/mission/mission_card_real.dart';

class MissionsListScreen extends StatefulWidget {
  const MissionsListScreen({super.key});

  @override
  State<MissionsListScreen> createState() => _MissionsListScreenState();
}

class _MissionsListScreenState extends State<MissionsListScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missões'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<MissionProvider>().loadMissions();
        },
        child: Consumer<MissionProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final missions = _filtered(provider.missions);

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
                return MissionCardReal(
                  mission: mission,
                  onComplete: mission.id != null
                      ? () => _completeMission(mission)
                      : null,
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMissionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nova Missão'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FilterChip(
              label: 'Todas',
              selected: _filter == 'all',
              onTap: () => setState(() => _filter = 'all'),
            ),
            _FilterChip(
              label: 'Ativas',
              selected: _filter == 'active',
              onTap: () => setState(() => _filter = 'active'),
            ),
            _FilterChip(
              label: 'Completas',
              selected: _filter == 'completed',
              onTap: () => setState(() => _filter = 'completed'),
            ),
            _FilterChip(
              label: 'Arquivadas',
              selected: _filter == 'archived',
              onTap: () => setState(() => _filter = 'archived'),
            ),
          ],
        ),
      ),
    );
  }

  List<Mission> _filtered(List<Mission> missions) {
    switch (_filter) {
      case 'active':
        return missions.where((m) => m.status == 'active').toList();
      case 'completed':
        return missions.where((m) => m.status == 'completed').toList();
      case 'archived':
        return missions.where((m) => m.status == 'archived').toList();
      default:
        return missions;
    }
  }

  Future<void> _completeMission(Mission mission) async {
    await context.read<MissionProvider>().completeMission(mission.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Missão "${mission.title}" concluída!')),
    );
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
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

