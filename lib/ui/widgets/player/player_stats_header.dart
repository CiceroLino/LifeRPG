import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PlayerStatsHeader extends StatelessWidget {
  final String name;
  final String title;
  final int level;
  final String xpLabel; // e.g. "2,640,295 / 2,701,000"
  final double xpProgress; // 0..1
  final String hpLabel; // e.g. "15/100"
  final double hpProgress; // 0..1
  final String avatarText;

  const PlayerStatsHeader({
    super.key,
    required this.name,
    required this.title,
    required this.level,
    required this.xpLabel,
    required this.xpProgress,
    required this.hpLabel,
    required this.hpProgress,
    this.avatarText = 'P',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(text: avatarText),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'LEVEL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '$level',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _LabeledBar(
            label: xpLabel,
            progress: xpProgress,
            color: AppTheme.primary,
            background: AppTheme.border,
            height: 10,
          ),
          const SizedBox(height: 6),
          _LabeledBar(
            label: hpLabel,
            progress: hpProgress,
            color: AppTheme.accentRed,
            background: AppTheme.border,
            height: 8,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String text;
  const _Avatar({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border),
        color: AppTheme.background,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _LabeledBar extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final Color background;
  final double height;

  const _LabeledBar({
    required this.label,
    required this.progress,
    required this.color,
    required this.background,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: background,
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0, 1),
            child: Container(
              height: height,
              color: color,
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

