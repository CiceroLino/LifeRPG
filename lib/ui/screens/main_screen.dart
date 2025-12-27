import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'missions/missions_list_screen.dart';
import 'missions/mission_editor_screen.dart';
import '../widgets/common/app_drawer.dart';
import '../widgets/player/player_stats_header.dart';
import '../../providers/player_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

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
    _PlaceholderScreen(title: 'Map'),
    _PlaceholderScreen(title: 'Rewards'),
    _PlaceholderScreen(title: 'Inventory'),
    _PlaceholderScreen(title: 'Skills'),
    _PlaceholderScreen(title: 'Statistics'),
    _PlaceholderScreen(title: 'Profile'),
    _PlaceholderScreen(title: 'Shop'),
    _PlaceholderScreen(title: 'Settings'),
    _PlaceholderScreen(title: 'Help'),
  ];

  // Índices que NÃO devem mostrar o header (Settings e Help)
  bool get _shouldShowHeader => _currentIndex != 8 && _currentIndex != 9;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        selectedIndex: _currentIndex,
        onItemSelected: (i) => setState(() => _currentIndex = i),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_titleForIndex(_currentIndex)),
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, playerProvider, _) {
          return Column(
            children: [
              // Player Stats Header (mostra apenas se não for Settings ou Help)
              if (_shouldShowHeader && playerProvider.player != null)
                PlayerStatsHeader(
                  player: playerProvider.player!,
                  title: 'Adventurer', // TODO: Adicionar campo title ao Player model
                  onTabChanged: (index) {
                    // TODO: Implementar filtro de missões baseado na tab selecionada
                    // 0: PLAN, 1: ALL, 2: NEXT, 3: OVERDUE, 4: TODAY
                  },
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
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MissionEditorScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _titleForIndex(int i) {
    const titles = [
      'Missions',
      'Map',
      'Rewards',
      'Inventory',
      'Skills',
      'Statistics',
      'Profile',
      'Shop',
      'Settings',
      'Help',
    ];
    if (i >= 0 && i < titles.length) {
      return titles[i];
    }
    return 'Unknown';
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

