import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showCompleted = true;
  bool _notifications = true;
  bool _soundEffects = false;
  bool _vibration = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SettingsSectionHeader('System'),
          _SettingsCheckboxTile(
            title: 'Show completed',
            subtitle: 'Display completed tasks in lists',
            value: _showCompleted,
            onChanged: (value) => setState(() => _showCompleted = value ?? true),
          ),
          _SettingsCheckboxTile(
            title: 'Notifications',
            subtitle: 'Enable push notifications',
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value ?? true),
          ),
          const Divider(height: 1),
          const _SettingsSectionHeader('Interface'),
          _SettingsCheckboxTile(
            title: 'Compact view',
            subtitle: 'Use smaller spacing and fonts',
            value: false,
            onChanged: (value) {},
          ),
          const Divider(height: 1),
          const _SettingsSectionHeader('Sounds'),
          _SettingsCheckboxTile(
            title: 'Sound effects',
            subtitle: 'Play sounds for actions',
            value: _soundEffects,
            onChanged: (value) => setState(() => _soundEffects = value ?? false),
          ),
          _SettingsCheckboxTile(
            title: 'Vibration',
            subtitle: 'Haptic feedback on actions',
            value: _vibration,
            onChanged: (value) => setState(() => _vibration = value ?? true),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () {},
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
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
          fontSize: 14,
        ),
      ),
      activeColor: AppTheme.primary,
      checkColor: AppTheme.background,
    );
  }
}


