import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/daily_time_budget_advisor.dart';
import '../../../data/models/mission.dart';
import '../../../data/repositories/mission_reward_drop_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/mission_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/skill_provider.dart';
import '../../widgets/common/game_snack_bar.dart';
import 'mission_editor_screen.dart';
import 'mission_form_screen.dart';
import '../../widgets/mission/mission_card.dart';

class MissionsListScreen extends StatefulWidget {
  const MissionsListScreen({super.key});

  @override
  State<MissionsListScreen> createState() => _MissionsListScreenState();
}

class _MissionsListScreenState extends State<MissionsListScreen> {
  final MissionRewardDropRepository _dropsRepo = MissionRewardDropRepository();
  int? _expandedMissionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<MissionProvider>().loadMissions();
      },
      child: Consumer<MissionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final missions = provider.filteredMissions;

          if (missions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '${l10n.translate('no_missions_found')}\n${l10n.translate('use_add_button_to_create')}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];
              final children = provider.missions
                  .where((child) => child.parentMissionId == mission.id)
                  .toList();
              final completedChildren = children
                  .where((child) => child.status == 'completed')
                  .length;
              final progress = children.isEmpty
                  ? 0.0
                  : completedChildren / children.length;
              final timeWarning = _timeWarningForMission(
                mission,
                provider.missions,
              );
              return MissionCard(
                mission: mission,
                isExpanded:
                    mission.id != null && _expandedMissionId == mission.id,
                progress: progress,
                timeWarning: timeWarning,
                onToggleExpanded: () => _toggleMission(mission.id),
                onStatusChanged: (status) =>
                    _updateMissionStatus(mission, status),
                onEdit: () => _editMission(mission),
                onAddSubtask: () => _addSubtask(mission),
                onDuplicate: () => _duplicateMission(mission),
                onAdjustAttributes: () => _adjustAttributes(mission),
                onEditNotes: () => _editMissionNotes(mission),
                onQuickAction: (action) => _handleQuickAction(mission, action),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleMission(int? missionId) {
    if (missionId == null) return;
    setState(() {
      _expandedMissionId = _expandedMissionId == missionId ? null : missionId;
    });
  }

  Future<void> _updateMissionStatus(Mission mission, String status) async {
    if (mission.id == null) return;
    final missionProvider = context.read<MissionProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final skillProvider = context.read<SkillProvider>();
    final l10n = AppLocalizations.of(context);

    await missionProvider.updateMissionStatus(mission.id!, status);
    if (status == 'completed') {
      await Future.wait([
        playerProvider.loadPlayer(),
        skillProvider.loadSkills(),
      ]);
    }
    if (!mounted) return;

    GameSnackBar.show(
      context,
      title: status == 'completed'
          ? l10n.translate('mission_marked_completed')
          : l10n.translate('mission_status_updated'),
      message: '${mission.title} · ${status.toUpperCase()}',
      type: status == 'completed'
          ? GameSnackBarType.reward
          : GameSnackBarType.info,
    );
  }

  Future<void> _addSubtask(Mission mission) async {
    if (mission.id == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MissionFormScreen(initialParentMissionId: mission.id),
      ),
    );
  }

  Future<void> _editMission(Mission mission) async {
    final updated = await Navigator.of(context).push<Mission>(
      MaterialPageRoute(builder: (_) => MissionEditorScreen(initial: mission)),
    );

    if (!mounted || updated == null) return;
    await _updateMission(updated);
  }

  Future<void> _updateMission(Mission mission) async {
    if (mission.id == null) return;
    final missionProvider = context.read<MissionProvider>();
    final existingDrops = await _dropsRepo.getByMissionId(mission.id!);
    if (!mounted) return;
    await missionProvider.updateMission(mission, rewardDrops: existingDrops);
  }

  Future<void> _duplicateMission(Mission mission) async {
    if (mission.id == null) return;
    final missionProvider = context.read<MissionProvider>();
    final l10n = AppLocalizations.of(context);
    final duplicate = mission.copyWith(
      id: null,
      title: '${l10n.translate('copy_of')} ${mission.title}',
      status: 'active',
      completedAt: null,
      lastCompletedAt: null,
      streak: 0,
    );

    final drops = await _dropsRepo.getByMissionId(mission.id!);
    if (!mounted) return;
    await missionProvider.addMission(duplicate, rewardDrops: drops);
  }

  Future<void> _editMissionNotes(Mission mission) async {
    final notesController = TextEditingController(text: mission.notes);
    final l10n = AppLocalizations.of(context);

    final shouldSave =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.background,
            title: Text(l10n.translate('edit_notes')),
            content: TextField(
              controller: notesController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.translate('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.translate('apply')),
              ),
            ],
          ),
        ) ??
        false;

    final notes = notesController.text.trim();
    notesController.dispose();

    if (!mounted || !shouldSave) return;
    await _updateMission(mission.copyWith(notes: notes));
  }

  Future<void> _adjustAttributes(Mission mission) async {
    if (mission.id == null) return;
    double difficulty = mission.difficulty.toDouble();
    double urgency = mission.urgency.toDouble();
    double fear = mission.fear.toDouble();
    final l10n = AppLocalizations.of(context);

    final updated = await showDialog<Mission>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l10n.translate('adjust_attributes')),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _attributeSlider(
                      l10n.translate('difficulty'),
                      value: difficulty,
                      onChanged: (value) => setState(() => difficulty = value),
                    ),
                    _attributeSlider(
                      l10n.translate('urgency'),
                      value: urgency,
                      onChanged: (value) => setState(() => urgency = value),
                    ),
                    _attributeSlider(
                      l10n.translate('fear'),
                      value: fear,
                      onChanged: (value) => setState(() => fear = value),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                mission.copyWith(
                  difficulty: difficulty.round(),
                  urgency: urgency.round(),
                  fear: fear.round(),
                ),
              ),
              child: Text(l10n.translate('apply')),
            ),
          ],
        );
      },
    );

    if (!mounted || updated == null) return;
    await _updateMission(updated);
  }

  Widget _attributeSlider(
    String label, {
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Future<void> _handleQuickAction(
    Mission mission,
    MissionCardQuickAction action,
  ) async {
    switch (action) {
      case MissionCardQuickAction.delete:
        final missionProvider = context.read<MissionProvider>();
        final l10n = AppLocalizations.of(context);
        final deleteTitle = l10n.translate('delete');
        final deleteMessage = l10n
            .translate('delete_action_done')
            .replaceFirst('{title}', mission.title);
        final confirm = await _confirmDelete(mission.title);
        if (!confirm || mission.id == null) return;
        await missionProvider.deleteMission(mission.id!);
        if (!mounted) return;
        GameSnackBar.show(
          context,
          title: deleteTitle,
          message: deleteMessage,
          type: GameSnackBarType.info,
        );
        return;
      case MissionCardQuickAction.fail:
        await _updateMissionStatus(mission, 'archived');
        return;
      case MissionCardQuickAction.reschedule:
        await _rescheduleMission(mission);
        return;
      case MissionCardQuickAction.recurrence:
        await _editRecurrence(mission);
        return;
      case MissionCardQuickAction.reward:
        await _editMission(mission);
        return;
      case MissionCardQuickAction.duration:
        await _editDuration(mission);
        return;
      case MissionCardQuickAction.skills:
        await _editSkills(mission);
        return;
      case MissionCardQuickAction.move:
        await _moveMission(mission);
        return;
      default:
        return;
    }
  }

  Future<void> _rescheduleMission(Mission mission) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: mission.dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 4)),
    );
    if (selected == null || mission.id == null) return;
    await _updateMission(mission.copyWith(dueDate: selected));
  }

  Future<void> _editRecurrence(Mission mission) async {
    if (mission.id == null) return;
    final l10n = AppLocalizations.of(context);
    String recurrence = mission.recurrenceType ?? 'once';
    int interval = mission.recurrenceInterval ?? 1;

    final updated = await showDialog<Mission>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(l10n.translate('mission_menu_recurrence')),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: recurrence,
                    items: [
                      DropdownMenuItem(
                        value: 'once',
                        child: Text(l10n.translate('mission_recurrence_once')),
                      ),
                      DropdownMenuItem(
                        value: 'continuous',
                        child: Text(
                          l10n.translate('mission_recurrence_continuous'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'daily',
                        child: Text(l10n.translate('mission_recurrence_daily')),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text(
                          l10n.translate('mission_recurrence_weekly'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => recurrence = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (recurrence != 'once') ...[
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.translate('recurrence_interval'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        interval = int.tryParse(value) ?? interval;
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              mission.copyWith(
                recurrenceType: recurrence == 'once' ? null : recurrence,
                recurrenceInterval: recurrence == 'once' ? null : interval,
                isRecurring: recurrence != 'once',
              ),
            ),
            child: Text(l10n.translate('apply')),
          ),
        ],
      ),
    );

    if (!mounted || updated == null) return;
    await _updateMission(updated);
  }

  Future<void> _editDuration(Mission mission) async {
    final l10n = AppLocalizations.of(context);
    final durationController = TextEditingController(
      text: mission.estimatedDuration?.toString() ?? '',
    );

    final newDuration = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(l10n.translate('mission_menu_duration')),
        content: TextField(
          controller: durationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.translate('duration_minutes'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(durationController.text.trim());
              if (value == null || value < 0) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, value);
            },
            child: Text(l10n.translate('apply')),
          ),
        ],
      ),
    );
    durationController.dispose();
    if (!mounted || newDuration == null || mission.id == null) return;
    await _updateMission(mission.copyWith(estimatedDuration: newDuration));
  }

  Future<void> _editSkills(Mission mission) async {
    final l10n = AppLocalizations.of(context);
    final availableSkills = context.read<SkillProvider>().skills;
    final Set<int> selected = mission.skillIds.toSet();

    final updated = await showDialog<Set<int>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l10n.translate('mission_menu_skills')),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 320,
                child: ListView(
                  shrinkWrap: true,
                  children: availableSkills
                      .where((skill) => skill.id != null)
                      .map(
                        (skill) => CheckboxListTile(
                          title: Text(skill.name),
                          value: selected.contains(skill.id),
                          onChanged: (value) {
                            if (skill.id == null) return;
                            setState(() {
                              if (value == true) {
                                selected.add(skill.id!);
                              } else {
                                selected.remove(skill.id!);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text(l10n.translate('apply')),
            ),
          ],
        );
      },
    );

    if (!mounted || updated == null || mission.id == null) return;
    await _updateMission(mission.copyWith(skillIds: updated.toList()));
  }

  Future<void> _moveMission(Mission mission) async {
    final l10n = AppLocalizations.of(context);
    final missions = context.read<MissionProvider>().missions;
    int? selected = mission.parentMissionId;

    final updatedParent = await showDialog<int?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l10n.translate('mission_menu_move')),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(l10n.translate('none')),
                      leading: Icon(
                        selected == null
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected == null
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                      onTap: () => setState(() => selected = null),
                    ),
                    ...missions
                        .where((m) => m.id != mission.id && m.id != null)
                        .map(
                          (option) => ListTile(
                            title: Text(option.title),
                            leading: Icon(
                              selected == option.id
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: selected == option.id
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                            onTap: () => setState(() => selected = option.id),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text(l10n.translate('apply')),
            ),
          ],
        );
      },
    );

    if (mission.id == null || !mounted) return;
    await _updateMission(mission.copyWith(parentMissionId: updatedParent));
  }

  Future<bool> _confirmDelete(String title) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(l10n.translate('confirm')),
        content: Text('${l10n.translate('confirm_delete')} $title'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.translate('delete'),
              style: const TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String? _timeWarningForMission(Mission mission, List<Mission> allMissions) {
    if (!_isDueToday(mission) || (mission.estimatedDuration ?? 0) <= 0) {
      return null;
    }
    final player = context.read<PlayerProvider>().player;
    if (player == null || player.energyMode != 'auto') return null;
    final result = DailyTimeBudgetAdvisor.assess(
      now: DateTime.now(),
      wakeUpTime: player.wakeUpTime,
      sleepTime: player.sleepTime,
      missions: allMissions,
    );
    return result.exceedsAvailableTime ? result.message : null;
  }

  bool _isDueToday(Mission mission) {
    final dueDate = mission.dueDate;
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }
}
