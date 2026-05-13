import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// AppBar customizado para o LifeRPG.
///
/// Se adapta ao contexto da tela atual (`currentScreen`) e expõe ações
/// específicas para cada fluxo de uso (missões, perfil e estatísticas).
class LifeRPGAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String currentScreen;
  final bool isStatsExpanded;
  final bool showCompleted;
  final String currentSort;
  final String missionSearchQuery;
  final VoidCallback? onToggleStats;
  final Function(bool)? onToggleShowCompleted;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onEdit;
  final VoidCallback? onCalendar;
  final VoidCallback? onAddMission;
  final ValueChanged<String>? onSortChanged;
  final ValueChanged<int>? onNavigateToScreen;
  final VoidCallback? onResetAvatar;
  final VoidCallback? onShareProfile;
  final VoidCallback? onExportData;
  final VoidCallback? onClearHistory;
  final VoidCallback? onSkillsFilter;

  const LifeRPGAppBar({
    super.key,
    required this.currentScreen,
    this.isStatsExpanded = true,
    this.showCompleted = false,
    this.currentSort = 'date',
    this.missionSearchQuery = '',
    this.onToggleStats,
    this.onToggleShowCompleted,
    this.onSearch,
    this.onEdit,
    this.onCalendar,
    this.onAddMission,
    this.onSortChanged,
    this.onNavigateToScreen,
    this.onResetAvatar,
    this.onShareProfile,
    this.onExportData,
    this.onClearHistory,
    this.onSkillsFilter,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<LifeRPGAppBar> createState() => _LifeRPGAppBarState();
}

class _LifeRPGAppBarState extends State<LifeRPGAppBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isMissionSearchExpanded = false;
  bool _hasSearchText = false;
  bool _isSyncingSearchText = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.missionSearchQuery;
    _hasSearchText = widget.missionSearchQuery.trim().isNotEmpty;
    _searchController.addListener(_handleSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchTextChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LifeRPGAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!mounted) {
      return;
    }

    if (widget.currentScreen != 'missions' && _isMissionSearchExpanded) {
      setState(() {
        _isMissionSearchExpanded = false;
      });
      _searchFocusNode.unfocus();
      _setSearchText('');
      widget.onSearch?.call('');
      return;
    }

    if (widget.currentScreen == 'missions' &&
        widget.missionSearchQuery != _searchController.text) {
      _setSearchText(widget.missionSearchQuery);
    }
  }

  void _handleSearchTextChanged() {
    if (!mounted || _isSyncingSearchText) {
      return;
    }

    final nextHasText = _searchController.text.trim().isNotEmpty;
    if (_hasSearchText != nextHasText) {
      setState(() {
        _hasSearchText = nextHasText;
      });
    }
    widget.onSearch?.call(_searchController.text);
  }

  void _setSearchText(String value) {
    if (!mounted) {
      return;
    }

    if (_searchController.text == value) {
      _hasSearchText = value.trim().isNotEmpty;
      return;
    }

    _isSyncingSearchText = true;
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _isSyncingSearchText = false;
    _hasSearchText = value.trim().isNotEmpty;
  }

  void _toggleMissionSearch() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isMissionSearchExpanded = !_isMissionSearchExpanded;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_isMissionSearchExpanded) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
      }
    });
  }

  void _clearMissionSearch() {
    if (!_hasSearchText || !mounted) {
      return;
    }
    _setSearchText('');
    widget.onSearch?.call('');
    setState(() {
      _hasSearchText = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          color: AppTheme.textPrimary,
          tooltip: l10n.translate('open_menu'),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: _buildTitle(context),
      titleSpacing: 0,
      actions: _buildActions(context),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.currentScreen == 'missions' && _isMissionSearchExpanded) {
      return _buildMissionSearchField(l10n);
    }

    return _buildNavigationDropdown(context, l10n);
  }

  Widget _buildMissionSearchField(AppLocalizations l10n) {
    return TextField(
      key: const Key('mission-search-field'),
      controller: _searchController,
      focusNode: _searchFocusNode,
      onSubmitted: (_) {
        _searchFocusNode.unfocus();
      },
      decoration: InputDecoration(
        hintText: l10n.translate('mission_search_hint'),
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: const Icon(
          Icons.search,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        suffixIcon: _hasSearchText
            ? IconButton(
                key: const Key('mission-search-clear'),
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                tooltip: l10n.translate('search_clear'),
                onPressed: _clearMissionSearch,
              )
            : null,
        border: const UnderlineInputBorder(),
        isDense: true,
      ),
      style: const TextStyle(color: AppTheme.textPrimary),
      cursorColor: AppTheme.primary,
    );
  }

  Widget _buildNavigationDropdown(BuildContext context, AppLocalizations l10n) {
    final destinations = _navigationDestinations(l10n);
    return PopupMenuButton<int>(
      tooltip: l10n.translate('navigation_title'),
      offset: const Offset(0, 8),
      initialValue: _currentScreenIndex(widget.currentScreen),
      onSelected: (value) => widget.onNavigateToScreen?.call(value),
      itemBuilder: (context) => destinations
          .map(
            (destination) => PopupMenuItem<int>(
              value: destination.index,
              child: Row(
                children: [
                  Icon(destination.icon, color: AppTheme.textPrimary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    destination.label,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LifeRPG',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.unfold_more, color: AppTheme.textPrimary, size: 20),
              ],
            ),
            Text(
              _screenLabel(widget.currentScreen, l10n),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    switch (widget.currentScreen) {
      case 'missions':
        return _buildMissionsActions(context);
      case 'profile':
        return _buildProfileActions(context);
      case 'statistics':
        return _buildStatisticsActions(context);
      default:
        return _buildDefaultActions(context);
    }
  }

  Widget _buildStatusToggleButton(AppLocalizations l10n) => IconButton(
    icon: Icon(
      widget.isStatsExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
      color: AppTheme.textPrimary,
    ),
    onPressed: widget.onToggleStats,
    tooltip: widget.isStatsExpanded
        ? l10n.translate('hide_status')
        : l10n.translate('show_status'),
  );

  List<Widget> _buildDefaultActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [_buildStatusToggleButton(l10n)];
  }

  List<Widget> _buildMissionsActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _buildStatusToggleButton(l10n),
      IconButton(
        key: const Key('mission-search-toggle'),
        icon: Icon(
          _isMissionSearchExpanded ? Icons.close : Icons.search,
          color: AppTheme.textPrimary,
        ),
        onPressed: _toggleMissionSearch,
        tooltip: _isMissionSearchExpanded
            ? l10n.translate('close')
            : l10n.translate('search_missions'),
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
        tooltip: l10n.translate('more_options'),
        onSelected: (value) => _handleMissionsMenuAction(context, value),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'add',
            child: Row(
              children: [
                const Icon(Icons.add, size: 20, color: AppTheme.textPrimary),
                const SizedBox(width: 12),
                Text(l10n.translate('add_mission')),
              ],
            ),
          ),
          CheckedPopupMenuItem<String>(
            value: 'show_completed',
            checked: widget.showCompleted,
            child: Text(l10n.translate('show_completed')),
          ),
          PopupMenuItem<String>(
            value: 'sort',
            child: Row(
              children: [
                const Icon(Icons.sort, size: 20, color: AppTheme.textPrimary),
                const SizedBox(width: 12),
                Text(l10n.translate('sort_by')),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'skills_filter',
            child: Row(
              children: [
                const Icon(
                  Icons.filter_list,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(l10n.translate('filter_by_skill')),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildProfileActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _buildStatusToggleButton(l10n),
      IconButton(
        icon: const Icon(Icons.edit, color: AppTheme.textPrimary),
        onPressed: widget.onEdit,
        tooltip: l10n.translate('edit_profile'),
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
        tooltip: l10n.translate('more_options'),
        onSelected: (value) => _handleProfileMenuAction(context, value),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'reset_avatar',
            child: Row(
              children: [
                const Icon(
                  Icons.refresh,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(l10n.translate('reset_avatar')),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'share_profile',
            child: Row(
              children: [
                const Icon(Icons.share, size: 20, color: AppTheme.textPrimary),
                const SizedBox(width: 12),
                Text(l10n.translate('share_profile')),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStatisticsActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _buildStatusToggleButton(l10n),
      IconButton(
        icon: const Icon(Icons.calendar_today, color: AppTheme.textPrimary),
        onPressed: widget.onCalendar,
        tooltip: l10n.translate('calendar'),
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
        tooltip: l10n.translate('more_options'),
        onSelected: (value) => _handleStatisticsMenuAction(context, value),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'export',
            child: Row(
              children: [
                const Icon(
                  Icons.file_download,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(l10n.translate('export_backup')),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'clear_history',
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(l10n.translate('clear_history')),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  void _handleMissionsMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'add':
        widget.onAddMission?.call();
        return;
      case 'show_completed':
        widget.onToggleShowCompleted?.call(!widget.showCompleted);
        return;
      case 'sort':
        _showSortDialog(context);
        return;
      case 'skills_filter':
        widget.onSkillsFilter?.call();
        return;
      default:
        return;
    }
  }

  void _handleProfileMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'reset_avatar':
        widget.onResetAvatar?.call();
        return;
      case 'share_profile':
        widget.onShareProfile?.call();
        return;
      default:
        return;
    }
  }

  void _handleStatisticsMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'export':
        widget.onExportData?.call();
        return;
      case 'clear_history':
        widget.onClearHistory?.call();
        return;
      default:
        return;
    }
  }

  void _showSortDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String selectedSort = _normalizeSortValue(widget.currentSort);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          l10n.translate('sort_options'),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            const sortOptions = [
              ('date', 'sort_date'),
              ('difficulty', 'sort_difficulty'),
              ('importance', 'sort_importance'),
              ('reward', 'sort_reward'),
            ];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: sortOptions.map((option) {
                final isSelected = selectedSort == option.$1;
                return ListTile(
                  selected: isSelected,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                  title: Text(
                    l10n.translate(option.$2),
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  onTap: () => setState(() => selectedSort = option.$1),
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.translate('cancel'),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.onSortChanged?.call(selectedSort);
              Navigator.of(context).pop();
            },
            child: Text(
              l10n.translate('apply'),
              style: const TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _screenLabel(String screen, AppLocalizations l10n) {
    switch (screen) {
      case 'missions':
        return l10n.translate('missions');
      case 'map':
        return l10n.translate('map');
      case 'rewards':
        return l10n.translate('rewards');
      case 'inventory':
        return l10n.translate('inventory');
      case 'skills':
        return l10n.translate('skills');
      case 'statistics':
        return l10n.translate('statistics');
      case 'profile':
        return l10n.translate('profile');
      case 'shop':
        return l10n.translate('shop');
      case 'pomodoro':
        return l10n.translate('pomodoro');
      case 'settings':
        return l10n.translate('settings');
      case 'help':
        return l10n.translate('help');
      default:
        return screen.isNotEmpty
            ? screen[0].toUpperCase() + screen.substring(1)
            : '';
    }
  }

  int _currentScreenIndex(String screen) {
    const screens = {
      'missions': 0,
      'map': 1,
      'rewards': 2,
      'inventory': 3,
      'skills': 4,
      'statistics': 5,
      'profile': 6,
      'shop': 7,
      'pomodoro': 8,
      'settings': 9,
      'help': 10,
    };
    return screens[screen] ?? 0;
  }

  List<_AppBarDestination> _navigationDestinations(AppLocalizations l10n) => [
    _AppBarDestination(
      index: 0,
      label: l10n.translate('missions'),
      icon: Icons.flag_outlined,
    ),
    _AppBarDestination(
      index: 1,
      label: l10n.translate('map'),
      icon: Icons.map_outlined,
    ),
    _AppBarDestination(
      index: 2,
      label: l10n.translate('rewards'),
      icon: Icons.card_giftcard_outlined,
    ),
    _AppBarDestination(
      index: 3,
      label: l10n.translate('inventory'),
      icon: Icons.inventory_2_outlined,
    ),
    _AppBarDestination(
      index: 4,
      label: l10n.translate('skills'),
      icon: Icons.auto_graph,
    ),
    _AppBarDestination(
      index: 5,
      label: l10n.translate('statistics'),
      icon: Icons.query_stats,
    ),
    _AppBarDestination(
      index: 6,
      label: l10n.translate('profile'),
      icon: Icons.person_outline,
    ),
    _AppBarDestination(
      index: 7,
      label: l10n.translate('shop'),
      icon: Icons.storefront_outlined,
    ),
    _AppBarDestination(
      index: 8,
      label: l10n.translate('pomodoro'),
      icon: Icons.hourglass_bottom_outlined,
    ),
    _AppBarDestination(
      index: 9,
      label: l10n.translate('settings'),
      icon: Icons.settings_outlined,
    ),
    _AppBarDestination(
      index: 10,
      label: l10n.translate('help'),
      icon: Icons.help_outline,
    ),
  ];

  String _normalizeSortValue(String value) {
    if (value == 'difficulty' ||
        value == 'importance' ||
        value == 'reward' ||
        value == 'date') {
      return value;
    }
    return 'date';
  }
}

class _AppBarDestination {
  const _AppBarDestination({
    required this.index,
    required this.label,
    required this.icon,
  });

  final int index;
  final String label;
  final IconData icon;
}
