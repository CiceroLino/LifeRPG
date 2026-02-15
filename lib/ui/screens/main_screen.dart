import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'missions/missions_list_screen.dart';
import 'missions/mission_form_screen.dart';
import 'map/map_screen.dart';
import 'rewards/rewards_screen.dart';
import 'inventory/inventory_screen.dart';
import 'skills/skills_view.dart';
import 'statistics/statistics_screen.dart';
import 'profile/profile_screen.dart';
import 'shop/shop_screen.dart';
import 'settings/settings_screen.dart';
import 'help/help_screen.dart';
import '../widgets/common/app_drawer.dart';
import '../widgets/common/liferpg_app_bar.dart';
import '../widgets/player/player_stats_header.dart';
import '../../providers/mission_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/skill_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isStatsExpanded = true;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlayerProvider>().loadPlayer();
        context.read<SkillProvider>().loadSkills();
      }
    });
  }

  final _pages = const [
    MissionsListScreen(),
    MapScreen(),
    RewardsScreen(),
    InventoryScreen(),
    SkillsView(),
    StatisticsScreen(),
    ProfileScreen(),
    ShopScreen(),
    SettingsScreen(),
    HelpScreen(),
  ];

  // Índices que NÃO devem mostrar o header (Skills, Settings e Help)
  bool get _shouldShowHeader =>
      _currentIndex != 4 && _currentIndex != 8 && _currentIndex != 9;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        selectedIndex: _currentIndex,
        onItemSelected: (i) => setState(() => _currentIndex = i),
      ),
      appBar: LifeRPGAppBar(
        currentScreen: _getCurrentScreenName(_currentIndex),
        isStatsExpanded: _isStatsExpanded,
        showCompleted: _showCompleted,
        onToggleStats: () =>
            setState(() => _isStatsExpanded = !_isStatsExpanded),
        onToggleShowCompleted: (value) =>
            setState(() => _showCompleted = value),
        onSearch: _showMissionSearchDialog,
        onEdit: () {
          // TODO: Implementar edição de perfil
        },
        onCalendar: () {
          // TODO: Implementar calendário
        },
        onAddMission: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const MissionFormScreen()));
        },
        onSortChanged: (sortValue) => _applySort(sortValue),
        onWorkspaceChanged: (workspace) {
          // TODO: Implementar troca de workspace
          debugPrint('Workspace changed to:      $workspace');
        },
        onResetAvatar: () {
          // TODO: Implementar reset de avatar
        },
        onShareProfile: () {
          // TODO: Implementar compartilhamento de perfil
        },
        onExportData: () {
          // TODO: Implementar exportação de dados
        },
        onClearHistory: () {
          // TODO: Implementar limpeza de histórico
        },
        onSkillsFilter: _openSkillsFilterSheet,
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, playerProvider, _) {
          return Column(
            children: [
              // Player Stats Header (mostra apenas se não for Settings ou Help e se estiver expandido)
              if (_shouldShowHeader &&
                  _isStatsExpanded &&
                  playerProvider.player != null)
                PlayerStatsHeader(
                  player: playerProvider.player!,
                  showTabs: _currentIndex == 0,
                  onTabChanged: (index) {},
                ),
              // Conteúdo da tela
              Expanded(
                child: IndexedStack(index: _currentIndex, children: _pages),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Future<void> _showMissionSearchDialog() async {
    final controller = TextEditingController(
      text: context.read<MissionProvider>().searchQuery,
    );
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buscar missões'),
        content: TextField(
          key: const Key('mission-search-field'),
          controller: controller,
          decoration: const InputDecoration(hintText: 'Título ou descrição'),
          autofocus: true,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (!mounted || query == null) return;
    context.read<MissionProvider>().setSearchQuery(query);
  }

  void _applySort(String sortValue) {
    MissionSortMode mode = MissionSortMode.recent;
    switch (sortValue) {
      case 'difficulty':
        mode = MissionSortMode.difficultyDesc;
        break;
      case 'importance':
        mode = MissionSortMode.priorityDesc;
        break;
      case 'reward':
        mode = MissionSortMode.rewardDesc;
        break;
      case 'date':
      default:
        mode = MissionSortMode.recent;
        break;
    }

    context.read<MissionProvider>().setSortMode(mode);
  }

  Future<void> _openSkillsFilterSheet() async {
    final skillProvider = context.read<SkillProvider>();
    final missionProvider = context.read<MissionProvider>();
    final selected = {...missionProvider.selectedSkillIds};

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final skills = skillProvider.skills;
        if (skills.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhuma skill disponível para filtrar.'),
          );
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar por skills',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((skill) {
                      return FilterChip(
                        label: Text(skill.name),
                        selected: selected.contains(skill.id),
                        onSelected: (enabled) {
                          if (skill.id == null) return;
                          setState(() {
                            if (enabled) {
                              selected.add(skill.id!);
                            } else {
                              selected.remove(skill.id!);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          selected.clear();
                          setState(() {});
                        },
                        child: const Text('Limpar'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          missionProvider.setSkillFilters(selected);
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget? _buildFAB() {
    switch (_currentIndex) {
      case 0:
        return FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MissionFormScreen()),
            );
          },
          child: const Icon(Icons.add),
        );
      case 2:
        return FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        );
      case 3:
        return FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        );
      case 4:
        return FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  /// Retorna o nome da tela atual baseado no índice
  String _getCurrentScreenName(int index) {
    const screenNames = [
      'missions',
      'map',
      'rewards',
      'inventory',
      'skills',
      'statistics',
      'profile',
      'shop',
      'settings',
      'help',
    ];
    if (index >= 0 && index < screenNames.length) {
      return screenNames[index];
    }
    return 'missions'; // Default
  }
}
