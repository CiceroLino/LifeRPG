import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../widgets/common/game_snack_bar.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, _) {
        final l10n = AppLocalizations.of(context);
        final minutes = provider.plannedMinutes;
        final remaining = _formatTime(provider.remainingSeconds);
        final xpPreview = minutes;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Icon(
                          Icons.hourglass_bottom,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('focus_quest'),
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              l10n.translate('pomodoro_ritual'),
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RewardBadge(label: '+$xpPreview XP'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      remaining,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: provider.progress.clamp(0, 1),
                      backgroundColor: AppTheme.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${l10n.translate('quest_length')}: $minutes min',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    min: 5,
                    max: 240,
                    divisions: 47,
                    value: minutes.clamp(5, 240).toDouble(),
                    label: '$minutes min',
                    onChanged: provider.isRunning
                        ? null
                        : (value) => provider.setPlannedMinutes(
                            (value / 5).round() * 5,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [25, 50, 90, 120, 240]
                        .map(
                          (value) => ChoiceChip(
                            label: Text('${value}m'),
                            selected: minutes == value,
                            onSelected: provider.isRunning
                                ? null
                                : (_) => provider.setPlannedMinutes(value),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: provider.isCompleting
                              ? null
                              : provider.isRunning
                              ? provider.pause
                              : provider.start,
                          icon: Icon(
                            provider.isRunning ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(
                            provider.isRunning
                                ? l10n.translate('pause')
                                : l10n.translate('start'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: provider.reset,
                        icon: const Icon(Icons.replay),
                        tooltip: l10n.translate('reset'),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: provider.isCompleting
                            ? null
                            : () => _complete(context, provider),
                        icon: const Icon(Icons.emoji_events_outlined),
                        tooltip: l10n.translate('complete_quest'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _RulePanel(),
          ],
        );
      },
    );
  }

  static Future<void> _complete(
    BuildContext context,
    PomodoroProvider provider,
  ) async {
    final result = await provider.completeNow();
    if (result == null || !context.mounted) return;
    await context.read<PlayerProvider>().loadPlayer();
    if (!context.mounted) return;
    GameSnackBar.show(
      context,
      title: AppLocalizations.of(context).translate('focus_quest_complete'),
      message:
          '+${result.xpGranted} ${AppLocalizations.of(context).translate('xp_earned')}',
      type: GameSnackBarType.success,
    );
  }

  static String _formatTime(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _RewardBadge extends StatelessWidget {
  final String label;

  const _RewardBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.accentAmber,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RulePanel extends StatelessWidget {
  const _RulePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.accentAmber, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate('focus_quest_rule'),
              style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
