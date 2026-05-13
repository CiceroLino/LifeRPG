import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final items = <_DrawerItem>[
      const _DrawerItem(
        labelKey: 'missions',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/archery-target.svg',
      ),
      const _DrawerItem(
        labelKey: 'map',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/compass.svg',
      ),
      const _DrawerItem(
        labelKey: 'rewards',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/present.svg',
      ),
      const _DrawerItem(
        labelKey: 'inventory',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/chest.svg',
      ),
      const _DrawerItem(
        labelKey: 'skills',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/skills.svg',
      ),
      const _DrawerItem(
        labelKey: 'statistics',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/chart.svg',
      ),
      const _DrawerItem(
        labelKey: 'profile',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/darkzaitzev/hooded-figure.svg',
      ),
      const _DrawerItem(
        labelKey: 'shop',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/shopping-bag.svg',
      ),
      const _DrawerItem(
        labelKey: 'pomodoro',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/hourglass.svg',
      ),
      const _DrawerItem(
        labelKey: 'settings',
        asset:
            'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/settings-knobs.svg',
      ),
      const _DrawerItem(
        labelKey: 'help',
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
              height: 116,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF424242),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/gamepad.svg',
                    width: 46,
                    height: 46,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => const SizedBox(
                      width: 46,
                      height: 46,
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
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LifeRPG',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.translate('app_subtitle'),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  return ListTile(
                    selected: selected,
                    selectedColor: AppTheme.primary,
                    selectedTileColor: AppTheme.surface.withValues(alpha: 0.3),
                    iconColor: selected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(index);
                    },
                    leading: SvgPicture.asset(
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
                    title: Text(
                      l10n.translate(item.labelKey),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    tileColor: selected ? AppTheme.surface.withValues(alpha: .7) : null,
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
  final String labelKey;
  final String asset;

  const _DrawerItem({required this.labelKey, required this.asset});
}
