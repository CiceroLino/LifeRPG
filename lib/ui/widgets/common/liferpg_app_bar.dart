import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// AppBar customizado para o LifeRPG
///
/// Implementa [PreferredSizeWidget] para ser usado como `appBar:` em Scaffolds.
/// Design denso, escuro e funcional que se adapta dinamicamente ao contexto da tela.
class LifeRPGAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Tela atual: 'missions', 'profile', ou 'statistics'
  final String currentScreen;

  /// Estado de expansão do PlayerStatsHeader
  final bool isStatsExpanded;

  /// Estado de visibilidade de missões completadas (apenas para missions)
  final bool showCompleted;

  /// Callback quando o botão de expand/collapse é pressionado
  final VoidCallback? onToggleStats;

  /// Callback para alternar visibilidade de missões completadas
  final Function(bool)? onToggleShowCompleted;

  /// Callback quando o botão de search é pressionado (missions)
  final VoidCallback? onSearch;

  /// Callback quando o botão de edit é pressionado (profile)
  final VoidCallback? onEdit;

  /// Callback quando o botão de calendar é pressionado (statistics)
  final VoidCallback? onCalendar;

  /// Callback para navegar para criação de missão
  final VoidCallback? onAddMission;

  /// Callback quando uma opção de ordenação é selecionada
  final ValueChanged<String>? onSortChanged;

  /// Callback quando workspace é alterado
  final ValueChanged<String>? onWorkspaceChanged;

  /// Callback para resetar avatar (profile)
  final VoidCallback? onResetAvatar;

  /// Callback para compartilhar perfil (profile)
  final VoidCallback? onShareProfile;

  /// Callback para exportar dados (statistics)
  final VoidCallback? onExportData;

  /// Callback para limpar histórico (statistics)
  final VoidCallback? onClearHistory;

  /// Callback para abrir filtro de skills (missions)
  final VoidCallback? onSkillsFilter;

  const LifeRPGAppBar({
    super.key,
    required this.currentScreen,
    this.isStatsExpanded = true,
    this.showCompleted = false,
    this.onToggleStats,
    this.onToggleShowCompleted,
    this.onSearch,
    this.onEdit,
    this.onCalendar,
    this.onAddMission,
    this.onSortChanged,
    this.onWorkspaceChanged,
    this.onResetAvatar,
    this.onShareProfile,
    this.onExportData,
    this.onClearHistory,
    this.onSkillsFilter,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.background, // #212121
      elevation: 0, // Flat, sem elevação
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          color: AppTheme.textPrimary,
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: _buildTitle(context),
      titleSpacing: 0, // Título próximo ao ícone do menu
      actions: _buildActions(context),
    );
  }

  /// Constrói o título interativo com dropdown e subtítulo dinâmico
  Widget _buildTitle(BuildContext context) {
    // Capitaliza a primeira letra do currentScreen
    final screenName = currentScreen.isEmpty
        ? ''
        : currentScreen[0].toUpperCase() + currentScreen.substring(1);

    return InkWell(
      onTap: () => _showWorkspaceDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linha 1: "LifeRPG" + Ícone dropdown
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LifeRPG',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              ],
            ),
            // Linha 2: Subtítulo dinâmico baseado em currentScreen
            Text(
              screenName,
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

  /// Constrói os botões de ação no canto direito baseado no contexto
  List<Widget> _buildActions(BuildContext context) {
    switch (currentScreen) {
      case 'missions':
        return _buildMissionsActions(context);
      case 'profile':
        return _buildProfileActions(context);
      case 'statistics':
        return _buildStatisticsActions(context);
      default:
        return _buildMissionsActions(context); // Default
    }
  }

  /// Actions para o contexto de Missions
  List<Widget> _buildMissionsActions(BuildContext context) {
    return [
      // Botão Expandir/Recolher
      IconButton(
        icon: Icon(
          isStatsExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
          color: AppTheme.textPrimary,
        ),
        onPressed: onToggleStats,
        tooltip: isStatsExpanded ? 'Ocultar Stats' : 'Mostrar Stats',
      ),
      // Botão Search
      IconButton(
        icon: const Icon(Icons.search, color: AppTheme.textPrimary),
        onPressed: onSearch,
        tooltip: 'Buscar',
      ),
      // Overflow Menu
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
        onSelected: (value) => _handleMissionsMenuAction(context, value),
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'add',
            child: Row(
              children: [
                Icon(Icons.add, size: 20, color: AppTheme.textPrimary),
                SizedBox(width: 12),
                Text('Add mission'),
              ],
            ),
          ),
          CheckedPopupMenuItem<String>(
            value: 'show_completed',
            checked: showCompleted,
            child: const Text('Show completed'),
          ),
          const PopupMenuItem<String>(
            value: 'sort',
            child: Row(
              children: [
                Icon(Icons.sort, size: 20, color: AppTheme.textPrimary),
                SizedBox(width: 12),
                Text('Sort by...'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'skills_filter',
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 20, color: AppTheme.textPrimary),
                SizedBox(width: 12),
                Text('Skills filter'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  /// Actions para o contexto de Profile
  List<Widget> _buildProfileActions(BuildContext context) {
    return [
      // Botão Expandir/Recolher
      IconButton(
        icon: Icon(
          isStatsExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
          color: AppTheme.textPrimary,
        ),
        onPressed: onToggleStats,
        tooltip: isStatsExpanded ? 'Ocultar Stats' : 'Mostrar Stats',
      ),
      // Botão Edit
      IconButton(
        icon: const Icon(Icons.edit, color: AppTheme.textPrimary),
        onPressed: onEdit,
        tooltip: 'Editar Perfil',
      ),
      // Overflow Menu
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
        onSelected: (value) => _handleProfileMenuAction(context, value),
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'reset_avatar',
            child: Row(
              children: [
                Icon(Icons.refresh, size: 20, color: AppTheme.textPrimary),
                SizedBox(width: 12),
                Text('Reset Avatar'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'share_profile',
            child: Row(
              children: [
                Icon(Icons.share, size: 20, color: AppTheme.textPrimary),
                SizedBox(width: 12),
                Text('Share Profile'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  /// Actions para o contexto de Statistics
  List<Widget> _buildStatisticsActions(BuildContext context) {
    return [
      // Botão Expandir/Recolher
      IconButton(
        icon: Icon(
          isStatsExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
          color: AppTheme.textPrimary,
        ),
        onPressed: onToggleStats,
        tooltip: isStatsExpanded ? 'Ocultar Stats' : 'Mostrar Stats',
      ),
      // Botão Calendar
      IconButton(
        icon: const Icon(Icons.calendar_today, color: AppTheme.textPrimary),
        onPressed: onCalendar,
        tooltip: 'Calendário',
      ),
      // Overflow Menu
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
        onSelected: (value) => _handleStatisticsMenuAction(context, value),
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'export',
            child: Row(
              children: [
                Icon(
                  Icons.file_download,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
                SizedBox(width: 12),
                Text('Export Data (CSV)'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'clear_history',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
                SizedBox(width: 12),
                Text('Clear History'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  /// Manipula as ações do menu overflow para Missions
  void _handleMissionsMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'add':
        if (onAddMission != null) {
          onAddMission!();
        } else {
          debugPrint('Add mission');
        }
        break;

      case 'show_completed':
        onToggleShowCompleted?.call(!showCompleted);
        break;

      case 'sort':
        _showSortDialog(context);
        break;

      case 'skills_filter':
        if (onSkillsFilter != null) {
          onSkillsFilter!();
        } else {
          debugPrint('Open filter');
        }
        break;

      default:
        break;
    }
  }

  /// Manipula as ações do menu overflow para Profile
  void _handleProfileMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'reset_avatar':
        if (onResetAvatar != null) {
          onResetAvatar!();
        } else {
          debugPrint('Reset Avatar');
        }
        break;

      case 'share_profile':
        if (onShareProfile != null) {
          onShareProfile!();
        } else {
          debugPrint('Share Profile');
        }
        break;

      default:
        break;
    }
  }

  /// Manipula as ações do menu overflow para Statistics
  void _handleStatisticsMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'export':
        if (onExportData != null) {
          onExportData!();
        } else {
          debugPrint('Export Data (CSV)');
        }
        break;

      case 'clear_history':
        if (onClearHistory != null) {
          onClearHistory!();
        } else {
          debugPrint('Clear History');
        }
        break;

      default:
        break;
    }
  }

  /// Mostra o dialog de opções de ordenação
  void _showSortDialog(BuildContext context) {
    String selectedSort = 'date'; // Valor padrão

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Sort Options',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            Widget sortOption(String value, String label) {
              final selected = selectedSort == value;
              return ListTile(
                title: Text(
                  label,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                trailing: selected
                    ? const Icon(Icons.check_circle, color: AppTheme.primary)
                    : const Icon(
                        Icons.circle_outlined,
                        color: AppTheme.textSecondary,
                      ),
                onTap: () {
                  setState(() {
                    selectedSort = value;
                  });
                },
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                sortOption('date', 'Date'),
                sortOption('difficulty', 'Difficulty'),
                sortOption('importance', 'Importance'),
                sortOption('reward', 'Reward'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              onSortChanged?.call(selectedSort);
              debugPrint('Sort by: $selectedSort');
              Navigator.of(context).pop();
            },
            child: const Text(
              'Apply',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Mostra o dialog mockado para trocar de Workspace
  void _showWorkspaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Select Workspace',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () {
              onWorkspaceChanged?.call('personal');
              Navigator.of(context).pop();
            },
            child: const Text(
              'Personal',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              onWorkspaceChanged?.call('work');
              Navigator.of(context).pop();
            },
            child: const Text(
              'Work',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
