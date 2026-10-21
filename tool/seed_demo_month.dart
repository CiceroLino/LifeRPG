// ignore_for_file: avoid_print

import 'dart:math';

import 'package:liferpg/core/platform/database_platform.dart';
import 'package:liferpg/core/utils/xp_calculator.dart';
import 'package:liferpg/data/database/database_helper.dart';

const _tag = '[Demo Month]';

Future<void> main() async {
  await configureDatabasePlatform();

  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;
  final now = DateTime.now();
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 29));

  final summary = await db.transaction((txn) async {
    await _deleteExistingDemoData(txn);

    final skillIds = await _insertSkills(txn, start);
    final rewardIds = await _insertRewards(txn, start);
    final totals = _SeedTotals();
    final inventoryIds = <int, int>{};

    for (var dayIndex = 0; dayIndex < 30; dayIndex++) {
      final day = start.add(Duration(days: dayIndex));
      final isWeekend =
          day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

      await _insertCompletedMission(
        txn,
        totals: totals,
        skillIds: [skillIds['Fitness']!, skillIds['Discipline']!],
        rewardIds: rewardIds,
        inventoryIds: inventoryIds,
        createdAt: day
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 20)),
        completedAt: day.add(const Duration(hours: 7, minutes: 35)),
        title: '$_tag Morning HP routine D${dayIndex + 1}',
        description:
            'Wake up, hydrate, stretch, and log energy before the day starts.',
        notes: 'Kept the HP loop visible and easy to complete.',
        difficulty: isWeekend ? 34 : 42,
        urgency: 48,
        fear: 12,
        energyRequired: 2,
        estimatedDuration: 25,
        locationName: 'Home Base',
        latitude: -9.6498,
        longitude: -35.7089,
        rewardDropId: rewardIds['Energy Potion']!,
        rewardDropChance: dayIndex % 4 == 0 ? 100 : 35,
        rewardDropAwarded: dayIndex % 4 == 0,
      );

      if (!isWeekend) {
        await _insertCompletedMission(
          txn,
          totals: totals,
          skillIds: [skillIds['Work']!, skillIds['Focus']!],
          rewardIds: rewardIds,
          inventoryIds: inventoryIds,
          createdAt: day
              .subtract(const Duration(days: 1))
              .add(const Duration(hours: 18)),
          completedAt: day.add(const Duration(hours: 10, minutes: 20)),
          title: '$_tag Deep work quest D${dayIndex + 1}',
          description:
              'Complete a high-value work block with a clear deliverable.',
          notes: 'Used Focus Quest before opening chat or email.',
          difficulty: 72,
          urgency: 66 + (dayIndex % 3) * 6,
          fear: 28 + (dayIndex % 4) * 8,
          energyRequired: 4,
          estimatedDuration: 90,
          locationName: 'Desk Station',
          latitude: -9.6486,
          longitude: -35.7064,
          rewardDropId: rewardIds['Rare Coffee Token']!,
          rewardDropChance: dayIndex % 6 == 0 ? 100 : 20,
          rewardDropAwarded: dayIndex % 6 == 0,
        );
      }

      await _insertCompletedMission(
        txn,
        totals: totals,
        skillIds: [skillIds['Homecraft']!, skillIds['Admin']!],
        rewardIds: rewardIds,
        inventoryIds: inventoryIds,
        createdAt: day
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 21)),
        completedAt: day.add(const Duration(hours: 19, minutes: 10)),
        title: '$_tag Real-life upkeep D${dayIndex + 1}',
        description:
            'One practical life task: cleaning, bills, messages, or planning.',
        notes: 'Small quest that keeps the base from decaying.',
        difficulty: 38 + (dayIndex % 5) * 5,
        urgency: 42 + (dayIndex % 4) * 7,
        fear: 18 + (dayIndex % 3) * 6,
        energyRequired: 2,
        estimatedDuration: 35,
        locationName: dayIndex % 5 == 0 ? 'Errand Route' : 'Home Base',
        latitude: -9.665 + dayIndex * 0.001,
        longitude: -35.735 + dayIndex * 0.001,
      );

      if (!isWeekend || dayIndex % 2 == 0) {
        await _insertFocusSession(
          txn,
          totals: totals,
          day: day,
          plannedMinutes: isWeekend ? 25 : 50,
          completedMinutes: isWeekend ? 25 : 45 + (dayIndex % 3) * 5,
        );
      }
    }

    await _insertActiveAndArchivedMissions(
      txn,
      now: now,
      skillIds: skillIds,
      rewardIds: rewardIds,
    );
    await _insertInventoryAndPurchases(
      txn,
      rewardIds: rewardIds,
      inventoryIds: inventoryIds,
      now: now,
      totals: totals,
    );
    await _insertNotebooks(txn, start, now);
    await _insertTomes(txn, start, now);
    await _insertAudioTracks(txn, start, now);
    await _updateSkills(txn, skillIds, totals.skillXp, now);
    await _updatePlayer(txn, totals, now);

    return {
      'missions': totals.completedMissions + 8,
      'completedMissions': totals.completedMissions,
      'focusSessions': totals.focusSessions,
      'xp': totals.totalXp,
      'rp': totals.remainingRp,
    };
  });

  await dbHelper.close();

  print('Seeded LifeRPG demo month.');
  print('Missions: ${summary['missions']}');
  print('Completed missions: ${summary['completedMissions']}');
  print('Focus sessions: ${summary['focusSessions']}');
  print('Player XP: ${summary['xp']}');
  print('Remaining RP: ${summary['rp']}');
}

