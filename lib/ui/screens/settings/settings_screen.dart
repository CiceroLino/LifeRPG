import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/mission_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/skill_provider.dart';

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
    return Consumer2<SettingsProvider, PlayerProvider>(
      builder: (context, settings, playerProvider, _) {
        final l10n = AppLocalizations.of(context);
        if (settings.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final player = playerProvider.player;
        if (player == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            ListView(
              children: [
                _SettingsSectionHeader(
                  l10n.translate('language').toUpperCase(),
                ),
                _SettingsActionTile(
                  title: l10n.translate('language'),
                  subtitle: _getLanguageName(settings.language),
                  icon: Icons.language,
                  onTap: () => _showLanguageDialog(context, settings),
                ),
                const Divider(height: 1),
                _SettingsSectionHeader(l10n.translate('sounds')),
                _SettingsCheckboxTile(
                  title: l10n.translate('sound_effects'),
                  subtitle: l10n.translate('play_sounds_actions'),
                  value: settings.soundEffectsEnabled,
                  onChanged: (value) =>
                      settings.setSoundEffectsEnabled(value ?? false),
                ),
                _SettingsCheckboxTile(
                  title: l10n.translate('notification_sounds'),
                  subtitle: l10n.translate('play_sounds_notifications'),
                  value: settings.notificationSoundsEnabled,
                  onChanged: (value) =>
                      settings.setNotificationSoundsEnabled(value ?? true),
                ),
                const Divider(height: 1),
                _SettingsSectionHeader(l10n.translate('data_backup')),
                _SettingsActionTile(
                  title: l10n.translate('export_database'),
                  subtitle: l10n.translate('save_data'),
                  icon: Icons.upload_file,
                  onTap: _isExporting
                      ? null
                      : () async => await _handleExport(context, settings),
                ),
                _SettingsActionTile(
                  title: l10n.translate('import_database'),
                  subtitle: l10n.translate('restore_data'),
                  icon: Icons.download,
                  onTap: _isImporting
                      ? null
                      : () async => await _handleImport(context, settings),
                ),
                const Divider(height: 1),
                _SettingsSectionHeader(l10n.translate('system')),
                _SettingsCheckboxTile(
                  title: l10n.translate('enable_notifications'),
                  subtitle: l10n.translate('receive_reminders'),
                  value: settings.notificationsEnabled,
                  onChanged: (value) =>
                      settings.setNotificationsEnabled(value ?? true),
                ),
                _SettingsCheckboxTile(
                  title: l10n.translate('start_week_monday'),
                  subtitle: l10n.translate('calendar_formatting'),
                  value: settings.startWeekOnMonday,
                  onChanged: (value) =>
                      settings.setStartWeekOnMonday(value ?? false),
                ),
                _SettingsCheckboxTile(
                  title: l10n.translate('use_24h_clock'),
                  subtitle: l10n.translate('use_24h_format'),
                  value: settings.use24HourFormat,
                  onChanged: (value) =>
                      settings.setUse24HourFormat(value ?? false),
                ),
                const Divider(height: 1),
                _SettingsSectionHeader(l10n.translate('interface')),
                _SettingsCheckboxTile(
                  title: l10n.translate('show_xp_bar'),
                  subtitle: l10n.translate('display_xp_bar'),
                  value: settings.showXpBar,
                  onChanged: (value) => settings.setShowXpBar(value ?? true),
                ),
                const Divider(height: 1),
                _SettingsSectionHeader(l10n.translate('energy').toUpperCase()),
                ListTile(
                  title: Text(
                    l10n.translate('energy_mode'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    l10n.translate('energy_mode_subtitle'),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  trailing: DropdownButton<String>(
                    value: player.energyMode == 'auto' ? 'auto' : 'manual',
                    dropdownColor: AppTheme.surface,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(
                        value: 'manual',
                        child: Text(l10n.translate('manual_mode')),
                      ),
                      DropdownMenuItem(
                        value: 'auto',
                        child: Text(l10n.translate('automatic_mode')),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      await playerProvider.setEnergyMode(value);
                    },
                  ),
                ),
                if (player.energyMode == 'auto') ...[
                  _SettingsActionTile(
                    title: l10n.translate('wake_up_time'),
                    subtitle: player.wakeUpTime ?? l10n.translate('not_set'),
                    icon: Icons.wb_sunny_outlined,
                    onTap: () async => _pickWakeUpTime(context, playerProvider),
                  ),
                  _SettingsActionTile(
                    title: l10n.translate('sleep_time'),
                    subtitle: player.sleepTime ?? l10n.translate('not_set'),
                    icon: Icons.nightlight_round,
                    onTap: () async => _pickSleepTime(context, playerProvider),
                  ),
                ],
                const Divider(height: 1),
                _SettingsSectionHeader(l10n.translate('reset_section')),
                _SettingsDangerTile(
                  title: l10n.translate('reset_character'),
                  color: Colors.orange,
                  onTap: () => _showResetCharacterDialog(context, settings),
                ),
                _SettingsDangerTile(
                  title: l10n.translate('factory_reset'),
                  color: AppTheme.accentRed,
                  onTap: () => _showFactoryResetDialog(context, settings),
                ),
                const SizedBox(height: 32),
              ],
            ),
            if (_isExporting || _isImporting)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickWakeUpTime(
    BuildContext context,
    PlayerProvider playerProvider,
  ) async {
    final player = playerProvider.player;
    if (player == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _parseTime(player.wakeUpTime) ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;

    final value = _formatTime(picked);
    if (value == player.sleepTime) {
      _showScheduleError();
      return;
    }
    await playerProvider.setWakeUpTime(value);
  }

  Future<void> _pickSleepTime(
    BuildContext context,
    PlayerProvider playerProvider,
  ) async {
    final player = playerProvider.player;
    if (player == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _parseTime(player.sleepTime) ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (picked == null) return;

    final value = _formatTime(picked);
    if (value == player.wakeUpTime) {
      _showScheduleError();
      return;
    }
    await playerProvider.setSleepTime(value);
  }

  void _showScheduleError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('wake_sleep_times_different'),
        ),
        backgroundColor: AppTheme.accentRed,
      ),
    );
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _handleExport(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cancelledMessage = l10n.translate('backup_export_cancelled');
    final successMessage = l10n.translate('backup_created');
    final errorMessage = l10n.translate('error_creating_backup');

    try {
      final success = await settings.exportData();
      if (!mounted) {
        return;
      }
      if (!success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(cancelledMessage),
            backgroundColor: AppTheme.textSecondary,
          ),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$errorMessage: ${e.toString()}'),
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

  Future<void> _handleImport(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          AppLocalizations.of(context).translate('import_backup'),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context).translate('replace_all_data'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context).translate('import'),
              style: const TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isImporting = true);

    try {
      final message = await settings.importData();
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
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
            context: this.context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text(
                AppLocalizations.of(context).translate('restart_required'),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              content: Text(
                AppLocalizations.of(context).translate('restart_message'),
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context).translate('ok'),
                    style: const TextStyle(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(this.context).translate('error_importing')}: ${e.toString()}',
            ),
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
      case 'pt_BR':
        return 'Português (Brasil)';
      case 'es':
        return 'Español';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          AppLocalizations.of(context).translate('select_language'),
          style: const TextStyle(color: AppTheme.textPrimary),
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
              language: 'pt_BR',
              name: 'Português (Brasil)',
              currentLanguage: settings.language,
              onSelect: () {
                settings.setLanguage('pt_BR');
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
          ],
        ),
      ),
    );
  }

  void _showResetCharacterDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          AppLocalizations.of(context).translate('reset_character_title'),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context).translate('reset_character_message'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await settings.resetCharacter();
              if (!context.mounted) return;
              await context.read<PlayerProvider>().loadPlayer();
              if (!context.mounted) return;
              Navigator.pop(context);
              if (!mounted) return;
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      this.context,
                    ).translate('character_stats_reset'),
                  ),
                ),
              );
            },
            child: Text(
              AppLocalizations.of(context).translate('reset_button'),
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showFactoryResetDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          AppLocalizations.of(context).translate('factory_reset_title'),
          style: const TextStyle(color: AppTheme.accentRed),
        ),
        content: Text(
          AppLocalizations.of(context).translate('factory_reset_message'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final playerProvider = context.read<PlayerProvider>();
              final missionProvider = context.read<MissionProvider>();
              final skillProvider = context.read<SkillProvider>();
              final navigator = Navigator.of(context);
              await settings.factoryReset();
              await playerProvider.loadPlayer();
              await missionProvider.loadMissions();
              await skillProvider.loadSkills();
              navigator.pop();
              if (!mounted) return;
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      this.context,
                    ).translate('factory_reset_completed'),
                  ),
                  backgroundColor: AppTheme.accentRed,
                ),
              );
            },
            child: Text(
              AppLocalizations.of(context).translate('wipe_all_data'),
              style: const TextStyle(
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
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
        color: onTap != null
            ? AppTheme.textSecondary
            : AppTheme.textSecondary.withValues(alpha: 0.5),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: onTap != null
              ? AppTheme.textPrimary
              : AppTheme.textPrimary.withValues(alpha: 0.5),
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: onTap != null
              ? AppTheme.textSecondary
              : AppTheme.textSecondary.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: onTap != null
            ? AppTheme.textSecondary
            : AppTheme.textSecondary.withValues(alpha: 0.5),
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
      trailing: Icon(Icons.warning, color: color),
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
