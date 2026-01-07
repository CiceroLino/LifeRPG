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
import '../../providers/player_provider.dart';

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
    // Garante que o player seja carregado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlayerProvider>().loadPlayer();
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
  bool get _shouldShowHeader => _currentIndex != 4 && _currentIndex != 8 && _currentIndex != 9;

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
        onToggleStats: () => setState(() => _isStatsExpanded = !_isStatsExpanded),
        onToggleShowCompleted: (value) => setState(() => _showCompleted = value),
        onSearch: () {
          // TODO: Implementar busca
        },
        onEdit: () {
          // TODO: Implementar edição de perfil
        },
        onCalendar: () {
          // TODO: Implementar calendário
        },
        onAddMission: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MissionFormScreen(),
            ),
          );
        },
        onSortChanged: (sortValue) {
          // TODO: Implementar ordenação
          debugPrint('Sort changed to: $sortValue');
        },
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
        onSkillsFilter: () {
          // TODO: Implementar filtro de skills
        },
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
                child: IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget? _buildFAB() {
    switch (_currentIndex) {
      case 0:
        return FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MissionFormScreen(),
              ),
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