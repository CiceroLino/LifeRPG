import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'liferpg.db');

    return await openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
        difficulty INTEGER DEFAULT 10 CHECK(difficulty BETWEEN 0 AND 100),
        urgency INTEGER DEFAULT 10 CHECK(urgency BETWEEN 0 AND 100),
        fear INTEGER DEFAULT 10 CHECK(fear BETWEEN 0 AND 100),
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
        completed_at TEXT,
        FOREIGN KEY(parent_mission_id) REFERENCES missions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_missions_status ON missions(status)');
    await db.execute(
      'CREATE INDEX idx_missions_parent ON missions(parent_mission_id)',
    );

    await db.execute('''
      CREATE TABLE mission_skills (
        mission_id INTEGER NOT NULL,
        skill_id INTEGER NOT NULL,
        PRIMARY KEY(mission_id, skill_id),
        FOREIGN KEY(mission_id) REFERENCES missions(id) ON DELETE CASCADE,
        FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE
      )
    ''');

    await _createMissionCompletionHistoryTables(db);

    await _insertDefaultPlayer(db);
    await _insertDefaultSkills(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE player ADD COLUMN title TEXT NOT NULL DEFAULT "Adventurer"',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'UPDATE player SET current_energy = 100 WHERE current_energy < 100',
      );
      await db.execute(
        'ALTER TABLE player ADD COLUMN energy_mode TEXT DEFAULT "manual"',
      );
      await db.execute('ALTER TABLE player ADD COLUMN wake_up_time TEXT');
      await db.execute('ALTER TABLE player ADD COLUMN sleep_time TEXT');
    }
    if (oldVersion < 4) {
      await _createMissionCompletionHistoryTables(db);
    }
    if (oldVersion < 5) {
      await _migrateMissionAttributesToPercent(db);
    }
  }

  Future<void> _migrateMissionAttributesToPercent(Database db) async {
    await db.execute('''
      CREATE TABLE mission_skills_v5 AS
      SELECT mission_id, skill_id FROM mission_skills
    ''');
    await db.execute('''
      CREATE TABLE mission_completion_events_v5 AS
      SELECT * FROM mission_completion_events
    ''');
    await db.execute('''
      CREATE TABLE mission_completion_skill_rewards_v5 AS
      SELECT * FROM mission_completion_skill_rewards
    ''');

    await db.execute('DROP TABLE mission_completion_skill_rewards');
    await db.execute('DROP TABLE mission_completion_events');
    await db.execute('DROP TABLE mission_skills');
    await db.execute('ALTER TABLE missions RENAME TO missions_v4');

    await db.execute('''
      CREATE TABLE missions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        difficulty INTEGER DEFAULT 10 CHECK(difficulty BETWEEN 0 AND 100),
        urgency INTEGER DEFAULT 10 CHECK(urgency BETWEEN 0 AND 100),
        fear INTEGER DEFAULT 10 CHECK(fear BETWEEN 0 AND 100),
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
        completed_at TEXT,
        FOREIGN KEY(parent_mission_id) REFERENCES missions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      INSERT INTO missions (
        id,
        title,
        description,
        difficulty,
        urgency,
        fear,
        energy_required,
        xp_reward,
        reward_points,
        status,
        due_date,
        estimated_duration,
        is_recurring,
        recurrence_type,
        recurrence_interval,
        last_completed_at,
        streak,
        parent_mission_id,
        order_index,
        icon,
        emoji,
        created_at,
        updated_at,
        completed_at
      )
      SELECT
        id,
        title,
        description,
        CASE WHEN difficulty BETWEEN 1 AND 5 THEN difficulty * 20 ELSE difficulty END,
        CASE WHEN urgency BETWEEN 1 AND 5 THEN urgency * 20 ELSE urgency END,
        CASE WHEN fear BETWEEN 1 AND 5 THEN fear * 20 ELSE fear END,
        energy_required,
        xp_reward,
        reward_points,
        status,
        due_date,
        estimated_duration,
        is_recurring,
        recurrence_type,
        recurrence_interval,
        last_completed_at,
        streak,
        parent_mission_id,
        order_index,
        icon,
        emoji,
        created_at,
        updated_at,
        completed_at
      FROM missions_v4
    ''');

    await db.execute('DROP TABLE missions_v4');
    await db.execute('CREATE INDEX idx_missions_status ON missions(status)');
    await db.execute(
      'CREATE INDEX idx_missions_parent ON missions(parent_mission_id)',
    );

    await db.execute('''
      CREATE TABLE mission_skills (
        mission_id INTEGER NOT NULL,
        skill_id INTEGER NOT NULL,
        PRIMARY KEY(mission_id, skill_id),
        FOREIGN KEY(mission_id) REFERENCES missions(id) ON DELETE CASCADE,
        FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      INSERT INTO mission_skills (mission_id, skill_id)
      SELECT mission_id, skill_id FROM mission_skills_v5
    ''');
    await db.execute('DROP TABLE mission_skills_v5');

    await _createMissionCompletionHistoryTables(db);
    await db.execute('''
      INSERT INTO mission_completion_events (
        id,
        mission_id,
        mission_title_snapshot,
        xp_granted,
        reward_points_granted,
        completed_at,
        recurrence_type,
        resulting_streak
      )
      SELECT
        id,
        mission_id,
        mission_title_snapshot,
        xp_granted,
        reward_points_granted,
        completed_at,
        recurrence_type,
        resulting_streak
      FROM mission_completion_events_v5
    ''');
    await db.execute('''
      INSERT INTO mission_completion_skill_rewards (
        id,
        event_id,
        skill_id,
        skill_name_snapshot,
        xp_granted
      )
      SELECT
        id,
        event_id,
        skill_id,
        skill_name_snapshot,
        xp_granted
      FROM mission_completion_skill_rewards_v5
    ''');
    await db.execute('DROP TABLE mission_completion_events_v5');
    await db.execute('DROP TABLE mission_completion_skill_rewards_v5');
  }

  Future<void> _createMissionCompletionHistoryTables(
    DatabaseExecutor db,
  ) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mission_completion_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mission_id INTEGER NOT NULL,
        mission_title_snapshot TEXT NOT NULL,
        xp_granted INTEGER DEFAULT 0,
        reward_points_granted INTEGER DEFAULT 0,
        completed_at TEXT NOT NULL,
        recurrence_type TEXT,
        resulting_streak INTEGER DEFAULT 0,
        FOREIGN KEY(mission_id) REFERENCES missions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mission_completion_skill_rewards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        skill_id INTEGER NOT NULL,
        skill_name_snapshot TEXT NOT NULL,
        xp_granted INTEGER DEFAULT 0,
        FOREIGN KEY(event_id) REFERENCES mission_completion_events(id) ON DELETE CASCADE,
        FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_completion_events_mission ON mission_completion_events(mission_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_completion_events_completed_at ON mission_completion_events(completed_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_completion_skill_rewards_event ON mission_completion_skill_rewards(event_id)',
    );
  }

  Future<Map<String, dynamic>> getAllDataForBackup() async {
    final db = await database;

    final playerMaps = await db.query('player');
    final missionsMaps = await db.query('missions');
    final skillsMaps = await db.query('skills');
    final missionSkillsMaps = await db.query('mission_skills');
    final completionEventsMaps = await db.query('mission_completion_events');
    final completionSkillRewardsMaps = await db.query(
      'mission_completion_skill_rewards',
    );

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'player': playerMaps.isNotEmpty ? playerMaps.first : null,
      'missions': missionsMaps,
      'skills': skillsMaps,
      'mission_skills': missionSkillsMaps,
      'mission_completion_events': completionEventsMaps,
      'mission_completion_skill_rewards': completionSkillRewardsMaps,
    };
  }

  Future<void> resetCharacterStats() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update('player', {
      'total_xp': 0,
      'level': 1,
      'reward_points': 0,
      'current_energy': 100,
      'energy_mode': 'manual',
      'wake_up_time': null,
      'sleep_time': null,
      'updated_at': now,
    }, where: 'id = 1');
  }

  Future<void> factoryReset() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('mission_completion_skill_rewards');
      await txn.delete('mission_completion_events');
      await txn.delete('mission_skills');
      await txn.delete('missions');
      await txn.delete('skills');
      await txn.delete('player');
      await _insertDefaultPlayer(txn);
      await _insertDefaultSkills(txn);
    });
  }

  Future<void> restoreData(Map<String, dynamic> data) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('mission_completion_skill_rewards');
      await txn.delete('mission_completion_events');
      await txn.delete('mission_skills');
      await txn.delete('missions');
      await txn.delete('skills');
      await txn.delete('player');

      final playerData = data['player'] as Map<String, dynamic>?;
      if (playerData != null) {
        await txn.insert('player', playerData);
      }

      final skills = data['skills'] as List<dynamic>?;
      if (skills != null) {
        for (final skill in skills) {
          await txn.insert('skills', skill as Map<String, dynamic>);
        }
      }

      final missions = data['missions'] as List<dynamic>?;
      if (missions != null) {
        for (final mission in missions) {
          await txn.insert('missions', mission as Map<String, dynamic>);
        }
      }

      final missionSkills = data['mission_skills'] as List<dynamic>?;
      if (missionSkills != null) {
        for (final ms in missionSkills) {
          await txn.insert('mission_skills', ms as Map<String, dynamic>);
        }
      }

      final completionEvents =
          data['mission_completion_events'] as List<dynamic>?;
      if (completionEvents != null) {
        for (final event in completionEvents) {
          await txn.insert(
            'mission_completion_events',
            event as Map<String, dynamic>,
          );
        }
      }

      final completionSkillRewards =
          data['mission_completion_skill_rewards'] as List<dynamic>?;
      if (completionSkillRewards != null) {
        for (final reward in completionSkillRewards) {
          await txn.insert(
            'mission_completion_skill_rewards',
            reward as Map<String, dynamic>,
          );
        }
      }
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> resetForTesting() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'liferpg.db');
    await deleteDatabase(path);
    _database = await _initDatabase();
  }

  Future<void> _insertDefaultPlayer(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('player', {
      'id': 1,
      'name': 'Player',
      'title': 'Adventurer',
      'total_xp': 0,
      'level': 1,
      'reward_points': 0,
      'current_energy': 100,
      'energy_mode': 'manual',
      'theme_mode': 'light',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _insertDefaultSkills(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();
    final skills = [
      ('Inteligência', '#2196F3'),
      ('Força', '#F44336'),
      ('Saúde', '#4CAF50'),
      ('Social', '#FF9800'),
      ('Criatividade', '#9C27B0'),
    ];

    for (final (name, color) in skills) {
      await db.insert('skills', {
        'name': name,
        'color': color,
        'created_at': now,
        'updated_at': now,
      });
    }
  }
}
