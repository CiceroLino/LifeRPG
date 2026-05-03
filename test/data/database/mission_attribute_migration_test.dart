import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().close();
    final path = join(await getDatabasesPath(), 'liferpg.db');
    await deleteDatabase(path);
  });

  test('upgrades stored 1-5 mission attributes to 0-100 percentages', () async {
    final path = join(await getDatabasesPath(), 'liferpg.db');
    final oldDb = await openDatabase(
      path,
      version: 4,
      onCreate: (db, _) async {
        await db.execute('''
        CREATE TABLE player (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          name TEXT NOT NULL DEFAULT 'Player',
          title TEXT NOT NULL DEFAULT 'Adventurer',
          total_xp INTEGER DEFAULT 0,
          level INTEGER DEFAULT 1,
          reward_points INTEGER DEFAULT 0,
          avatar_path TEXT,
          current_energy INTEGER DEFAULT 100,
          energy_mode TEXT DEFAULT 'manual',
          wake_up_time TEXT,
          sleep_time TEXT,
          theme_mode TEXT DEFAULT 'light',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
        await db.execute('''
        CREATE TABLE skills (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          current_xp INTEGER DEFAULT 0,
          level INTEGER DEFAULT 1,
          color TEXT DEFAULT '#2196F3',
          icon TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
        await db.execute('''
        CREATE TABLE missions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          difficulty INTEGER DEFAULT 1 CHECK(difficulty BETWEEN 1 AND 5),
          urgency INTEGER DEFAULT 1 CHECK(urgency BETWEEN 1 AND 5),
          fear INTEGER DEFAULT 1 CHECK(fear BETWEEN 1 AND 5),
          energy_required INTEGER DEFAULT 1 CHECK(energy_required BETWEEN 1 AND 5),
          xp_reward INTEGER DEFAULT 10,
          reward_points INTEGER DEFAULT 5,
          status TEXT DEFAULT 'active',
          due_date TEXT,
          estimated_duration INTEGER,
          is_recurring INTEGER DEFAULT 0,
          recurrence_type TEXT,
          recurrence_interval INTEGER,
          last_completed_at TEXT,
          streak INTEGER DEFAULT 0,
          parent_mission_id INTEGER,
          order_index INTEGER DEFAULT 0,
          icon TEXT,
          emoji TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          completed_at TEXT
        )
      ''');
        await db.execute('''
        CREATE TABLE mission_skills (
          mission_id INTEGER NOT NULL,
          skill_id INTEGER NOT NULL,
          PRIMARY KEY(mission_id, skill_id)
        )
      ''');
        await db.execute('''
        CREATE TABLE mission_completion_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mission_id INTEGER NOT NULL,
          mission_title_snapshot TEXT NOT NULL,
          xp_granted INTEGER DEFAULT 0,
          reward_points_granted INTEGER DEFAULT 0,
          completed_at TEXT NOT NULL,
          recurrence_type TEXT,
          resulting_streak INTEGER DEFAULT 0
        )
      ''');
        await db.execute('''
        CREATE TABLE mission_completion_skill_rewards (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          skill_id INTEGER NOT NULL,
          skill_name_snapshot TEXT NOT NULL,
          xp_granted INTEGER DEFAULT 0
        )
      ''');
        final now = DateTime(2026).toIso8601String();
        await db.insert('missions', {
          'title': 'Legacy mission',
          'description': '',
          'difficulty': 2,
          'urgency': 3,
          'fear': 5,
          'energy_required': 1,
          'xp_reward': 10,
          'reward_points': 5,
          'status': 'active',
          'is_recurring': 0,
          'streak': 0,
          'order_index': 0,
          'created_at': now,
          'updated_at': now,
        });
      },
    );
    await oldDb.close();

    await DatabaseHelper().database;
    final mission = (await MissionRepository().getAll()).single;

    expect(mission.difficulty, 40);
    expect(mission.urgency, 60);
    expect(mission.fear, 100);
  });
}