Future<void> _deleteExistingDemoData(dynamic txn) async {
  final demoMissionIds = await txn.rawQuery(
    "SELECT id FROM missions WHERE title LIKE '$_tag%'",
  );
  final demoRewardIds = await txn.rawQuery(
    "SELECT id FROM rewards WHERE name LIKE '$_tag%'",
  );
  final demoInventoryIds = await txn.rawQuery(
    "SELECT id FROM inventory_items WHERE name LIKE '$_tag%'",
  );
  final demoEventIds = await txn.rawQuery(
    "SELECT id FROM mission_completion_events "
    "WHERE mission_title_snapshot LIKE '$_tag%'",
  );

  final missionIds = _ids(demoMissionIds);
  final rewardIds = _ids(demoRewardIds);
  final inventoryIds = _ids(demoInventoryIds);
  final eventIds = _ids(demoEventIds);

  await _deleteWhereIn(
    txn,
    'mission_completion_reward_drops',
    'event_id',
    eventIds,
  );
  await _deleteWhereIn(
    txn,
    'mission_completion_skill_rewards',
    'event_id',
    eventIds,
  );
  await _deleteWhereIn(txn, 'mission_completion_events', 'id', eventIds);
  await _deleteWhereIn(txn, 'mission_reward_drops', 'mission_id', missionIds);
  await _deleteWhereIn(txn, 'mission_skills', 'mission_id', missionIds);
  await _deleteWhereIn(txn, 'missions', 'id', missionIds);
  await _deleteWhereIn(
    txn,
    'reward_redemptions',
    'inventory_item_id',
    inventoryIds,
  );
  await _deleteWhereIn(txn, 'reward_redemptions', 'reward_id', rewardIds);
  await txn.delete(
    'reward_redemptions',
    where: "reward_name_snapshot LIKE '$_tag%'",
  );
  await _deleteWhereIn(txn, 'inventory_items', 'id', inventoryIds);
  await _deleteWhereIn(txn, 'rewards', 'id', rewardIds);
  await txn.delete('focus_sessions', where: "status = 'demo_completed'");
  await txn.delete('notes', where: "title LIKE '$_tag%'");
  await txn.delete('notebooks', where: "name LIKE '$_tag%'");
  await txn.delete('tomes', where: "title LIKE '$_tag%'");
  await txn.delete('audio_tracks', where: "title LIKE '$_tag%'");
  await txn.delete('skills', where: "name LIKE '$_tag%'");
}

List<int> _ids(List<Map<String, Object?>> rows) =>
    rows.map((row) => row['id'] as int).toList(growable: false);

