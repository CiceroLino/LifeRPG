import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum GameSnackBarType { success, error, reward, info }

class GameSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    GameSnackBarType type = GameSnackBarType.info,
  }) {
    final (icon, color, defaultTitle) = switch (type) {
      GameSnackBarType.success => (
        Icons.check_circle_outline,
        AppTheme.successGreen,
        'Success',
      ),
      GameSnackBarType.error => (
        Icons.warning_amber_rounded,
        AppTheme.accentRed,
        'Error',
      ),
      GameSnackBarType.reward => (
        Icons.auto_awesome,
        AppTheme.accentAmber,
        'Reward',
      ),
      GameSnackBarType.info => (Icons.info_outline, AppTheme.primary, 'Info'),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: color, width: 1.4),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? defaultTitle,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
