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
      version: 10,
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
        description TEXT DEFAULT '',
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
        notes TEXT DEFAULT '',
        reminder_note TEXT DEFAULT '',
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
        location_name TEXT,
        latitude REAL,
        longitude REAL,
        reminder_at TEXT,
        recurrence_days TEXT,
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
    await _createRewardInventoryTables(db);
    await _createMissionRewardDropTables(db);
    await _createFocusSessionTables(db);

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
    if (oldVersion < 6) {
      await _createRewardInventoryTables(db);
    }
    if (oldVersion < 7) {
      await _migrateStrategyV7(db);
    }
    if (oldVersion < 8) {
      await _migrateMissionNotesV8(db);
    }
    if (oldVersion < 9) {
      await _createFocusSessionTables(db);
    }
    if (oldVersion < 10) {
      await _addColumnIfMissing(db, 'player', 'description', "TEXT DEFAULT ''");
    }
  }

  Future<void> _migrateMissionNotesV8(Database db) async {
    await _addColumnIfMissing(db, 'missions', 'notes', 'TEXT DEFAULT ""');
    await _addColumnIfMissing(
      db,
      'missions',
      'reminder_note',
      'TEXT DEFAULT ""',
    );
  }

  Future<void> _migrateStrategyV7(Database db) async {
    await _addColumnIfMissing(db, 'missions', 'location_name', 'TEXT');
    await _addColumnIfMissing(db, 'missions', 'latitude', 'REAL');
    await _addColumnIfMissing(db, 'missions', 'longitude', 'REAL');
    await _addColumnIfMissing(db, 'missions', 'reminder_at', 'TEXT');
    await _addColumnIfMissing(db, 'missions', 'recurrence_days', 'TEXT');
    await _createMissionRewardDropTables(db);
  }

  Future<void> _addColumnIfMissing(
    DatabaseExecutor db,
    String table,
    String column,
    String type,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
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
        notes TEXT DEFAULT '',
        reminder_note TEXT DEFAULT '',
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

  Future<void> _createRewardInventoryTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rewards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        price_rp INTEGER NOT NULL CHECK(price_rp >= 0),
        is_unlimited_stock INTEGER DEFAULT 1,
        stock_remaining INTEGER,
        icon TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reward_id INTEGER,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        icon TEXT,
        quantity INTEGER NOT NULL DEFAULT 1 CHECK(quantity > 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(reward_id) REFERENCES rewards(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS reward_redemptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reward_id INTEGER,
        inventory_item_id INTEGER,
        reward_name_snapshot TEXT NOT NULL,
        reward_description_snapshot TEXT DEFAULT '',
        reward_icon_snapshot TEXT,
        price_paid_rp INTEGER NOT NULL,
        redeemed_at TEXT NOT NULL,
        FOREIGN KEY(reward_id) REFERENCES rewards(id) ON DELETE SET NULL,
        FOREIGN KEY(inventory_item_id) REFERENCES inventory_items(id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_rewards_active ON rewards(is_active)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_reward ON inventory_items(reward_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_redemptions_reward ON reward_redemptions(reward_id)',
    );
  }

  Future<void> _createMissionRewardDropTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mission_reward_drops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mission_id INTEGER NOT NULL,
        reward_id INTEGER NOT NULL,
        chance_percent INTEGER NOT NULL DEFAULT 100 CHECK(chance_percent BETWEEN 0 AND 100),
        quantity INTEGER NOT NULL DEFAULT 1 CHECK(quantity > 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(mission_id) REFERENCES missions(id) ON DELETE CASCADE,
        FOREIGN KEY(reward_id) REFERENCES rewards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mission_completion_reward_drops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        reward_id INTEGER NOT NULL,
        inventory_item_id INTEGER,
        reward_name_snapshot TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        chance_percent INTEGER NOT NULL DEFAULT 0,
        was_awarded INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(event_id) REFERENCES mission_completion_events(id) ON DELETE CASCADE,
        FOREIGN KEY(reward_id) REFERENCES rewards(id) ON DELETE SET NULL,
        FOREIGN KEY(inventory_item_id) REFERENCES inventory_items(id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mission_reward_drops_mission ON mission_reward_drops(mission_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_completion_reward_drops_event ON mission_completion_reward_drops(event_id)',
    );
  }

  Future<void> _createFocusSessionTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        planned_minutes INTEGER NOT NULL CHECK(planned_minutes BETWEEN 1 AND 240),
        completed_minutes INTEGER NOT NULL CHECK(completed_minutes BETWEEN 1 AND 240),
        xp_granted INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'completed',
        started_at TEXT NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_focus_sessions_completed_at ON focus_sessions(completed_at)',
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
    final rewardsMaps = await db.query('rewards');
    final inventoryItemsMaps = await db.query('inventory_items');
    final rewardRedemptionsMaps = await db.query('reward_redemptions');
    final missionRewardDropsMaps = await db.query('mission_reward_drops');
    final completionRewardDropsMaps = await db.query(
      'mission_completion_reward_drops',
    );
    final focusSessionsMaps = await db.query('focus_sessions');

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'player': playerMaps.isNotEmpty ? playerMaps.first : null,
      'missions': missionsMaps,
      'skills': skillsMaps,
      'mission_skills': missionSkillsMaps,
      'mission_completion_events': completionEventsMaps,
      'mission_completion_skill_rewards': completionSkillRewardsMaps,
      'rewards': rewardsMaps,
      'inventory_items': inventoryItemsMaps,
      'reward_redemptions': rewardRedemptionsMaps,
      'mission_reward_drops': missionRewardDropsMaps,
      'mission_completion_reward_drops': completionRewardDropsMaps,
      'focus_sessions': focusSessionsMaps,
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
      await txn.delete('reward_redemptions');
      await txn.delete('focus_sessions');
      await txn.delete('mission_completion_reward_drops');
      await txn.delete('mission_reward_drops');
      await txn.delete('inventory_items');
      await txn.delete('rewards');
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
      await txn.delete('reward_redemptions');
      await txn.delete('focus_sessions');
      await txn.delete('mission_completion_reward_drops');
      await txn.delete('mission_reward_drops');
      await txn.delete('inventory_items');
      await txn.delete('rewards');
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

      final rewards = data['rewards'] as List<dynamic>?;
      if (rewards != null) {
        for (final reward in rewards) {
          await txn.insert('rewards', reward as Map<String, dynamic>);
        }
      }

      final missionRewardDrops = data['mission_reward_drops'] as List<dynamic>?;
      if (missionRewardDrops != null) {
        for (final drop in missionRewardDrops) {
          await txn.insert(
            'mission_reward_drops',
            drop as Map<String, dynamic>,
          );
        }
      }

      final inventoryItems = data['inventory_items'] as List<dynamic>?;
      if (inventoryItems != null) {
        for (final item in inventoryItems) {
          await txn.insert('inventory_items', item as Map<String, dynamic>);
        }
      }

      final rewardRedemptions = data['reward_redemptions'] as List<dynamic>?;
      if (rewardRedemptions != null) {
        for (final redemption in rewardRedemptions) {
          await txn.insert(
            'reward_redemptions',
            redemption as Map<String, dynamic>,
          );
        }
      }

      final completionRewardDrops =
          data['mission_completion_reward_drops'] as List<dynamic>?;
      if (completionRewardDrops != null) {
        for (final drop in completionRewardDrops) {
          await txn.insert(
            'mission_completion_reward_drops',
            drop as Map<String, dynamic>,
          );
        }
      }

      final focusSessions = data['focus_sessions'] as List<dynamic>?;
      if (focusSessions != null) {
        for (final session in focusSessions) {
          await txn.insert('focus_sessions', session as Map<String, dynamic>);
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
      'description': '',
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