Future<void> _deleteWhereIn(
  dynamic txn,
  String table,
  String column,
  List<int> ids,
) async {
  if (ids.isEmpty) return;
  final placeholders = List.filled(ids.length, '?').join(',');
  await txn.delete(table, where: '$column IN ($placeholders)', whereArgs: ids);
}

Future<Map<String, int>> _insertSkills(dynamic txn, DateTime start) async {
  final skills = <String, (String, String)>{
    'Focus': ('#7C4DFF', 'Long concentration and distraction control.'),
    'Work': ('#29B6F6', 'Professional delivery and deep execution.'),
    'Fitness': ('#EF5350', 'Body maintenance, mobility, and strength.'),
    'Discipline': ('#FFCA28', 'Repeatable habits and self-command.'),
    'Learning': ('#66BB6A', 'Reading, courses, and deliberate study.'),
    'Homecraft': ('#8D6E63', 'Home base upkeep and practical life systems.'),
    'Social': ('#EC407A', 'Relationships, messages, and shared plans.'),
    'Admin': ('#B0BEC5', 'Bills, planning, documents, and logistics.'),
  };

  final ids = <String, int>{};
  for (final entry in skills.entries) {
    ids[entry.key] = await txn.insert('skills', {
      'name': '$_tag ${entry.key}',
      'description': entry.value.$2,
      'current_xp': 0,
      'level': 1,
      'color': entry.value.$1,
      'icon': null,
      'is_active': 1,
      'created_at': start.toIso8601String(),
      'updated_at': start.toIso8601String(),
    });
  }
  return ids;
}

Future<Map<String, int>> _insertRewards(dynamic txn, DateTime start) async {
  final rewards = [
    ('Energy Potion', 'Take a guilt-free restorative break.', 25, true, null),
    (
      'Rare Coffee Token',
      'Premium coffee after a high-focus block.',
      40,
      false,
      6,
    ),
    (
      'Movie Night Pass',
      'Reserve an evening for a film or series.',
      70,
      true,
      null,
    ),
    (
      'Side Quest Snack',
      'Small treat from the shop inventory.',
      15,
      true,
      null,
    ),
    (
      'Weekend Raid Ticket',
      'Longer leisure block for the weekend.',
      130,
      false,
      3,
    ),
    (
      'Gear Upgrade Fund',
      'Budget marker for a useful life upgrade.',
      220,
      false,
      1,
    ),
  ];

  final ids = <String, int>{};
  for (final reward in rewards) {
    ids[reward.$1] = await txn.insert('rewards', {
      'name': '$_tag ${reward.$1}',
      'description': reward.$2,
      'price_rp': reward.$3,
      'is_unlimited_stock': reward.$4 ? 1 : 0,
      'stock_remaining': reward.$5,
      'icon': null,
      'is_active': 1,
      'created_at': start.toIso8601String(),
      'updated_at': start.toIso8601String(),
    });
  }
  return ids;
}

