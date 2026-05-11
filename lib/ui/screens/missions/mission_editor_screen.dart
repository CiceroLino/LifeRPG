import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/reward_point_advisor.dart';
import '../../../core/utils/xp_calculator.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/mission_reward_drop.dart';
import '../../../data/models/reward.dart';
import '../../../data/models/skill.dart';
import '../../../data/repositories/mission_reward_drop_repository.dart';
import '../../../providers/mission_provider.dart';
import '../../../providers/reward_provider.dart';
import '../../../providers/skill_provider.dart';
import '../../screens/map/location_picker_screen.dart';

class MissionEditorScreen extends StatefulWidget {
  final Mission? initial;
  final ValueChanged<Mission>? onSave;

  const MissionEditorScreen({super.key, this.initial, this.onSave});

  @override
  State<MissionEditorScreen> createState() => _MissionEditorScreenState();
}

class _MissionEditorScreenState extends State<MissionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  double _difficulty = 50;
  double _urgency = 50;
  double _fear = 30;

  DateTime? _dueDate;
  DateTime? _reminderAt;
  String _recurrence = 'once';
  int? _parentMissionId;
  int _rewardPoints = 0;
  Set<int> _selectedSkillIds = {};
  MissionLocationSelection? _location;
  List<MissionRewardDrop> _rewardDrops = [];
  final MissionRewardDropRepository _dropRepository =
      MissionRewardDropRepository();

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _titleController = TextEditingController(text: m?.title ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _difficulty = (m?.difficulty ?? 50).toDouble();
    _urgency = (m?.urgency ?? 50).toDouble();
    _fear = (m?.fear ?? 30).toDouble();
    _dueDate = m?.dueDate;
    _reminderAt = m?.reminderAt;
    _recurrence = m?.recurrenceType ?? 'once';
    _parentMissionId = m?.parentMissionId;
    _rewardPoints = m?.rewardPoints ?? 0;
    _selectedSkillIds = {...(m?.skillIds ?? const <int>[])};
    if (m?.latitude != null && m?.longitude != null) {
      _location = MissionLocationSelection(
        name: m?.locationName ?? 'Local da missão',
        latitude: m!.latitude!,
        longitude: m.longitude!,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SkillProvider>().loadSkills();
      context.read<MissionProvider>().loadMissions();
      context.read<RewardProvider>().loadRewards();
      _loadRewardDrops();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skillProvider = context.watch<SkillProvider>();
    final rewardProvider = context.watch<RewardProvider>();
    final missionProvider = context.watch<MissionProvider>();
    final allMissions = missionProvider.missions;
    final availableParentMissions = allMissions
        .where((m) => m.id != widget.initial?.id)
        .toList();
    final selectedSkills = skillProvider.skills
        .where((skill) => _selectedSkillIds.contains(skill.id))
        .toList();
    final xpPreview = _xpPreview;
    final recommendedRewardPoints = _recommendedRewardPoints;

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
                  decoration: const InputDecoration(labelText: 'Task'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Details'),
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
                  attribute: MissionAttribute.difficulty,
                  icon: FontAwesomeIcons.personHiking,
                  value: _difficulty,
                  activeColor: const Color(0xFF00BCD4),
                  onChanged: (v) => setState(() => _difficulty = v),
                ),
                AttributeSliderRow(
                  label: 'Urgency',
                  attribute: MissionAttribute.urgency,
                  icon: FontAwesomeIcons.personRunning,
                  value: _urgency,
                  activeColor: const Color(0xFF2196F3),
                  onChanged: (v) => setState(() => _urgency = v),
                ),
                AttributeSliderRow(
                  label: 'Fear',
                  attribute: MissionAttribute.fear,
                  icon: FontAwesomeIcons.mask,
                  value: _fear,
                  activeColor: const Color(0xFF673AB7),
                  onChanged: (v) => setState(() => _fear = v),
                ),
                const SizedBox(height: 8),
                _StrategyPreview(
                  icon: Icons.stars,
                  label: 'Calculated XP',
                  value: '$xpPreview XP',
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
                  value: selectedSkills.isEmpty
                      ? 'Select skills'
                      : selectedSkills.map((s) => s.name).join(', '),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickSkills(skillProvider.skills),
                ),
                const Divider(height: 16),
                _LinkRow(
                  label: 'Parent Mission',
                  value: _parentMissionId != null
                      ? _parentMissionTitle(availableParentMissions)
                      : 'None',
                  trailing: const Icon(Icons.expand_more),
                  onTap: () => _pickParentMission(availableParentMissions),
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
                const Divider(height: 16),
                _LinkRow(
                  label: 'Reminder',
                  value: _reminderAt == null
                      ? 'Not set'
                      : _reminderAt!.toLocal().toString().substring(0, 16),
                  leadingIcon: Icons.notifications_outlined,
                  onTap: _pickReminder,
                ),
                const Divider(height: 16),
                _LinkRow(
                  label: 'Location',
                  value: _locationLabel,
                  leadingIcon: Icons.location_on_outlined,
                  onTap: _pickLocation,
                ),
                if (_location != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _location = null),
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpar local'),
                    ),
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
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final value = await showDialog<int>(
                            context: context,
                            builder: (context) => _CircularValuePickerDialog(
                              initialValue: _rewardPoints,
                            ),
                          );
                          if (value != null) {
                            setState(() {
                              _rewardPoints = value;
                            });
                          }
                        },
                        child: Text('Set Reward Points ($_rewardPoints)'),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(
                          () => _rewardPoints = recommendedRewardPoints,
                        ),
                        child: Text('Use $recommendedRewardPoints RP'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Reward Drops',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _EditorRewardDrops(
                  drops: _rewardDrops,
                  rewards: rewardProvider.rewards,
                  onAdd: _pickRewardDrop,
                  onRemove: (drop) => setState(() => _rewardDrops.remove(drop)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int get _xpPreview => XPCalculator.calculateMissionXP(
    difficulty: _difficulty.round(),
    urgency: _urgency.round(),
    fear: _fear.round(),
  );

  int get _recommendedRewardPoints =>
      RewardPointAdvisor.recommendMissionRewardPoints(
        xpReward: _xpPreview,
        isChildMission: _parentMissionId != null,
        recurrenceType: _recurrence == 'once' ? null : _recurrence,
      );

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

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? _dueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? now),
    );
    if (!mounted || time == null) return;
    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<MissionLocationSelection>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: _location),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _location = result);
  }

  Future<void> _loadRewardDrops() async {
    final missionId = widget.initial?.id;
    if (missionId == null) return;
    final drops = await _dropRepository.getByMissionId(missionId);
    if (!mounted) return;
    setState(() => _rewardDrops = drops);
  }

  Future<void> _pickRewardDrop() async {
    final rewards = context.read<RewardProvider>().rewards;
    final result = await showDialog<MissionRewardDrop>(
      context: context,
      builder: (context) => _EditorRewardDropDialog(rewards: rewards),
    );
    if (result == null) return;
    setState(() => _rewardDrops = [..._rewardDrops, result]);
  }

  String get _locationLabel {
    final location = _location;
    if (location == null) return 'Not set';
    final name = location.name;
    if (name != null && name.trim().isNotEmpty) return name;
    return '${location.latitude.toStringAsFixed(4)}, '
        '${location.longitude.toStringAsFixed(4)}';
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

  String _parentMissionTitle(List<Mission> missions) {
    final match = missions.where((m) => m.id == _parentMissionId);
    if (match.isEmpty) {
      return 'Mission #$_parentMissionId';
    }
    return match.first.title;
  }

  Future<void> _pickSkills(List<Skill> skills) async {
    if (skills.isEmpty) return;
    final selected = {..._selectedSkillIds};

    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecionar Skills',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((skill) {
                      return FilterChip(
                        label: Text(skill.name),
                        selected:
                            skill.id != null && selected.contains(skill.id),
                        onSelected: (enabled) {
                          if (skill.id == null) return;
                          setSheetState(() {
                            if (enabled) {
                              selected.add(skill.id!);
                            } else {
                              selected.remove(skill.id!);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          selected.clear();
                          setSheetState(() {});
                        },
                        child: const Text('Limpar'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, selected),
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedSkillIds = result;
      });
    }
  }

  Future<void> _pickParentMission(List<Mission> missions) async {
    final result = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('None'),
              onTap: () => Navigator.pop(context, null),
            ),
            ...missions.map(
              (mission) => ListTile(
                title: Text(mission.title),
                subtitle: mission.id != null
                    ? Text('Mission #${mission.id}')
                    : null,
                trailing: mission.id == _parentMissionId
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, mission.id),
              ),
            ),
          ],
        );
      },
    );

    setState(() {
      _parentMissionId = result;
    });
  }

  Future<void> _save() async {
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
      xpReward: _xpPreview,
      rewardPoints: _rewardPoints,
      status: base?.status ?? 'active',
      dueDate: _dueDate,
      reminderAt: _reminderAt,
      estimatedDuration: base?.estimatedDuration,
      isRecurring: _recurrence != 'once',
      recurrenceType: _recurrence == 'once' ? null : _recurrence,
      recurrenceInterval: base?.recurrenceInterval,
      lastCompletedAt: base?.lastCompletedAt,
      streak: base?.streak ?? 0,
      parentMissionId: _parentMissionId,
      orderIndex: base?.orderIndex ?? 0,
      icon: base?.icon,
      emoji: base?.emoji,
      createdAt: base?.createdAt,
      updatedAt: DateTime.now(),
      completedAt: base?.completedAt,
      locationName: _location?.name,
      latitude: _location?.latitude,
      longitude: _location?.longitude,
      skillIds: _selectedSkillIds.toList(),
    );

    if (mission.id != null) {
      await _dropRepository.replaceForMission(
        mission.id!,
        _rewardDrops
            .map((drop) => drop.copyWith(missionId: mission.id!))
            .toList(),
      );
    }

    widget.onSave?.call(mission);
    if (!mounted) return;
    Navigator.pop(context, mission);
  }
}

