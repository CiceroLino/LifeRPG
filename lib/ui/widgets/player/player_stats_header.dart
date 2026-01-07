import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/player.dart';
import '../../../core/utils/xp_calculator.dart';

class PlayerStatsHeader extends StatelessWidget {
  final Player player;
  final int maxHp;
  final ValueChanged<int>? onTabChanged;
  final bool showTabs;

  const PlayerStatsHeader({
    super.key,
    required this.player,
    this.maxHp = 100,
    this.onTabChanged,
    this.showTabs = false,
  });

  /// Calcula o XP atual no nível
  int get currentXp =>
      XPCalculator.xpInCurrentLevel(player.totalXP, player.level);

  /// Calcula o XP necessário para o próximo nível
  int get nextLevelXp => XPCalculator.xpForNextLevel(player.level);

  /// Calcula o progresso do XP (0.0 a 1.0)
  double get xpProgress {
    if (nextLevelXp == 0) return 0.0;
    return (currentXp / nextLevelXp).clamp(0.0, 1.0);
  }

  /// Calcula o progresso do HP/Energy (0.0 a 1.0)
  double get hpProgress {
    return (player.currentEnergy / maxHp).clamp(0.0, 1.0);
  }

  /// Formata números grandes com vírgulas
  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// Formata o timer restante (placeholder - pode ser implementado com lógica real)
  String _formatTimeLeft() {
    // TODO: Implementar lógica real de timer baseada em regeneração de energia
    return '04:02:28 left';
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: AppTheme.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SEÇÃO SUPERIOR: Info do Jogador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar (Esquerda)
                _buildAvatar(),
                const SizedBox(width: 12),

                // Nome e Título (Centro)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        player.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pontos e Nível (Direita)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Linha Superior: Diamante + Pontos
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.gem,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${player.rewardPoints}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Linha Inferior: Nível GIGANTE e AMARELO
                    Text(
                      '${player.level}',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFD700), // Gold/Amber
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // SEÇÃO DO MEIO: Barras de Progresso Stacked
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra de XP (Cima)
                _buildProgressBar(
                  progress: xpProgress,
                  backgroundColor: const Color(0xFF424242),
                  fillColor: const Color(0xFF2196F3), // Azul Neon
                  height: 20,
                  label:
                      '${_formatNumber(currentXp)} / ${_formatNumber(nextLevelXp)}',
                  labelAlignment: Alignment.centerLeft,
                  labelPadding: const EdgeInsets.only(left: 8),
                ),

                // Barra de HP (Baixo) - sem espaçamento
                _buildProgressBar(
                  progress: hpProgress,
                  backgroundColor: const Color(0xFF424242),
                  fillColor: AppTheme.accentRed, // Vermelho
                  height: 20,
                  label: '${player.currentEnergy}/$maxHp',
                  labelAlignment: Alignment.centerLeft,
                  labelPadding: const EdgeInsets.only(left: 8),
                  rightLabel: _formatTimeLeft(),
                  rightLabelPadding: const EdgeInsets.only(right: 8),
                ),
              ],
            ),
          ),

          // SEÇÃO INFERIOR: Tabs/Filtros (apenas se showTabs == true)
          if (showTabs)
            Container(
              color: AppTheme.surface,
              child: TabBar(
                onTap: (index) => onTabChanged?.call(index),
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelColor: AppTheme.textPrimary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                tabs: const [
                  Tab(text: 'PLAN'),
                  Tab(text: 'ALL'),
                  Tab(text: 'NEXT'),
                  Tab(text: 'OVERDUE'),
                  Tab(text: 'TODAY'),
                  Tab(text: 'TOMORROW'),
                ],
              ),
            ),
        ],
      ),
    );

    // Se showTabs é true, precisa do DefaultTabController
    if (showTabs) {
      return DefaultTabController(length: 6, child: content);
    }

    return content;
  }

  /// Constrói o avatar
  Widget _buildAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: player.avatarPath != null && player.avatarPath!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildAvatarImage(player.avatarPath!),
            )
          : _buildAvatarPlaceholder(),
    );
  }

  /// Constrói a imagem do avatar suportando assets e arquivos customizados
  Widget _buildAvatarImage(String avatarPath) {
    // Se for um caminho absoluto (arquivo customizado)
    if (avatarPath.startsWith('/') || avatarPath.startsWith('file://')) {
      try {
        final filePath = avatarPath.replaceFirst('file://', '');
        final file = File(filePath);
        if (file.existsSync()) {
          if (filePath.endsWith('.svg')) {
            return SvgPicture.file(
              file,
              fit: BoxFit.cover,
              colorFilter: const ColorFilter.mode(
                AppTheme.textPrimary,
                BlendMode.srcIn,
              ),
              placeholderBuilder: (_) => _buildAvatarPlaceholder(),
              errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
            );
          } else {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
            );
          }
        }
      } catch (e) {
        // Se houver erro, retorna placeholder
        return _buildAvatarPlaceholder();
      }
    }

    // Se for um asset (SVG ou imagem)
    if (avatarPath.endsWith('.svg')) {
      return SvgPicture.asset(
        avatarPath,
        fit: BoxFit.cover,
        colorFilter: const ColorFilter.mode(
          AppTheme.textPrimary,
          BlendMode.srcIn,
        ),
        placeholderBuilder: (_) => _buildAvatarPlaceholder(),
        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
      );
    } else {
      return Image.asset(
        avatarPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
      );
    }
  }

  /// Placeholder do avatar
  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  /// Constrói uma barra de progresso customizada com texto sobreposto
  Widget _buildProgressBar({
    required double progress,
    required Color backgroundColor,
    required Color fillColor,
    required double height,
    required String label,
    required Alignment labelAlignment,
    required EdgeInsets labelPadding,
    String? rightLabel,
    EdgeInsets? rightLabelPadding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Fundo
            Container(
              width: double.infinity,
              height: height,
              color: backgroundColor,
            ),
            // Preenchimento (Progresso)
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(height: height, color: fillColor),
            ),
            // Texto sobreposto (Esquerda)
            Positioned.fill(
              child: Align(
                alignment: labelAlignment,
                child: Padding(
                  padding: labelPadding,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 0),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Texto sobreposto (Direita) - se fornecido
            if (rightLabel != null)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: rightLabelPadding ?? EdgeInsets.zero,
                    child: Text(
                      rightLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 0),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
