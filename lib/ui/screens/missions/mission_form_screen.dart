import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/skill.dart';
import '../../../providers/mission_provider.dart';
import '../../../providers/skill_provider.dart';

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
  final _rewardController = TextEditingController(text: '10');

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
    // Garantir que skills/missions estejam carregadas
    Future.microtask(() {
      context.read<SkillProvider>().loadSkills();
      context.read<MissionProvider>().loadMissions();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skillProvider = context.watch<SkillProvider>();
    final missions = context.watch<MissionProvider>().missions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Missão'),
      ),
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
                          sel ? _selectedSkills.add(skill.id!) : _selectedSkills.remove(skill.id!);
                        }),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            _Section(title: 'Relacionamento'),
            DropdownButtonFormField<int>(
              value: _parentMissionId,
              decoration: const InputDecoration(labelText: 'Parent Mission'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Nenhuma')),
                ...missions
                    .where((m) => m.id != null)
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.title),
                      ),
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
              value: _recurrence,
              decoration: const InputDecoration(labelText: 'Repetition'),
              items: const [
                DropdownMenuItem(value: 'once', child: Text('Once')),
                DropdownMenuItem(value: 'continuous', child: Text('Continuous')),
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
            TextFormField(
              controller: _rewardController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reward (money/points)',
              ),
            ),
            const SizedBox(height: 16),
            _Section(title: 'Icon'),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final asset = _iconOptions[index];
                  final selected = asset == _iconAsset;
                  return GestureDetector(
                    onTap: () => setState(() => _iconAsset = asset),
                    child: Container(
                      width: 64,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected ? AppTheme.primary : AppTheme.border,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.surface,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: SvgPicture.asset(
                        asset,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _iconOptions.length,
              ),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    final reward = int.tryParse(_rewardController.text.trim()) ?? 0;

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
      rewardPoints: reward,
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
  'assets/game-icons.net.svg/icons/ffffff/000000/1x1/lorc/archery-target.svg',
  'assets/game-icons.net.svg/icons/ffffff/000000/1x1/delapouite/present.svg',
  'assets/game-icons.net.svg/icons/ffffff/000000/1x1/delapouite/chest.svg',
  'assets/game-icons.net.svg/icons/ffffff/000000/1x1/delapouite/shop.svg',
  'assets/game-icons.net.svg/icons/ffffff/000000/1x1/darkzaitzev/hooded-figure.svg',
];