Future<void> _insertCompletedMission(
  dynamic txn, {
  required _SeedTotals totals,
  required List<int> skillIds,
  required Map<String, int> rewardIds,
  required Map<int, int> inventoryIds,
  required DateTime createdAt,
  required DateTime completedAt,
  required String title,
  required String description,
  required String notes,
  required int difficulty,
  required int urgency,
  required int fear,
  required int energyRequired,
  required int estimatedDuration,
  required String locationName,
  required double latitude,
  required double longitude,
  int? rewardDropId,
  int rewardDropChance = 0,
  bool rewardDropAwarded = false,
}) async {
  final xp = XPCalculator.calculateMissionXP(
    difficulty: difficulty,
    urgency: urgency,
    fear: fear,
  );
  final rp = xp <= 1000
      ? 5
      : xp <= 10000
      ? 10
      : 25;

  final missionId = await txn.insert('missions', {
    'title': title,
    'description': description,
    'notes': notes,
    'reminder_note': 'Demo reminder: treat this like a real-world quest.',
    'difficulty': difficulty,
    'urgency': urgency,
    'fear': fear,
    'energy_required': energyRequired,
    'xp_reward': xp,
    'reward_points': rp,
    'status': 'completed',
    'due_date': completedAt.toIso8601String(),
    'estimated_duration': estimatedDuration,
    'is_recurring': 0,
    'recurrence_type': null,
    'recurrence_interval': null,
    'last_completed_at': null,
    'streak': 0,
    'parent_mission_id': null,
    'order_index': totals.completedMissions,
    'icon': null,
    'emoji': null,
    'location_name': locationName,
    'latitude': latitude,
    'longitude': longitude,
    'reminder_at': completedAt
        .subtract(const Duration(hours: 1))
        .toIso8601String(),
    'recurrence_days': null,
    'created_at': createdAt.toIso8601String(),
    'updated_at': completedAt.toIso8601String(),
    'completed_at': completedAt.toIso8601String(),
  });

  for (final skillId in skillIds) {
    await txn.insert('mission_skills', {
      'mission_id': missionId,
      'skill_id': skillId,
    });
  }

  final eventId = await txn.insert('mission_completion_events', {
    'mission_id': missionId,
    'mission_title_snapshot': title,
    'xp_granted': xp,
    'reward_points_granted': rp,
    'completed_at': completedAt.toIso8601String(),
    'recurrence_type': null,
    'resulting_streak': 0,
  });

  final xpPerSkill = (xp / skillIds.length).round();
  for (final skillId in skillIds) {
    await txn.insert('mission_completion_skill_rewards', {
      'event_id': eventId,
      'skill_id': skillId,
      'skill_name_snapshot': await _skillName(txn, skillId),
      'xp_granted': xpPerSkill,
    });
    totals.skillXp[skillId] = (totals.skillXp[skillId] ?? 0) + xpPerSkill;
  }

  if (rewardDropId != null) {
    await txn.insert('mission_reward_drops', {
      'mission_id': missionId,
      'reward_id': rewardDropId,
      'chance_percent': rewardDropChance,
      'quantity': 1,
      'created_at': createdAt.toIso8601String(),
      'updated_at': createdAt.toIso8601String(),
    });

    int? inventoryItemId;
    if (rewardDropAwarded) {
      inventoryItemId = await _upsertInventoryItem(
        txn,
        rewardId: rewardDropId,
        inventoryIds: inventoryIds,
        now: completedAt,
      );
    }

    await txn.insert('mission_completion_reward_drops', {
      'event_id': eventId,
      'reward_id': rewardDropId,
      'inventory_item_id': inventoryItemId,
      'reward_name_snapshot': await _rewardName(txn, rewardDropId),
      'quantity': 1,
      'chance_percent': rewardDropChance,
      'was_awarded': rewardDropAwarded ? 1 : 0,
    });
  }

  totals.completedMissions++;
  totals.totalXp += xp;
  totals.earnedRp += rp;
}

Future<void> _insertFocusSession(
  dynamic txn, {
  required _SeedTotals totals,
  required DateTime day,
  required int plannedMinutes,
  required int completedMinutes,
}) async {
  final completedAt = day.add(const Duration(hours: 9, minutes: 20));
  await txn.insert('focus_sessions', {
    'planned_minutes': plannedMinutes,
    'completed_minutes': completedMinutes,
    'xp_granted': completedMinutes,
    'status': 'demo_completed',
    'started_at': completedAt
        .subtract(Duration(minutes: completedMinutes))
        .toIso8601String(),
    'completed_at': completedAt.toIso8601String(),
  });
  totals.focusSessions++;
  totals.totalXp += completedMinutes;
}

