import 'package:flutter/material.dart';

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
      const _DrawerItem(labelKey: 'missions', icon: Icons.flag_outlined),
      const _DrawerItem(labelKey: 'notebooks', icon: Icons.menu_book_outlined),
      const _DrawerItem(labelKey: 'tomes', icon: Icons.auto_stories_outlined),
      const _DrawerItem(labelKey: 'map', icon: Icons.map_outlined),
      const _DrawerItem(
        labelKey: 'rewards',
        icon: Icons.card_giftcard_outlined,
      ),
      const _DrawerItem(
        labelKey: 'inventory',
        icon: Icons.inventory_2_outlined,
      ),
      const _DrawerItem(labelKey: 'skills', icon: Icons.auto_graph),
      const _DrawerItem(labelKey: 'statistics', icon: Icons.query_stats),
      const _DrawerItem(labelKey: 'profile', icon: Icons.person_outline),
      const _DrawerItem(labelKey: 'shop', icon: Icons.storefront_outlined),
      const _DrawerItem(
        labelKey: 'pomodoro',
        icon: Icons.hourglass_bottom_outlined,
      ),
      const _DrawerItem(labelKey: 'settings', icon: Icons.settings_outlined),
      const _DrawerItem(labelKey: 'help', icon: Icons.help_outline),
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
                  const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(
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
                    leading: Icon(
                      item.icon,
                      size: 22,
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                    title: Text(
                      l10n.translate(item.labelKey),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    tileColor: selected
                        ? AppTheme.surface.withValues(alpha: .7)
                        : null,
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
  final IconData icon;

  const _DrawerItem({required this.labelKey, required this.icon});
}
