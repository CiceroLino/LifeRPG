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
      version: 2,
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
        current_energy INTEGER DEFAULT 5,
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
        completed_at TEXT,
        FOREIGN KEY(parent_mission_id) REFERENCES missions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_missions_status ON missions(status)');
    await db.execute('CREATE INDEX idx_missions_parent ON missions(parent_mission_id)');

    await db.execute('''
      CREATE TABLE mission_skills (
        mission_id INTEGER NOT NULL,
        skill_id INTEGER NOT NULL,
        PRIMARY KEY(mission_id, skill_id),
        FOREIGN KEY(mission_id) REFERENCES missions(id) ON DELETE CASCADE,
        FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE
      )
    ''');

    await db.insert('player', {
      'id': 1,
      'name': 'Player',
      'title': 'Adventurer',
      'total_xp': 0,
      'level': 1,
      'reward_points': 0,
      'current_energy': 5,
      'theme_mode': 'light',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final now = DateTime.now().toIso8601String();
    await db.insert('skills', {
      'name': 'Inteligência',
      'color': '#2196F3',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('skills', {
      'name': 'Força',
      'color': '#F44336',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('skills', {
      'name': 'Saúde',
      'color': '#4CAF50',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('skills', {
      'name': 'Social',
      'color': '#FF9800',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('skills', {
      'name': 'Criatividade',
      'color': '#9C27B0',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE player ADD COLUMN title TEXT NOT NULL DEFAULT "Adventurer"');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}