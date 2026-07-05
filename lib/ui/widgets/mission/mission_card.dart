import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/mission.dart';
import '../../../l10n/app_localizations.dart';
import '../../screens/missions/mission_icon_assets.dart';

enum MissionCardQuickAction {
  duplicate,
  adjustAttributes,
  editNotes,
  delete,
  fail,
  reschedule,
  recurrence,
  reward,
  duration,
  skills,
  move,
}

class MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback? onTap;
  final VoidCallback? onAddSubtask;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  final Future<void> Function(String status)? onStatusChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onAdjustAttributes;
  final VoidCallback? onEditNotes;
  final ValueChanged<MissionCardQuickAction>? onQuickAction;
  final double progress; // 0.0 to 1.0
  final String? timeWarning;

  const MissionCard({
    super.key,
    required this.mission,
    this.onTap,
    this.onAddSubtask,
    this.isExpanded = false,
    this.onToggleExpanded,
    this.onStatusChanged,
    this.onEdit,
    this.onDuplicate,
    this.onAdjustAttributes,
    this.onEditNotes,
    this.onQuickAction,
    this.progress = 0.0,
    this.timeWarning,
  });

  /// Calcula a cor de prioridade baseada nos atributos da missão
  Color _getPriorityColor() {
    // Prioridade baseada em urgency (vermelho), difficulty (laranja), fear (azul)
    final urgency = mission.urgency;
    final difficulty = mission.difficulty;
    final fear = mission.fear;

    // Extreme urgency gets the strongest priority color.
    if (urgency >= 76) {
      return AppTheme.accentRed;
    }
    if (difficulty >= 76) {
      return const Color(0xFFFF9800); // Orange
    }
    if (fear >= 76) {
      return AppTheme.primary;
    }
    if (urgency >= 51) {
      return AppTheme.accentAmber;
    }
    // Padrão: cinza para baixa prioridade
    return AppTheme.textSecondary;
  }

  /// Formata a duração estimada
  String _formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) return '';
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}min';
  }

  /// Obtém o ícone da missão
  Widget _buildIcon() {
    final iconColor = _getPriorityColor();

    // Se tem ícone SVG, usa ele
    if (mission.icon != null && mission.icon!.isNotEmpty) {
      final iconAsset = normalizeMissionIconAsset(mission.icon!);
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(
          iconAsset,
          width: 34,
          height: 34,
          placeholderBuilder: (_) =>
              Icon(Icons.task_alt, color: iconColor, size: 24),
          errorBuilder: (_, error, stackTrace) =>
              Icon(Icons.task_alt, color: iconColor, size: 24),
        ),
      );
    }

    // Se tem emoji, usa ele
    if (mission.emoji != null && mission.emoji!.isNotEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(mission.emoji!, style: const TextStyle(fontSize: 28)),
        ),
      );
    }

    // Ícone padrão baseado no título ou tipo
    FaIconData defaultIcon = FontAwesomeIcons.bullseye;
    final titleLower = mission.title.toLowerCase();
    if (titleLower.contains('chore') || titleLower.contains('tarefa')) {
      defaultIcon = FontAwesomeIcons.broom;
    } else if (titleLower.contains('fitness') || titleLower.contains('exerc')) {
      defaultIcon = FontAwesomeIcons.heartPulse;
    } else if (titleLower.contains('study') || titleLower.contains('estud')) {
      defaultIcon = FontAwesomeIcons.book;
    } else if (titleLower.contains('work') || titleLower.contains('trabalh')) {
      defaultIcon = FontAwesomeIcons.briefcase;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: FaIcon(defaultIcon, color: iconColor, size: 24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final priorityColor = _getPriorityColor();
    final cardColor = const Color(0xFF424242); // Slightly darker than surface

    void onStatusSelectChanged(String? value) {
      if (onStatusChanged == null || value == null) return;
      if (value == mission.status) return;
      onStatusChanged!(value);
    }

    void onQuickActionSelected(MissionCardQuickAction action) {
      if (onQuickAction == null) return;
      onQuickAction?.call(action);
    }

    String statusLabel() {
      if (mission.status == 'completed') return l10n.translate('completed');
      if (mission.status == 'archived') return l10n.translate('archived');
      return l10n.translate('active');
    }

    return InkWell(
      onTap: onToggleExpanded ?? onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Faixa de Prioridade (Left Strip)
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),

              // Área do Ícone
              Padding(padding: const EdgeInsets.all(10), child: _buildIcon()),

              // Conteúdo Principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Linha 1: Cabeçalho (Ícone +, Título, Chevron)
                      Row(
                        children: [
                          // Ícone "+" para subtask
                          GestureDetector(
                            onTap: onAddSubtask,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isExpanded)
                            Flexible(
                              child: Text(
                                statusLabel(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (!isExpanded) const Spacer(),
                          // Título
                          Expanded(
                            child: Text(
                              mission.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.chevron_right,
                            size: 22,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Linha 2: Descrição/Meta (Recorrência, Descrição/Duração, Recompensa)
                      Row(
                        children: [
                          // Ícone de Recorrência (se aplicável)
                          if (mission.isRecurring) ...[
                            Icon(
                              Icons.repeat,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          // Descrição ou Duração
                          Expanded(
                            child: Text(
                              mission.description.isNotEmpty
                                  ? mission.description
                                  : _formatDuration(mission.estimatedDuration),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Ícone de Diamante + Recompensa
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.gem,
                                size: 12,
                                color: AppTheme.accentAmber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${mission.rewardPoints}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.accentAmber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (timeWarning != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.accentAmber.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.hourglass_bottom,
                                color: AppTheme.accentAmber,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  timeWarning!,
                                  style: const TextStyle(
                                    color: AppTheme.accentAmber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (isExpanded) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 10),
                        if (mission.notes.isNotEmpty) ...[
                          _ExpandedLoreBlock(
                            icon: Icons.menu_book_outlined,
                            label: l10n.translate('mission_notes'),
                            value: mission.notes,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (mission.reminderNote.isNotEmpty) ...[
                          _ExpandedLoreBlock(
                            icon: Icons.edit_notifications_outlined,
                            label: l10n.translate('mission_reminder'),
                            value: mission.reminderNote,
                          ),
                          const SizedBox(height: 8),
                        ],
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  key: const Key('mission-status-select'),
                                  value: mission.status,
                                  isDense: true,
                                  icon: const Icon(
                                    Icons.expand_more,
                                    color: AppTheme.textSecondary,
                                    size: 18,
                                  ),
                                  onChanged: onStatusSelectChanged,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'active',
                                      child: Text(l10n.translate('active')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'completed',
                                      child: Text(l10n.translate('completed')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'archived',
                                      child: Text(l10n.translate('archived')),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                key: const Key('mission-edit-button'),
                                tooltip: l10n.translate('edit_mission'),
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                                onPressed: onEdit,
                              ),
                              const SizedBox(width: 2),
                              IconButton(
                                key: const Key('mission-duplicate-button'),
                                tooltip: l10n.translate('duplicate_mission'),
                                icon: const Icon(
                                  Icons.add,
                                  color: AppTheme.accentAmber,
                                  size: 18,
                                ),
                                onPressed: onDuplicate,
                              ),
                              const SizedBox(width: 2),
                              IconButton(
                                key: const Key('mission-adjust-button'),
                                tooltip: l10n.translate('adjust_attributes'),
                                icon: const Icon(
                                  Icons.tune,
                                  color: AppTheme.textSecondary,
                                  size: 18,
                                ),
                                onPressed: onAdjustAttributes,
                              ),
                              const SizedBox(width: 2),
                              IconButton(
                                key: const Key('mission-notes-button'),
                                tooltip: l10n.translate('edit_notes'),
                                icon: const Icon(
                                  Icons.note_alt,
                                  color: AppTheme.textSecondary,
                                  size: 18,
                                ),
                                onPressed: onEditNotes,
                              ),
                              PopupMenuButton<MissionCardQuickAction>(
                                key: const Key('mission-quick-action-button'),
                                tooltip: l10n.translate('menu_more_actions'),
                                color: AppTheme.surface,
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: AppTheme.textSecondary,
                                  size: 18,
                                ),
                                onSelected: onQuickActionSelected,
                                itemBuilder: (context) => [
                                  _missionQuickActionItem(
                                    l10n.translate('delete'),
                                    Icons.delete_outline,
                                    MissionCardQuickAction.delete,
                                  ),
                                  _missionQuickActionItem(
                                    l10n.translate('mission_menu_fail'),
                                    Icons.cancel_outlined,
                                    MissionCardQuickAction.fail,
                                  ),
                                  _missionQuickActionItem(
                                    l10n.translate('mission_menu_reschedule'),
                                    Icons.event,
                                    MissionCardQuickAction.reschedule,
                                  ),
                                  _missionQuickActionItem(
                                    l10n.translate('mission_menu_recurrence'),
                                    Icons.repeat,
                                    MissionCardQuickAction.recurrence,
                                  ),
                                  _missionQuickActionItem(
                                    l10n.translate('mission_menu_reward'),
                                    Icons.auto_awesome,
                                    MissionCardQuickAction.reward,
                                  ),
                                  _missionQuickActionItem(
                                    l10n.translate('mission_menu_duration'),
                                    Icons.timer,
                                    MissionCardQuickAction.duration,
                                  ),
                                  _missionQuickActionItem(
                                    l10n.translate('mission_menu_skills'),
                                    Icons.track_changes,
                                    MissionCardQuickAction.skills,
                                  ),
                                  _missionQuickActionItem(
                                    l10n.translate('mission_menu_move'),
                                    Icons.drive_file_move,
                                    MissionCardQuickAction.move,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (progress > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: AppTheme.border,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2196F3), // Azul Neon
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

PopupMenuItem<MissionCardQuickAction> _missionQuickActionItem(
  String label,
  IconData icon,
  MissionCardQuickAction action,
) {
  return PopupMenuItem<MissionCardQuickAction>(
    value: action,
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textPrimary),
        const SizedBox(width: 10),
        Text(label),
      ],
    ),
  );
}

class _ExpandedLoreBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ExpandedLoreBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
