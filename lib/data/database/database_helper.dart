import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../services/backup_document.dart';
import 'database_schema.dart';

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
      version: DatabaseSchema.version,
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
    await _createNotebookTables(db);
    await _createTomeTables(db);
    await _createAudioTrackTables(db);

    await _insertDefaultPlayer(db);
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
    if (oldVersion < 11) {
      await _createNotebookTables(db);
    }
    if (oldVersion < 12) {
      await _createTomeTables(db);
    }
    if (oldVersion < 13) {
      await _createAudioTrackTables(db);
    }
    if (oldVersion < 14) {
      await _addColumnIfMissing(db, 'focus_sessions', 'session_key', 'TEXT');
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_focus_session_key ON focus_sessions(session_key)',
      );
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
        session_key TEXT,
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
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_focus_session_key ON focus_sessions(session_key)',
    );
  }

  Future<void> _createNotebookTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notebooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        notebook_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(notebook_id) REFERENCES notebooks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notebooks_active ON notebooks(is_active)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_notebook ON notes(notebook_id)',
    );
  }

  Future<void> _createTomeTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT DEFAULT '',
        description TEXT DEFAULT '',
        file_path TEXT NOT NULL,
        current_page INTEGER NOT NULL DEFAULT 0 CHECK(current_page >= 0),
        total_pages INTEGER CHECK(total_pages IS NULL OR total_pages > 0),
        is_active INTEGER DEFAULT 1,
        last_opened_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tomes_active ON tomes(is_active)',
    );
  }

  Future<void> _createAudioTrackTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audio_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT DEFAULT '',
        album TEXT DEFAULT '',
        file_path TEXT NOT NULL,
        duration_ms INTEGER CHECK(duration_ms IS NULL OR duration_ms >= 0),
        position_ms INTEGER NOT NULL DEFAULT 0 CHECK(position_ms >= 0),
        is_active INTEGER DEFAULT 1,
        last_played_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audio_tracks_active ON audio_tracks(is_active)',
    );
  }

  Future<Map<String, dynamic>> getAllDataForBackup() async {
    final db = await database;
    return db.transaction((txn) async {
      final players = await txn.query('player');
      final data = <String, dynamic>{
        'version': '2.0',
        'formatVersion': 2,
        'schemaVersion': DatabaseSchema.version,
        'timestamp': DateTime.now().toIso8601String(),
        'player': players.isEmpty ? null : players.single,
      };
      for (final table in BackupDocument.tableNames) {
        data[table] = await txn.query(table);
      }
      return data;
    });
  }

  Future<void> resetCharacterStats() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update('player', {
      'name': 'Player',
      'title': 'Adventurer',
      'description': '',
      'total_xp': 0,
      'level': 1,
      'reward_points': 0,
      'avatar_path': null,
      'current_energy': 100,
      'energy_mode': 'manual',
      'wake_up_time': null,
      'sleep_time': null,
      'updated_at': now,
    }, where: 'id = 1');
  }

  Future<void> _clearData(DatabaseExecutor txn) async {
    for (final table in BackupDocument.tableNames.reversed) {
      await txn.delete(table);
    }
    await txn.delete('player');
  }

  Future<void> factoryReset() async {
    final db = await database;
    await db.transaction((txn) async {
      await _clearData(txn);
      await _insertDefaultPlayer(txn);
    });
  }

  Future<void> restoreData(Map<String, dynamic> data) async {
    final backup = BackupDocument.parse(data);
    final db = await database;
    await db.transaction((txn) async {
      await _clearData(txn);
      await txn.insert('player', backup.player);
      for (final table in BackupDocument.tableNames) {
        for (final row in backup.tables[table]!) {
          await txn.insert(table, row);
        }
      }
      if ((await txn.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
        throw const FormatException('Restored data violates foreign keys.');
      }
    });
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
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
}
