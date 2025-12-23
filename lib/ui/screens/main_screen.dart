import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'missions/missions_list_screen.dart';

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
    _PlaceholderScreen(title: 'Skills (em breve)'),
    _PlaceholderScreen(title: 'Rewards (em breve)'),
    _PlaceholderScreen(title: 'Profile/Stats (em breve)'),
    _PlaceholderScreen(title: 'Settings (em breve)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Missões'),
          NavigationDestination(icon: Icon(Icons.bolt_outlined), label: 'Skills'),
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: 'Rewards'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
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

