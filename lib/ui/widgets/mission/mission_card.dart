import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/mission.dart';
import '../../screens/missions/mission_icon_assets.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback? onTap;
  final VoidCallback? onAddSubtask;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  final Future<void> Function(String status)? onStatusChanged;
  final VoidCallback? onEdit;
  final double progress; // 0.0 to 1.0

  const MissionCard({
    super.key,
    required this.mission,
    this.onTap,
    this.onAddSubtask,
    this.isExpanded = false,
    this.onToggleExpanded,
    this.onStatusChanged,
    this.onEdit,
    this.progress = 0.0,
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
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
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
    IconData defaultIcon = FontAwesomeIcons.bullseye;
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
    final priorityColor = _getPriorityColor();
    final cardColor = const Color(0xFF424242); // Slightly darker than surface

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
                                  : mission.estimatedDuration != null
                                  ? _formatDuration(mission.estimatedDuration)
                                  : 'No description available',
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
                              Icon(
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

                      if (isExpanded) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: const Key('mission-status-dropdown'),
                                initialValue: mission.status,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('Active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text('Completed'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'archived',
                                    child: Text('Archived'),
                                  ),
                                ],
                                onChanged: (value) async {
                                  if (value == null ||
                                      value == mission.status) {
                                    return;
                                  }
                                  await onStatusChanged?.call(value);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: onEdit,
                              child: const Text('Editar'),
                            ),
                          ],
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
