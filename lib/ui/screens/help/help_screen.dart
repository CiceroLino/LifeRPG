import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  void _showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Column(
          children: [
            Icon(
              Icons.games,
              size: 64,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 16),
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Version 2.3.5',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '© 2025 LifeRPG Team\nAll rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: AppTheme.primary),
            ),
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
            applicationVersion: '2.3.5',
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
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView(
        children: [
          _HelpListTile(
            icon: Icons.book,
            title: 'Manual',
            onTap: () {},
          ),
          _HelpListTile(
            icon: Icons.bug_report,
            title: 'Report Bugs',
            onTap: () {},
          ),
          _HelpListTile(
            icon: Icons.feedback,
            title: 'Send Feedback',
            onTap: () {},
          ),
          _HelpListTile(
            icon: Icons.translate,
            title: 'Translate',
            onTap: () {},
          ),
          const Divider(height: 1),
          _HelpListTile(
            icon: Icons.description,
            title: 'Credits/Licenses',
            onTap: () => _showLicensesScreen(context),
          ),
          _HelpListTile(
            icon: Icons.info,
            title: 'Version Info',
            onTap: () => _showVersionDialog(context),
          ),
        ],
      ),
    );
  }
}

class _HelpListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HelpListTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }
}


