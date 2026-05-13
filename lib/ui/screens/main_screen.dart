import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'missions/missions_list_screen.dart';
import 'missions/mission_form_screen.dart';
import 'notebooks/notebooks_screen.dart';
import 'tomes/tomes_screen.dart';
import 'map/map_screen.dart';
import 'rewards/rewards_screen.dart';
import 'rewards/reward_form_screen.dart';
import 'inventory/inventory_screen.dart';
import 'skills/skills_view.dart';
import 'statistics/statistics_screen.dart';
import 'profile/profile_screen.dart';
import 'pomodoro/pomodoro_screen.dart';
import 'shop/shop_screen.dart';
import 'settings/settings_screen.dart';
import 'help/help_screen.dart';
import '../widgets/common/app_drawer.dart';
import '../widgets/common/game_snack_bar.dart';
import '../widgets/common/liferpg_app_bar.dart';
import '../widgets/player/player_stats_header.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/mission_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/skill_provider.dart';
import '../../providers/tome_provider.dart';
import '../../l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isStatsExpanded = true;
  bool _showCompleted = false;
  Timer? _energyAutoRefreshTimer;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlayerProvider>().loadPlayer();
        context.read<SkillProvider>().loadSkills();
        context.read<RewardProvider>().loadRewards();
        context.read<InventoryProvider>().loadItems();
        context.read<TomeProvider>().loadTomes();
        _syncEnergyAutoRefreshTimer();
      }
    });
  }

  @override
  void dispose() {
    _energyAutoRefreshTimer?.cancel();
    super.dispose();
  }

  final _pages = const [
    MissionsListScreen(),
    NotebooksScreen(),
    TomesScreen(),
    MapScreen(),
    RewardsScreen(),
    InventoryScreen(),
    SkillsView(),
    StatisticsScreen(),
    ProfileScreen(),
    ShopScreen(),
    PomodoroScreen(),
    SettingsScreen(),
    HelpScreen(),
  ];

  // Índices que NÃO devem mostrar o header (Notebooks, Tomes, Skills, Settings e Help)
  bool get _shouldShowHeader =>
      _currentIndex != 1 &&
      _currentIndex != 2 &&
      _currentIndex != 6 &&
      _currentIndex != 11 &&
      _currentIndex != 12;

  @override
  Widget build(BuildContext context) {
    return Consumer<MissionProvider>(
      builder: (context, missionProvider, _) {
        return Scaffold(
          drawer: AppDrawer(
            selectedIndex: _currentIndex,
            onItemSelected: (i) => setState(() => _currentIndex = i),
          ),
          appBar: LifeRPGAppBar(
            currentScreen: _getCurrentScreenName(_currentIndex),
            isStatsExpanded: _isStatsExpanded,
            showCompleted: _showCompleted,
            missionSearchQuery: missionProvider.searchQuery,
            currentSort: _missionSortValueForAppBar(context),
            onToggleStats: () =>
                setState(() => _isStatsExpanded = !_isStatsExpanded),
            onToggleShowCompleted: (value) {
              setState(() => _showCompleted = value);
              context.read<MissionProvider>().setShowCompleted(value);
            },
            onSearch: missionProvider.setSearchQuery,
            onEdit: _goToProfile,
            onCalendar: _showCalendarPicker,
            onAddMission: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MissionFormScreen()),
              );
            },
            onSortChanged: (sortValue) => _applySort(sortValue),
            onNavigateToScreen: (index) =>
                setState(() => _currentIndex = index),
            onResetAvatar: _resetAvatar,
            onShareProfile: _shareProfile,
            onExportData: _exportData,
            onClearHistory: _clearHistory,
            onSkillsFilter: _openSkillsFilterSheet,
          ),
          body: Consumer<PlayerProvider>(
            builder: (context, playerProvider, _) {
              _syncEnergyAutoRefreshTimer();
              final shouldShowHeader =
                  _shouldShowHeader &&
                  _isStatsExpanded &&
                  playerProvider.player != null;
              return Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axisAlignment: -1,
                          child: child,
                        ),
                      );
                    },
                    child: shouldShowHeader
                        ? PlayerStatsHeader(
                            key: const ValueKey('player-stats-header'),
                            player: playerProvider.player!,
                            onManualEnergyChanged: (value) =>
                                _setManualEnergy(value),
                            onProfileTap: _goToProfile,
                            showTabs: _currentIndex == 0,
                            onTabChanged: _setMissionTabFilter,
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: IndexedStack(index: _currentIndex, children: _pages),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: _buildFAB(),
        );
      },
    );
  }

  Future<void> _setManualEnergy(int value) async {
    final playerProvider = context.read<PlayerProvider>();
    if (playerProvider.player?.energyMode != 'manual') return;
    await playerProvider.setManualEnergy(value);
  }

  void _syncEnergyAutoRefreshTimer() {
    if (!mounted) return;
    final isAutoMode =
        context.read<PlayerProvider>().player?.energyMode == 'auto';
    if (!isAutoMode) {
      _energyAutoRefreshTimer?.cancel();
      _energyAutoRefreshTimer = null;
      return;
    }

    if (_energyAutoRefreshTimer != null) return;
    _energyAutoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
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

  void _setMissionTabFilter(int index) {
    const filters = [
      MissionFilterMode.plan,
      MissionFilterMode.all,
      MissionFilterMode.next,
      MissionFilterMode.overdue,
      MissionFilterMode.today,
      MissionFilterMode.tomorrow,
    ];
    if (index < 0 || index >= filters.length) return;
    context.read<MissionProvider>().setFilterMode(filters[index]);
  }

  void _goToProfile() {
    setState(() {
      _currentIndex = 8;
    });
  }

  Future<void> _showCalendarPicker() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (!mounted || picked == null) return;
    GameSnackBar.show(
      context,
      title: l10n.translate('calendar'),
      message:
          '${l10n.translate('selected_date_prefix')}${picked.toIso8601String().split('T').first}',
    );
  }

  Future<void> _resetAvatar() async {
    final l10n = AppLocalizations.of(context);
    final playerProvider = context.read<PlayerProvider>();
    final player = playerProvider.player;
    if (player == null) return;
    await playerProvider.updatePlayer(player.copyWith(avatarPath: null));
    if (!mounted) return;
    GameSnackBar.show(
      context,
      title: l10n.translate('profile'),
      message: l10n.translate('avatar_reset_success'),
      type: GameSnackBarType.success,
    );
  }

  Future<void> _shareProfile() async {
    final l10n = AppLocalizations.of(context);
    final player = context.read<PlayerProvider>().player;
    if (player == null) return;
    final text =
        'LifeRPG ${l10n.translate('profile')}\\nName: ${player.name}\\nTitle: ${player.title}\\nLevel: ${player.level}\\nXP: ${player.totalXP}\\nCoins: ${player.rewardPoints}';
    await Share.share(text, subject: 'LifeRPG ${l10n.translate('profile')}');
  }

  Future<void> _exportData() async {
    if (_isExporting) return;
    if (!mounted) return;
    setState(() {
      _isExporting = true;
    });
    final settings = context.read<SettingsProvider>();
    try {
      final l10n = AppLocalizations.of(context);
      final success = await settings.exportData();
      if (!mounted) return;
      if (!success) {
        GameSnackBar.show(
          context,
          title: l10n.translate('export_backup'),
          message: l10n.translate('backup_export_cancelled'),
          type: GameSnackBarType.info,
        );
        return;
      }
      GameSnackBar.show(
        context,
        title: l10n.translate('export_backup'),
        message: l10n.translate('backup_created'),
        type: GameSnackBarType.success,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final shouldClear = await _confirmClearHistory();
    if (!mounted || shouldClear != true) return;

    await context.read<MissionProvider>().clearCompletedMissions();
    if (!mounted) return;
    GameSnackBar.show(
      context,
      title: AppLocalizations.of(context).translate('history'),
      message: AppLocalizations.of(context).translate('history_cleared'),
      type: GameSnackBarType.success,
    );
  }

  Future<bool?> _confirmClearHistory() {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          l10n.translate('confirm_clear_history_title'),
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          l10n.translate('confirm_clear_history_message'),
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.translate('confirm'),
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  String _missionSortValueForAppBar(BuildContext context) {
    final missionProvider = context.read<MissionProvider>();
    switch (missionProvider.sortMode) {
      case MissionSortMode.difficultyDesc:
        return 'difficulty';
      case MissionSortMode.priorityDesc:
        return 'importance';
      case MissionSortMode.rewardDesc:
        return 'reward';
      case MissionSortMode.recent:
      case MissionSortMode.oldest:
        return 'date';
    }
  }

  Future<void> _openSkillsFilterSheet() async {
    final skillProvider = context.read<SkillProvider>();
    final missionProvider = context.read<MissionProvider>();
    final selected = {...missionProvider.selectedSkillIds};
    final l10n = AppLocalizations.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final skills = skillProvider.skills;
        if (skills.isEmpty) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Center(child: Text(l10n.translate('no_skills_available'))),
          );
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final selectedCount = selected.length;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('filter_by_skills'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n
                        .translate('selected_count_label')
                        .replaceFirst('{count}', selectedCount.toString()),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.28,
                    child: SingleChildScrollView(
                      child: Wrap(
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          selected.clear();
                          setState(() {});
                        },
                        child: Text(l10n.translate('clear')),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(l10n.translate('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          missionProvider.setSkillFilters(selected);
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(l10n.translate('apply')),
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
      case 4:
        return FloatingActionButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RewardFormScreen()));
          },
          child: const Icon(Icons.add),
        );
      case 5:
        return null;
      case 6:
        return null;
      case 10:
        return null;
      default:
        return null;
    }
  }

  /// Retorna o nome da tela atual baseado no índice
  String _getCurrentScreenName(int index) {
    const screenNames = [
      'missions',
      'notebooks',
      'tomes',
      'map',
      'rewards',
      'inventory',
      'skills',
      'statistics',
      'profile',
      'shop',
      'pomodoro',
      'settings',
      'help',
    ];
    if (index >= 0 && index < screenNames.length) {
      return screenNames[index];
    }
    return 'missions'; // Default
  }
}