class _EditorRewardDrops extends StatelessWidget {
  final List<MissionRewardDrop> drops;
  final List<Reward> rewards;
  final VoidCallback onAdd;
  final ValueChanged<MissionRewardDrop> onRemove;

  const _EditorRewardDrops({
    required this.drops,
    required this.rewards,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final rewardById = {
      for (final reward in rewards)
        if (reward.id != null) reward.id!: reward,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (drops.isEmpty)
          const Text(
            'Nenhum drop vinculado.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          )
        else
          ...drops.map((drop) {
            final reward = rewardById[drop.rewardId];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_awesome, color: AppTheme.primary),
              title: Text(reward?.name ?? 'Reward #${drop.rewardId}'),
              subtitle: Text(
                '${drop.chancePercent}% de chance | qtd. ${drop.quantity}',
              ),
              trailing: IconButton(
                tooltip: 'Remover drop',
                onPressed: () => onRemove(drop),
                icon: const Icon(Icons.close),
              ),
            );
          }),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: rewards.isEmpty ? null : onAdd,
            icon: const Icon(Icons.add),
            label: Text(
              rewards.isEmpty
                  ? 'Cadastre uma recompensa antes'
                  : 'Adicionar drop',
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorRewardDropDialog extends StatefulWidget {
  final List<Reward> rewards;

  const _EditorRewardDropDialog({required this.rewards});

  @override
  State<_EditorRewardDropDialog> createState() =>
      _EditorRewardDropDialogState();
}

class _EditorRewardDropDialogState extends State<_EditorRewardDropDialog> {
  int? _rewardId;
  double _chance = 25;
  final _quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _rewardId = widget.rewards.isEmpty ? null : widget.rewards.first.id;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Drop da missão'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _rewardId,
            decoration: const InputDecoration(labelText: 'Recompensa'),
            items: widget.rewards
                .where((reward) => reward.id != null)
                .map(
                  (reward) => DropdownMenuItem(
                    value: reward.id,
                    child: Text(reward.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _rewardId = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Chance'),
              Expanded(
                child: Slider(
                  value: _chance,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_chance.round()}%',
                  onChanged: (value) => setState(() => _chance = value),
                ),
              ),
              SizedBox(width: 42, child: Text('${_chance.round()}%')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantidade'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _rewardId == null
              ? null
              : () {
                  Navigator.pop(
                    context,
                    MissionRewardDrop(
                      missionId: 0,
                      rewardId: _rewardId!,
                      chancePercent: _chance.round(),
                      quantity:
                          int.tryParse(_quantityController.text.trim()) ?? 1,
                    ),
                  );
                },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

class AttributeSliderRow extends StatelessWidget {
  final String label;
  final MissionAttribute attribute;
  final IconData icon;
  final double value;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const AttributeSliderRow({
    super.key,
    required this.label,
    required this.attribute,
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
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${value.round()}%',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: activeColor,
                    inactiveTrackColor: AppTheme.border,
                    thumbColor: activeColor,
                    overlayColor: activeColor.withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${value.toStringAsFixed(0)}%',
                    onChanged: onChanged,
                  ),
                ),
                Text(
                  '${XPCalculator.attributeBand(value.round())}: '
                  '${XPCalculator.attributeGuideLabel(attribute, value.round())}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: activeColor, size: 20),
        ],
      ),
    );
  }
}

class _StrategyPreview extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StrategyPreview({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
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
              Icon(leadingIcon, color: AppTheme.textSecondary, size: 18),
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
            ?trailing,
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
                border: Border.all(color: AppTheme.primary, width: 3),
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
