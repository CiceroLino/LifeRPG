import 'icon_registry.dart';

class ProfileClassPreset {
  final String name;

  const ProfileClassPreset(this.name);
}

class MissionTemplate {
  final String label;
  final String title;
  final String description;
  final String notes;
  final int difficulty;
  final int urgency;
  final int fear;
  final int durationMinutes;
  final String recurrence;
  final String iconAsset;

  const MissionTemplate({
    required this.label,
    required this.title,
    required this.description,
    required this.notes,
    required this.difficulty,
    required this.urgency,
    required this.fear,
    required this.durationMinutes,
    required this.recurrence,
    required this.iconAsset,
  });
}

class RewardTemplate {
  final String label;
  final String name;
  final String description;
  final int priceRp;
  final String icon;

  const RewardTemplate({
    required this.label,
    required this.name,
    required this.description,
    required this.priceRp,
    required this.icon,
  });
}

class NotebookTemplate {
  final String name;
  final String description;

  const NotebookTemplate({
    required this.name,
    required this.description,
  });
}

class DefaultContentTemplates {
  static const profileClasses = [
    ProfileClassPreset('Adventurer'),
    ProfileClassPreset('Knight'),
    ProfileClassPreset('Mage'),
    ProfileClassPreset('Rogue'),
    ProfileClassPreset('Hunter'),
    ProfileClassPreset('Scholar'),
    ProfileClassPreset('Healer'),
    ProfileClassPreset('Craftsman'),
    ProfileClassPreset('Explorer'),
    ProfileClassPreset('Guardian'),
  ];

  static final missionTemplates = [
    MissionTemplate(
      label: 'Daily ritual',
      title: 'Daily ritual',
      description: 'Complete the core routine that keeps the day moving.',
      notes: 'Session 1 - Review intent, execute, then log what changed.',
      difficulty: 35,
      urgency: 65,
      fear: 15,
      durationMinutes: 30,
      recurrence: 'daily',
      iconAsset: '${LifeRPGIcons.assetRoot}/missions/skills.svg',
    ),
    MissionTemplate(
      label: 'Deep work',
      title: 'Deep work block',
      description: 'Protect a focused work block for a meaningful task.',
      notes: 'Session 1 - Define the outcome before starting.',
      difficulty: 70,
      urgency: 55,
      fear: 35,
      durationMinutes: 60,
      recurrence: 'once',
      iconAsset: '${LifeRPGIcons.assetRoot}/missions/work.svg',
    ),
    MissionTemplate(
      label: 'Training',
      title: 'Training quest',
      description: 'Practice a skill with a clear finish condition.',
      notes: 'Session 1 - Record repetitions, blockers, and next drill.',
      difficulty: 55,
      urgency: 45,
      fear: 20,
      durationMinutes: 45,
      recurrence: 'weekly',
      iconAsset: '${LifeRPGIcons.assetRoot}/missions/strength.svg',
    ),
    MissionTemplate(
      label: 'Cleanup',
      title: 'Clear the backlog',
      description: 'Resolve a small cluster of pending tasks.',
      notes: 'Session 1 - List what was cleared and what remains.',
      difficulty: 40,
      urgency: 80,
      fear: 25,
      durationMinutes: 25,
      recurrence: 'once',
      iconAsset: '${LifeRPGIcons.assetRoot}/missions/quest.svg',
    ),
  ];

  static const rewardTemplates = [
    RewardTemplate(
      label: 'Break',
      name: 'Short break',
      description: 'A guilt-free pause after finishing a quest.',
      priceRp: 15,
      icon: 'local_cafe',
    ),
    RewardTemplate(
      label: 'Episode',
      name: 'Watch an episode',
      description: 'One episode or short video session.',
      priceRp: 35,
      icon: 'movie',
    ),
    RewardTemplate(
      label: 'Game',
      name: 'Game session',
      description: 'A focused game session with a clear stop point.',
      priceRp: 50,
      icon: 'sports_esports',
    ),
    RewardTemplate(
      label: 'Reading',
      name: 'Reading time',
      description: 'Dedicated reading time outside task mode.',
      priceRp: 25,
      icon: 'menu_book',
    ),
  ];

  static const notebookTemplates = [
    NotebookTemplate(
      name: 'Quest Log',
      description: 'Daily mission notes, session order, and outcomes.',
    ),
    NotebookTemplate(
      name: 'Build Notes',
      description: 'Ideas, decisions, and implementation notes.',
    ),
    NotebookTemplate(
      name: 'Reward Ideas',
      description: 'A shortlist of rewards to add to the shop later.',
    ),
    NotebookTemplate(
      name: 'Retrospective',
      description: 'Wins, blockers, and next adjustments.',
    ),
  ];
}
