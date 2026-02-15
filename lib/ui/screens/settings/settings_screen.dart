import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        if (settings.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            ListView(
              children: [
                const _SettingsSectionHeader('LANGUAGE'),
                _SettingsActionTile(
                  title: 'Language',
                  subtitle: _getLanguageName(settings.language),
                  icon: Icons.language,
                  onTap: () => _showLanguageDialog(context, settings),
                ),
                const Divider(height: 1),
                const _SettingsSectionHeader('SOUNDS'),
                _SettingsCheckboxTile(
                  title: 'Sound Effects',
                  subtitle: 'Play sounds for actions',
                  value: settings.soundEffectsEnabled,
                  onChanged: (value) => settings.setSoundEffectsEnabled(value ?? false),
                ),
                _SettingsCheckboxTile(
                  title: 'Notification Sounds',
                  subtitle: 'Play sounds for notifications',
                  value: settings.notificationSoundsEnabled,
                  onChanged: (value) => settings.setNotificationSoundsEnabled(value ?? true),
                ),
                const Divider(height: 1),
                const _SettingsSectionHeader('DATA & BACKUP'),
                _SettingsActionTile(
                  title: 'Export Database',
                  subtitle: 'Save your data to a file',
                  icon: Icons.upload_file,
                  onTap: _isExporting ? null : () async => await _handleExport(context, settings),
                ),
                _SettingsActionTile(
                  title: 'Import Database',
                  subtitle: 'Restore data from a file',
                  icon: Icons.download,
                  onTap: _isImporting ? null : () async => await _handleImport(context, settings),
                ),
                const Divider(height: 1),
                const _SettingsSectionHeader('SYSTEM'),
                _SettingsCheckboxTile(
                  title: 'Enable Notifications',
                  subtitle: 'Receive reminders and alerts',
                  value: settings.notificationsEnabled,
                  onChanged: (value) => settings.setNotificationsEnabled(value ?? true),
                ),
                _SettingsCheckboxTile(
                  title: 'Start week on Monday',
                  subtitle: 'Calendar and date formatting',
                  value: settings.startWeekOnMonday,
                  onChanged: (value) => settings.setStartWeekOnMonday(value ?? false),
                ),
                _SettingsCheckboxTile(
                  title: '24-Hour Clock',
                  subtitle: 'Use 24-hour time format',
                  value: settings.use24HourFormat,
                  onChanged: (value) => settings.setUse24HourFormat(value ?? false),
                ),
                const Divider(height: 1),
                const _SettingsSectionHeader('INTERFACE'),
                _SettingsCheckboxTile(
                  title: 'Show XP Bar',
                  subtitle: 'Display experience bar in header',
                  value: settings.showXpBar,
                  onChanged: (value) => settings.setShowXpBar(value ?? true),
                ),
                const Divider(height: 1),
                const _SettingsSectionHeader('RESET'),
                _SettingsDangerTile(
                  title: 'Reset Character Stats',
                  color: Colors.orange,
                  onTap: () => _showResetCharacterDialog(context, settings),
                ),
                _SettingsDangerTile(
                  title: 'Factory Reset / Wipe All',
                  color: AppTheme.accentRed,
                  onTap: () => _showFactoryResetDialog(context, settings),
                ),
                const SizedBox(height: 32),
              ],
            ),
            if (_isExporting || _isImporting)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleExport(BuildContext context, SettingsProvider settings) async {
    setState(() => _isExporting = true);

    try {
      await settings.exportData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating backup: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleImport(BuildContext context, SettingsProvider settings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Import Backup',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will replace ALL your current data with the backup file.\n\nAre you sure you want to continue?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Import',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);

    try {
      final message = await settings.importData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: message.toLowerCase().contains('success')
                ? AppTheme.successGreen
                : AppTheme.accentRed,
            duration: const Duration(seconds: 4),
          ),
        );

        if (message.toLowerCase().contains('success')) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text(
                'Restart Required',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: const Text(
                'Data has been restored successfully.\n\nPlease restart the application to load the restored data.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing backup: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Select Language',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              language: 'en',
              name: 'English',
              currentLanguage: settings.language,
              onSelect: () {
                settings.setLanguage('en');
                Navigator.pop(context);
              },
            ),
            _LanguageOption(
              language: 'pt',
              name: 'Português',
              currentLanguage: settings.language,
              onSelect: () {
                settings.setLanguage('pt');
                Navigator.pop(context);
              },
            ),
            _LanguageOption(
              language: 'es',
              name: 'Español',
              currentLanguage: settings.language,
              onSelect: () {
                settings.setLanguage('es');
                Navigator.pop(context);
              },
            ),
            _LanguageOption(
              language: 'fr',
              name: 'Français',
              currentLanguage: settings.language,
              onSelect: () {
                settings.setLanguage('fr');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResetCharacterDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Reset Character Stats',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will reset your character\'s level, XP, and stats to default values. Mission and skill data will be preserved.\n\nThis action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              settings.resetCharacter();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Character stats reset')),
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showFactoryResetDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Factory Reset',
          style: TextStyle(color: AppTheme.accentRed),
        ),
        content: const Text(
          'WARNING: This will permanently delete ALL your data including:\n\n• Character stats\n• All missions\n• All skills\n• Rewards and inventory\n• Settings\n\nThis action CANNOT be undone!',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              settings.factoryReset();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Factory reset completed'),
                  backgroundColor: AppTheme.accentRed,
                ),
              );
            },
            child: const Text(
              'WIPE ALL DATA',
              style: TextStyle(
                color: AppTheme.accentRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;

  const _SettingsSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsCheckboxTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _SettingsCheckboxTile({
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
      activeColor: AppTheme.primary,
      checkColor: AppTheme.background,
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _SettingsActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      leading: Icon(
        icon,
        color: onTap != null ? AppTheme.textSecondary : AppTheme.textSecondary.withOpacity(0.5),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: onTap != null ? AppTheme.textPrimary : AppTheme.textPrimary.withOpacity(0.5),
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: onTap != null ? AppTheme.textSecondary : AppTheme.textSecondary.withOpacity(0.5),
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: onTap != null ? AppTheme.textSecondary : AppTheme.textSecondary.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}

class _SettingsDangerTile extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _SettingsDangerTile({
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.warning,
        color: color,
      ),
      onTap: onTap,
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String language;
  final String name;
  final String currentLanguage;
  final VoidCallback onSelect;

  const _LanguageOption({
    required this.language,
    required this.name,
    required this.currentLanguage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = language == currentLanguage;
    
    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primary)
          : null,
      onTap: onSelect,
    );
  }
}



