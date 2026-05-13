import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'strategy_guide_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String _appVersion = '2.3.5';

  void _showComingSoon(BuildContext context, {required String feature}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature em breve.'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  void _showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Column(
          children: [
            const Icon(Icons.games, size: 64, color: AppTheme.primary),
            const SizedBox(height: 12),
            const Text(
              'LifeRPG',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Version $_appVersion',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2025 LifeRPG Team',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showLicensesScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppTheme.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppTheme.background,
              foregroundColor: AppTheme.textPrimary,
            ),
            cardColor: AppTheme.surface,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          child: const LicensePage(
            applicationName: 'LifeRPG',
            applicationVersion: _appVersion,
            applicationIcon: Icon(
              Icons.games,
              size: 48,
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuda')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          _HelpSection(
            icon: Icons.book,
            title: 'Guia de Estratégia',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StrategyGuideScreen(),
                ),
              );
            },
          ),
          _HelpSection(
            icon: Icons.bug_report,
            title: 'Reportar bug',
            onTap: () => _showComingSoon(context, feature: 'Reporte de bugs'),
          ),
          _HelpSection(
            icon: Icons.feedback,
            title: 'Enviar feedback',
            onTap: () =>
                _showComingSoon(context, feature: 'Envio de feedback'),
          ),
          _HelpSection(
            icon: Icons.translate,
            title: 'Idioma e localização',
            onTap: () => _showComingSoon(context, feature: 'Configuração de idioma'),
          ),
          const Divider(height: 1),
          _HelpSection(
            icon: Icons.description,
            title: 'Licenças',
            onTap: () => _showLicensesScreen(context),
          ),
          _HelpSection(
            icon: Icons.info_outline,
            title: 'Informações do app',
            onTap: () => _showVersionDialog(context),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HelpSection({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
