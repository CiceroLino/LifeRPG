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
    final sections = <_DrawerSection>[
      const _DrawerSection(
        labelKey: 'nav_group_quest_log',
        items: [
          _DrawerItem(
            index: 0,
            labelKey: 'missions',
            icon: Icons.flag_outlined,
          ),
          _DrawerItem(index: 4, labelKey: 'map', icon: Icons.map_outlined),
          _DrawerItem(
            index: 11,
            labelKey: 'focus_quest',
            icon: Icons.hourglass_bottom_outlined,
          ),
        ],
      ),
      const _DrawerSection(
        labelKey: 'nav_group_character',
        items: [
          _DrawerItem(
            index: 9,
            labelKey: 'profile',
            icon: Icons.person_outline,
          ),
          _DrawerItem(index: 7, labelKey: 'skills', icon: Icons.auto_graph),
          _DrawerItem(
            index: 8,
            labelKey: 'statistics',
            icon: Icons.query_stats,
          ),
        ],
      ),
      const _DrawerSection(
        labelKey: 'nav_group_loot',
        items: [
          _DrawerItem(
            index: 5,
            labelKey: 'rewards',
            icon: Icons.card_giftcard_outlined,
          ),
          _DrawerItem(
            index: 6,
            labelKey: 'inventory',
            icon: Icons.inventory_2_outlined,
          ),
          _DrawerItem(
            index: 10,
            labelKey: 'shop',
            icon: Icons.storefront_outlined,
          ),
        ],
      ),
      const _DrawerSection(
        labelKey: 'nav_group_lore',
        items: [
          _DrawerItem(
            index: 1,
            labelKey: 'notebooks',
            icon: Icons.menu_book_outlined,
          ),
          _DrawerItem(
            index: 2,
            labelKey: 'tomes',
            icon: Icons.auto_stories_outlined,
          ),
          _DrawerItem(
            index: 3,
            labelKey: 'tavern',
            icon: Icons.local_bar_outlined,
          ),
        ],
      ),
      const _DrawerSection(
        labelKey: 'nav_group_system',
        items: [
          _DrawerItem(
            index: 12,
            labelKey: 'settings',
            icon: Icons.settings_outlined,
          ),
          _DrawerItem(index: 13, labelKey: 'help', icon: Icons.help_outline),
        ],
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
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.86),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.28),
                  ),
                ),
              ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LifeRPG',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.translate('app_subtitle'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
                children: [
                  for (final section in sections) ...[
                    _DrawerSectionLabel(
                      label: l10n.translate(section.labelKey),
                    ),
                    for (final item in section.items)
                      _DrawerTile(
                        item: item,
                        label: l10n.translate(item.labelKey),
                        selected: item.index == selectedIndex,
                        onTap: () {
                          Navigator.pop(context);
                          onItemSelected(item.index);
                        },
                      ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppTheme.primary.withValues(alpha: 0.88),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _DrawerItem item;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppTheme.primary : AppTheme.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: selected,
        selectedColor: AppTheme.primary,
        selectedTileColor: AppTheme.primary.withValues(alpha: 0.12),
        iconColor: selected ? AppTheme.primary : AppTheme.textSecondary,
        minLeadingWidth: 24,
        minVerticalPadding: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onTap,
        leading: Icon(
          item.icon,
          size: 22,
          color: selected ? AppTheme.primary : AppTheme.textSecondary,
        ),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.chevron_right, color: AppTheme.primary, size: 18)
            : null,
      ),
    );
  }
}

class _DrawerSection {
  final String labelKey;
  final List<_DrawerItem> items;

  const _DrawerSection({required this.labelKey, required this.items});
}

class _DrawerItem {
  final int index;
  final String labelKey;
  final IconData icon;

  const _DrawerItem({
    required this.index,
    required this.labelKey,
    required this.icon,
  });
}
