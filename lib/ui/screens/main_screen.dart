import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'home/home_screen.dart';
import 'missions/missions_list_screen.dart';
import 'missions/mission_form_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    MissionsListScreen(),
    _PlaceholderScreen(title: 'Rewards'),
    _PlaceholderScreen(title: 'Inventory'),
    _PlaceholderScreen(title: 'Skills'),
    _PlaceholderScreen(title: 'Statistics'),
    _PlaceholderScreen(title: 'Profile'),
    _PlaceholderScreen(title: 'Shop'),
    _PlaceholderScreen(title: 'Settings'),
    _PlaceholderScreen(title: 'Help'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _AppDrawer(
        currentIndex: _currentIndex,
        onSelect: (i) => setState(() => _currentIndex = i),
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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MissionFormScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _titleForIndex(int i) {
    const titles = [
      'Dashboard',
      'Missions',
      'Rewards',
      'Inventory',
      'Skills',
      'Statistics',
      'Profile',
      'Shop',
      'Settings',
      'Help',
    ];
    return titles[i];
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _AppDrawer({
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _DrawerItem(
        label: 'Dashboard',
        asset: 'assets/game-icons.net.svg/icons/ffffff/000000/1x1/lorc/compass.svg',
      ),
      _DrawerItem(
        label: 'Missions',
        asset: 'assets/game-icons.net.svg/icons/ffffff/000000/1x1/lorc/archery-target.svg',
      ),
      _DrawerItem(
        label: 'Rewards',
        asset: 'assets/game-icons.net.svg/icons/ffffff/000000/1x1/delapouite/present.svg',
      ),
      _DrawerItem(
        label: 'Inventory',
        asset: 'assets/game-icons.net.svg/icons/ffffff/000000/1x1/delapouite/chest.svg',
      ),
      _DrawerItem(
        label: 'Skills',
        asset: 'assets/game-icons.net.svg/icons/ffffff/000000/1x1/delapouite/skills.svg',
      ),
      _DrawerItem(
        label: 'Statistics',
        asset: 'assets/game-icons.net.svg/icons/ffffff/000000/1x1/delapouite/chart.svg',
      ),
      _DrawerItem(
        label: 'Profile',
        asset: 'assets/game-icons.net.svg/icons/ffffff/000000/1x1/darkzaitzev/hooded-figure.svg',
      ),
      _DrawerItem(
        label: 'Shop',
        asset: 'assets/game-icons.net.svg/icons/ffffff/000000/1x1/delapouite/shop.svg',
      ),
      _DrawerItem(
        label: 'Settings',
        asset: 'assets/game-icons.net.svg/icons/ffffff/000000/1x1/delapouite/gear-hammer.svg',
      ),
      _DrawerItem(
        label: 'Help',
        asset: 'assets/game-icons.net.svg/icons/ffffff/000000/1x1/delapouite/info.svg',
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = currentIndex == index;
            return ListTile(
              leading: SvgPicture.asset(
                item.asset,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              title: Text(item.label),
              selected: selected,
              onTap: () {
                Navigator.pop(context);
                onSelect(index);
              },
            );
          },
        ),
      ),
    );
  }
}

class _DrawerItem {
  final String label;
  final String asset;

  _DrawerItem({required this.label, required this.asset});
}

