import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/skill.dart';
import '../../../providers/mission_provider.dart';
import '../../../providers/skill_provider.dart';
import '../../widgets/common/reward_picker_dialog.dart';

class MissionFormScreen extends StatefulWidget {
  const MissionFormScreen({super.key});

  @override
  State<MissionFormScreen> createState() => _MissionFormScreenState();
}

class _MissionFormScreenState extends State<MissionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController(text: '30');

  int _rewardPoints = 10;
  double _difficulty = 3;
  double _urgency = 3;
  double _fear = 2;
  DateTime? _dueDate;
  String _recurrence = 'once';
  int? _parentMissionId;
  final Set<int> _selectedSkills = {};
  String _iconAsset = _iconOptions.first;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SkillProvider>().loadSkills();
      context.read<MissionProvider>().loadMissions();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skillProvider = context.watch<SkillProvider>();
    final missions = context.watch<MissionProvider>().missions;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Missão')),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.check),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Missão (Título)'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Detalhes / Notas'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _Section(title: 'Parâmetros (XP)'),
            _SliderField(
              label: 'Dificuldade',
              value: _difficulty,
              onChanged: (v) => setState(() => _difficulty = v),
            ),
            _SliderField(
              label: 'Urgência',
              value: _urgency,
              onChanged: (v) => setState(() => _urgency = v),
            ),
            _SliderField(
              label: 'Medo',
              value: _fear,
              onChanged: (v) => setState(() => _fear = v),
            ),
            const SizedBox(height: 16),
            _Section(title: 'Skills'),
            if (skillProvider.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skillProvider.skills
                    .map(
                      (skill) => FilterChip(
                        label: Text(skill.name),
                        selected: _selectedSkills.contains(skill.id),
                        onSelected: (sel) => setState(() {
                          if (skill.id == null) return;
                          sel
                              ? _selectedSkills.add(skill.id!)
                              : _selectedSkills.remove(skill.id!);
                        }),
                      ),
                    )
                    .toList(),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _createSkillInline,
                icon: const Icon(Icons.add),
                label: const Text('+ Nova skill'),
              ),
            ),
            const SizedBox(height: 16),
            _Section(title: 'Relacionamento'),
            DropdownButtonFormField<int>(
              initialValue: _parentMissionId,
              decoration: const InputDecoration(labelText: 'Parent Mission'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Nenhuma')),
                ...missions
                    .where((m) => m.id != null)
                    .map(
                      (m) =>
                          DropdownMenuItem(value: m.id, child: Text(m.title)),
                    ),
              ],
              onChanged: (v) => setState(() => _parentMissionId = v),
            ),
            const SizedBox(height: 16),
            _Section(title: 'Datas'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _dueDate == null
                          ? 'Definir vencimento'
                          : 'Due: ${_dueDate!.toLocal().toString().split(' ').first}',
                    ),
                    onPressed: _pickDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: const InputDecoration(labelText: 'Repetition'),
              items: const [
                DropdownMenuItem(value: 'once', child: Text('Once')),
                DropdownMenuItem(
                  value: 'continuous',
                  child: Text('Continuous'),
                ),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (v) => setState(() => _recurrence = v ?? 'once'),
            ),
            const SizedBox(height: 16),
            _Section(title: 'Duração e Recompensa'),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (min, 0-60)',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickReward,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Reward Points',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _rewardPoints.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const FaIcon(
                      FontAwesomeIcons.gem,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Section(title: 'Icon'),
            OutlinedButton.icon(
              onPressed: _pickIcon,
              icon: SvgPicture.asset(
                _iconAsset,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                placeholderBuilder: (_) => const SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorBuilder: (_, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 18),
              ),
              label: const Text('Escolher ícone'),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              title: const Text('Mission Complete'),
              value: _isCompleted,
              onChanged: (v) => setState(() => _isCompleted = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Missão'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickReward() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => RewardPickerDialog(initialValue: _rewardPoints),
    );

    if (result != null) {
      setState(() => _rewardPoints = result);
    }
  }

  Future<void> _createSkillInline() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final created = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova skill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('new-skill-name-field'),
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('new-skill-description-field'),
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.pop(dialogContext, (
                name,
                descriptionController.text.trim(),
              ));
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (created == null || !mounted) return;

    final createdSkillId = await context.read<SkillProvider>().addSkill(
      Skill(name: created.$1, description: created.$2),
    );
    if (!mounted) return;
    if (createdSkillId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar a skill.')),
      );
      return;
    }

    setState(() {
      _selectedSkills.add(createdSkillId);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final duration = int.tryParse(_durationController.text.trim()) ?? 0;

    final isRecurring = _recurrence != 'once';
    final recurrenceType = _recurrence == 'once' ? null : _recurrence;
    final status = _isCompleted ? 'completed' : 'active';
    final completedAt = _isCompleted ? DateTime.now() : null;

    final mission = Mission(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      difficulty: _difficulty.round(),
      urgency: _urgency.round(),
      fear: _fear.round(),
      estimatedDuration: duration.clamp(0, 60),
      rewardPoints: _rewardPoints,
      dueDate: _dueDate,
      isRecurring: isRecurring,
      recurrenceType: recurrenceType,
      status: status,
      completedAt: completedAt,
      parentMissionId: _parentMissionId,
      icon: _iconAsset,
      skillIds: _selectedSkills.toList(),
    );

    await context.read<MissionProvider>().addMission(mission);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickIcon() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        return SizedBox(
          height: 360,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _iconOptions.length,
            itemBuilder: (context, index) {
              final asset = _iconOptions[index];
              final isSelected = asset == _iconAsset;
              return GestureDetector(
                onTap: () => Navigator.pop(context, asset),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: SvgPicture.asset(
                    asset,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    placeholderBuilder: (_) => const SizedBox(
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorBuilder: (_, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _iconAsset = selected);
    }
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value.toStringAsFixed(0)),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

const _iconOptions = [
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/archery-target.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/crosshair.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/overkill.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/present.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/treasure-map.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/shopping-bag.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/shop.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/chest.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/skoll/open-treasure-chest.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/locked-chest.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/darkzaitzev/hooded-figure.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/angel-wings.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/aura.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/skills.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/barbell.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/brain.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/feathered-wing.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/light-bulb.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/gear-hammer.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/compass.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/bookmark.svg',
];
