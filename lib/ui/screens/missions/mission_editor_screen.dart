import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/mission.dart';

class MissionEditorScreen extends StatefulWidget {
  final Mission? initial;
  final ValueChanged<Mission>? onSave;

  const MissionEditorScreen({
    super.key,
    this.initial,
    this.onSave,
  });

  @override
  State<MissionEditorScreen> createState() => _MissionEditorScreenState();
}

class _MissionEditorScreenState extends State<MissionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  double _difficulty = 3;
  double _urgency = 3;
  double _fear = 2;

  DateTime? _dueDate;
  String _recurrence = 'once';

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _titleController = TextEditingController(text: m?.title ?? '');
    _descriptionController =
        TextEditingController(text: m?.description ?? '');
    _difficulty = (m?.difficulty ?? 3).toDouble();
    _urgency = (m?.urgency ?? 3).toDouble();
    _fear = (m?.fear ?? 2).toDouble();
    _dueDate = m?.dueDate;
    _recurrence = m?.recurrenceType ?? 'once';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Attributes',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                AttributeSliderRow(
                  label: 'Difficulty',
                  icon: FontAwesomeIcons.personHiking,
                  value: _difficulty,
                  activeColor: const Color(0xFF00BCD4),
                  onChanged: (v) => setState(() => _difficulty = v),
                ),
                AttributeSliderRow(
                  label: 'Urgency',
                  icon: FontAwesomeIcons.personRunning,
                  value: _urgency,
                  activeColor: const Color(0xFF2196F3),
                  onChanged: (v) => setState(() => _urgency = v),
                ),
                AttributeSliderRow(
                  label: 'Fear',
                  icon: FontAwesomeIcons.mask,
                  value: _fear,
                  activeColor: const Color(0xFF673AB7),
                  onChanged: (v) => setState(() => _fear = v),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Links',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _LinkRow(
                  label: 'Skills',
                  value: 'Select skills',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: abrir seletor de skills
                  },
                ),
                const Divider(height: 16),
                _LinkRow(
                  label: 'Parent Mission',
                  value: widget.initial?.parentMissionId != null
                      ? 'Mission #${widget.initial!.parentMissionId}'
                      : 'None',
                  trailing: const Icon(Icons.expand_more),
                  onTap: () {
                    // TODO: abrir seletor de parent mission
                  },
                ),
                const Divider(height: 16),
                _LinkRow(
                  label: 'Date Due',
                  value: _dueDate == null
                      ? 'Not set'
                      : _dueDate!.toLocal().toString().split(' ').first,
                  leadingIcon: Icons.calendar_today,
                  onTap: _pickDate,
                ),
                _LinkRow(
                  label: 'Repetition',
                  value: _recurrenceLabel(_recurrence),
                  leadingIcon: Icons.repeat,
                  onTap: _pickRecurrence,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Reward',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () async {
                      final value = await showDialog<int>(
                        context: context,
                        builder: (context) => const _CircularValuePickerDialog(
                          initialValue: 10,
                        ),
                      );
                      if (value != null) {
                        // TODO: integrar com rewardPoints se desejar
                      }
                    },
                    child: const Text('Set Reward Points'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickRecurrence() async {
    const options = [
      'once',
      'daily',
      'weekly',
      'monthly',
      'yearly',
      'continuous',
    ];
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: options
              .map(
                (o) => ListTile(
                  title: Text(_recurrenceLabel(o)),
                  onTap: () => Navigator.pop(context, o),
                ),
              )
              .toList(),
        );
      },
    );
    if (value != null) {
      setState(() => _recurrence = value);
    }
  }

  String _recurrenceLabel(String value) {
    switch (value) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      case 'continuous':
        return 'Continuous';
      default:
        return 'Once';
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.initial;
    final mission = Mission(
      id: base?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      difficulty: _difficulty.round(),
      urgency: _urgency.round(),
      fear: _fear.round(),
      energyRequired: base?.energyRequired ?? 1,
      xpReward: base?.xpReward ?? 10,
      rewardPoints: base?.rewardPoints ?? 0,
      status: base?.status ?? 'active',
      dueDate: _dueDate,
      estimatedDuration: base?.estimatedDuration,
      isRecurring: _recurrence != 'once',
      recurrenceType: _recurrence == 'once' ? null : _recurrence,
      recurrenceInterval: base?.recurrenceInterval,
      lastCompletedAt: base?.lastCompletedAt,
      streak: base?.streak ?? 0,
      parentMissionId: base?.parentMissionId,
      orderIndex: base?.orderIndex ?? 0,
      icon: base?.icon,
      emoji: base?.emoji,
      createdAt: base?.createdAt,
      updatedAt: DateTime.now(),
      completedAt: base?.completedAt,
      skillIds: base?.skillIds ?? const [],
    );

    widget.onSave?.call(mission);
    Navigator.pop(context, mission);
  }
}

class AttributeSliderRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const AttributeSliderRow({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: activeColor,
                inactiveTrackColor: AppTheme.border,
                thumbColor: activeColor,
                overlayColor: activeColor.withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: value,
                min: 1,
                max: 5,
                divisions: 4,
                label: value.toStringAsFixed(0),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            icon,
            color: activeColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback onTap;

  const _LinkRow({
    required this.label,
    required this.value,
    this.leadingIcon,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _CircularValuePickerDialog extends StatefulWidget {
  final int initialValue;

  const _CircularValuePickerDialog({required this.initialValue});

  @override
  State<_CircularValuePickerDialog> createState() =>
      _CircularValuePickerDialogState();
}

class _CircularValuePickerDialogState
    extends State<_CircularValuePickerDialog> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text(
        'Set Reward Points',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: SizedBox(
        width: 220,
        height: 160,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary,
                  width: 3,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      color: AppTheme.primary,
                      onPressed: () {
                        setState(() {
                          if (_value > 0) _value--;
                        });
                      },
                    ),
                    Text(
                      '$_value',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      color: AppTheme.primary,
                      onPressed: () {
                        setState(() {
                          _value++;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _value),
          child: const Text('OK'),
        ),
      ],
    );
  }
}


