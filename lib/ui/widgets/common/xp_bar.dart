import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/theme/app_theme.dart';

class XPBar extends StatelessWidget {
  final int currentXP;
  final int xpNeeded;
  final double height;
  final bool showLabel;

  const XPBar({
    super.key,
    required this.currentXP,
    required this.xpNeeded,
    this.height = 24,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentXP / xpNeeded;

    return LinearPercentIndicator(
      animation: true,
      lineHeight: height,
      animationDuration: 1000,
      percent: progress.clamp(0.0, 1.0),
      center: showLabel
          ? Text(
              '$currentXP / $xpNeeded XP',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
      linearStrokeCap: LinearStrokeCap.roundAll,
      progressColor: AppTheme.xpBlue,
      backgroundColor: Colors.grey[300],
      barRadius: const Radius.circular(12),
    );
  }
}