Future<void> _insertActiveAndArchivedMissions(
  dynamic txn, {
  required DateTime now,
  required Map<String, int> skillIds,
  required Map<String, int> rewardIds,
}) async {
  final active = [
    (
      'Weekly review raid',
      'Review the last 7 days, plan next quests, and rebalance HP.',
      58,
      74,
      22,
      3,
      60,
      now.add(const Duration(days: 1, hours: 8)),
      true,
      'weekly',
      [DateTime.sunday],
      [skillIds['Discipline']!, skillIds['Admin']!],
    ),
    (
      'Clean inbox dungeon',
      'Clear email/messages to zero actionable loose ends.',
      46,
      64,
      34,
      2,
      45,
      now.subtract(const Duration(days: 1)),
      false,
      null,
      <int>[],
      [skillIds['Admin']!],
    ),
    (
      'Study chapter: systems thinking',
      'Read and summarize one chapter into the learning tome.',
      62,
      48,
      18,
      3,
      50,
      now.add(const Duration(days: 2)),
      false,
      null,
      <int>[],
      [skillIds['Learning']!, skillIds['Focus']!],
    ),
    (
      'Call an ally',
      'Reach out and schedule a real conversation.',
      32,
      52,
      46,
      1,
      20,
      now.add(const Duration(hours: 18)),
      false,
      null,
      <int>[],
      [skillIds['Social']!],
    ),
  ];

  for (var i = 0; i < active.length; i++) {
    final item = active[i];
    final missionId = await txn.insert('missions', {
      'title': '$_tag ${item.$1}',
      'description': item.$2,
      'notes': 'Active demo quest for testing filters, due dates, and details.',
      'reminder_note': 'Check HP before starting.',
      'difficulty': item.$3,
      'urgency': item.$4,
      'fear': item.$5,
      'energy_required': item.$6,
      'xp_reward': XPCalculator.calculateMissionXP(
        difficulty: item.$3,
        urgency: item.$4,
        fear: item.$5,
      ),
      'reward_points': 10,
      'status': 'active',
      'due_date': item.$8.toIso8601String(),
      'estimated_duration': item.$7,
      'is_recurring': item.$9 ? 1 : 0,
      'recurrence_type': item.$10,
      'recurrence_interval': item.$9 ? 1 : null,
      'last_completed_at': item.$9
          ? now.subtract(const Duration(days: 6)).toIso8601String()
          : null,
      'streak': item.$9 ? 4 : 0,
      'parent_mission_id': null,
      'order_index': i,
      'icon': null,
      'emoji': null,
      'location_name': i.isEven ? 'Home Base' : 'City Route',
      'latitude': -9.65 + i * 0.004,
      'longitude': -35.71 - i * 0.004,
      'reminder_at': item.$8
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
      'recurrence_days': item.$11.isEmpty ? null : item.$11.join(','),
      'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
      'updated_at': now.toIso8601String(),
      'completed_at': null,
    });

    for (final skillId in item.$12) {
      await txn.insert('mission_skills', {
        'mission_id': missionId,
        'skill_id': skillId,
      });
    }

    if (i == 0) {
      await txn.insert('mission_reward_drops', {
        'mission_id': missionId,
        'reward_id': rewardIds['Weekend Raid Ticket']!,
        'chance_percent': 45,
        'quantity': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }
  }

  final parentId = await txn.insert('missions', {
    'title': '$_tag Project arc: rebuild command center',
    'description': 'A parent quest with subtasks for testing hierarchy.',
    'difficulty': 80,
    'urgency': 55,
    'fear': 35,
    'energy_required': 5,
    'xp_reward': 5940,
    'reward_points': 25,
    'status': 'active',
    'due_date': now.add(const Duration(days: 6)).toIso8601String(),
    'estimated_duration': 180,
    'is_recurring': 0,
    'created_at': now.subtract(const Duration(days: 4)).toIso8601String(),
    'updated_at': now.toIso8601String(),
  });
  for (final skillId in [skillIds['Work']!, skillIds['Homecraft']!]) {
    await txn.insert('mission_skills', {
      'mission_id': parentId,
      'skill_id': skillId,
    });
  }

  for (final title in ['Cable management', 'Define weekly dashboard']) {
    await txn.insert('missions', {
      'title': '$_tag $title',
      'description': 'Subquest under command center project.',
      'difficulty': 36,
      'urgency': 44,
      'fear': 12,
      'energy_required': 2,
      'xp_reward': 1774,
      'reward_points': 5,
      'status': 'active',
      'due_date': now.add(const Duration(days: 3)).toIso8601String(),
      'estimated_duration': 35,
      'is_recurring': 0,
      'parent_mission_id': parentId,
      'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  await txn.insert('missions', {
    'title': '$_tag Archived quest: old habit tracker migration',
    'description': 'Archived demo quest for testing archive states.',
    'difficulty': 40,
    'urgency': 30,
    'fear': 20,
    'energy_required': 2,
    'xp_reward': 1440,
    'reward_points': 5,
    'status': 'archived',
    'due_date': now.subtract(const Duration(days: 14)).toIso8601String(),
    'estimated_duration': 40,
    'is_recurring': 0,
    'created_at': now.subtract(const Duration(days: 20)).toIso8601String(),
    'updated_at': now.subtract(const Duration(days: 12)).toIso8601String(),
  });
}

Future<void> _insertInventoryAndPurchases(
  dynamic txn, {
  required Map<String, int> rewardIds,
  required Map<int, int> inventoryIds,
  required DateTime now,
  required _SeedTotals totals,
}) async {
  final purchases = [
    ('Movie Night Pass', 1, 70),
    ('Side Quest Snack', 3, 45),
    ('Weekend Raid Ticket', 1, 130),
  ];

  for (var i = 0; i < purchases.length; i++) {
    final purchase = purchases[i];
    final rewardId = rewardIds[purchase.$1]!;
    final redeemedAt = now.subtract(Duration(days: 12 - i * 4));
    final inventoryItemId = await _upsertInventoryItem(
      txn,
      rewardId: rewardId,
      inventoryIds: inventoryIds,
      now: redeemedAt,
      quantity: purchase.$2,
    );
    await txn.insert('reward_redemptions', {
      'reward_id': rewardId,
      'inventory_item_id': inventoryItemId,
      'reward_name_snapshot': '$_tag ${purchase.$1}',
      'reward_description_snapshot': await _rewardDescription(txn, rewardId),
      'reward_icon_snapshot': null,
      'price_paid_rp': purchase.$3,
      'redeemed_at': redeemedAt.toIso8601String(),
    });
    totals.spentRp += purchase.$3;
  }

  await _upsertInventoryItem(
    txn,
    rewardId: rewardIds['Energy Potion']!,
    inventoryIds: inventoryIds,
    now: now,
    quantity: 2,
  );
}

Future<void> _insertNotebooks(dynamic txn, DateTime start, DateTime now) async {
  final notebookData = [
    ('Quest Journal', 'Daily notes, friction logs, and quest reflections.'),
    ('Build Log', 'Technical notes from the month-long work arc.'),
    ('Reward Ideas', 'Future shop items and inventory balancing notes.'),
  ];

  for (final notebook in notebookData) {
    final notebookId = await txn.insert('notebooks', {
      'name': '$_tag ${notebook.$1}',
      'description': notebook.$2,
      'is_active': 1,
      'created_at': start.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    for (var i = 0; i < 3; i++) {
      final day = start.add(
        Duration(days: i * 8 + notebookData.indexOf(notebook)),
      );
      await txn.insert('notes', {
        'notebook_id': notebookId,
        'title': '$_tag ${notebook.$1} note ${i + 1}',
        'body':
            'Demo note from ${day.toIso8601String().split('T').first}: what worked, what cost HP, and what becomes a quest next.',
        'created_at': day.toIso8601String(),
        'updated_at': day.add(const Duration(hours: 1)).toIso8601String(),
      });
    }
  }
}

Future<void> _insertTomes(dynamic txn, DateTime start, DateTime now) async {
  final tomes = [
    ('Systems Thinking Field Manual', 'Demo Author', 42, 180),
    ('Focus Quest Codex', 'Guild Archivist', 18, 96),
    ('Habit Alchemy Notes', 'Local Sage', 73, 144),
  ];
  for (final tome in tomes) {
    await txn.insert('tomes', {
      'title': '$_tag ${tome.$1}',
      'author': tome.$2,
      'description': 'Demo tome with reading progress for UI testing.',
      'file_path':
          '/tmp/liferpg-demo/${tome.$1.toLowerCase().replaceAll(' ', '-')}.pdf',
      'current_page': tome.$3,
      'total_pages': tome.$4,
      'is_active': 1,
      'last_opened_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      'created_at': start.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }
}

Future<void> _insertAudioTracks(
  dynamic txn,
  DateTime start,
  DateTime now,
) async {
  final tracks = [
    (
      'Tavern Ambience - Planning Night',
      'Demo Bard',
      'LifeRPG OST',
      3600000,
      640000,
    ),
    ('Dungeon Sprint Timer', 'Demo Bard', 'Focus Loops', 1500000, 310000),
    ('Victory Walk Home', 'Demo Bard', 'Reward Themes', 2100000, 0),
  ];
  for (final track in tracks) {
    await txn.insert('audio_tracks', {
      'title': '$_tag ${track.$1}',
      'artist': track.$2,
      'album': track.$3,
      'file_path':
          '/tmp/liferpg-demo/${track.$1.toLowerCase().replaceAll(' ', '-')}.mp3',
      'duration_ms': track.$4,
      'position_ms': track.$5,
      'is_active': 1,
      'last_played_at': now
          .subtract(const Duration(hours: 3))
          .toIso8601String(),
      'created_at': start.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }
}

Future<String> _skillName(dynamic txn, int id) async {
  final rows = await txn.query(
    'skills',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  return rows.first['name'] as String;
}

Future<String> _rewardName(dynamic txn, int id) async {
  final rows = await txn.query(
    'rewards',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  return rows.first['name'] as String;
}

Future<String> _rewardDescription(dynamic txn, int id) async {
  final rows = await txn.query(
    'rewards',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  return rows.first['description'] as String? ?? '';
}

Future<int> _upsertInventoryItem(
  dynamic txn, {
  required int rewardId,
  required Map<int, int> inventoryIds,
  required DateTime now,
  int quantity = 1,
}) async {
  final existingId = inventoryIds[rewardId];
  if (existingId != null) {
    await txn.rawUpdate(
      'UPDATE inventory_items SET quantity = quantity + ?, updated_at = ? WHERE id = ?',
      [quantity, now.toIso8601String(), existingId],
    );
    return existingId;
  }

  final rewardRows = await txn.query(
    'rewards',
    where: 'id = ?',
    whereArgs: [rewardId],
    limit: 1,
  );
  final reward = rewardRows.first;
  final inventoryItemId = await txn.insert('inventory_items', {
    'reward_id': rewardId,
    'name': reward['name'],
    'description': reward['description'],
    'icon': reward['icon'],
    'quantity': quantity,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  });
  inventoryIds[rewardId] = inventoryItemId;
  return inventoryItemId;
}

Future<void> _updateSkills(
  dynamic txn,
  Map<String, int> skillIds,
  Map<int, int> skillXp,
  DateTime now,
) async {
  for (final skillId in skillIds.values) {
    final totalXp = skillXp[skillId] ?? 0;
    final level = max(1, XPCalculator.calculateLevel(totalXp));
    final xpInLevel = XPCalculator.xpInCurrentLevel(totalXp, level);
    await txn.update(
      'skills',
      {
        'current_xp': xpInLevel,
        'level': level,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [skillId],
    );
  }
}

Future<void> _updatePlayer(
  dynamic txn,
  _SeedTotals totals,
  DateTime now,
) async {
  final level = XPCalculator.calculateLevel(totals.totalXp);
  final rewardPoints = max(0, totals.earnedRp - totals.spentRp + 250);
  totals.remainingRp = rewardPoints;

  await txn.update('player', {
    'name': 'Demo Month Hero',
    'title': 'Life Strategist',
    'description':
        'Seeded profile representing one month of continuous LifeRPG usage.',
    'total_xp': totals.totalXp,
    'level': level,
    'reward_points': rewardPoints,
    'current_energy': 68,
    'energy_mode': 'auto',
    'wake_up_time': '06:30',
    'sleep_time': '23:15',
    'updated_at': now.toIso8601String(),
  }, where: 'id = 1');
}

class _SeedTotals {
  int completedMissions = 0;
  int focusSessions = 0;
  int totalXp = 0;
  int earnedRp = 0;
  int spentRp = 0;
  int remainingRp = 0;
  final skillXp = <int, int>{};
}
