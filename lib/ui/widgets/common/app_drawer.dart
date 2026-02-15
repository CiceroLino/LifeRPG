import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_DrawerItem>[
      const _DrawerItem(
        label: 'Missions',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/archery-target.svg',
      ),
      const _DrawerItem(
        label: 'Map',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/compass.svg',
      ),
      const _DrawerItem(
        label: 'Rewards',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/present.svg',
      ),
      const _DrawerItem(
        label: 'Inventory',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/chest.svg',
      ),
      const _DrawerItem(
        label: 'Skills',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/skills.svg',
      ),
      const _DrawerItem(
        label: 'Statistics',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/chart.svg',
      ),
      const _DrawerItem(
        label: 'Profile',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/darkzaitzev/hooded-figure.svg',
      ),
      const _DrawerItem(
        label: 'Shop',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/shopping-bag.svg',
      ),
      const _DrawerItem(
        label: 'Settings',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/settings-knobs.svg',
      ),
      const _DrawerItem(
        label: 'Help',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/info.svg',
      ),
    ];

    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120,
              color: const Color(0xFF424242),
              child: Center(
                child: SvgPicture.asset(
                  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/gamepad.svg',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.sports_esports,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  errorBuilder: (_, error, stackTrace) => const Icon(
                    Icons.sports_esports,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(index);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.surface.withValues(alpha: 0.6)
                            : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: selected
                                ? AppTheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            item.asset,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) => const SizedBox(
                              width: 22,
                              height: 22,
                              child: Icon(
                                Icons.circle,
                                color: Colors.white54,
                                size: 16,
                              ),
                            ),
                            errorBuilder: (_, error, stackTrace) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  final String label;
  final String asset;

  const _DrawerItem({required this.label, required this.asset});
}
