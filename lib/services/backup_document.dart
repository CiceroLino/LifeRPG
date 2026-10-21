import '../data/database/database_schema.dart';

/// A validated, detached backup. Raw JSON never reaches destructive writes.
class BackupDocument {
  BackupDocument._(this.player, this.tables);

  final Map<String, Object?> player;
  final Map<String, List<Map<String, Object?>>> tables;

  static const tableNames = [
    'skills',
    'missions',
    'mission_skills',
    'mission_completion_events',
    'mission_completion_skill_rewards',
    'rewards',
    'inventory_items',
    'reward_redemptions',
    'mission_reward_drops',
    'mission_completion_reward_drops',
    'focus_sessions',
    'notebooks',
    'notes',
    'tomes',
    'audio_tracks',
  ];

  static BackupDocument parse(Map<String, dynamic> data) {
    final format = data['formatVersion'];
    final legacy = format == null && data['version'] == '1.0';
    if (!legacy && (format != 2 || data['version'] != '2.0')) {
      throw const FormatException('Unsupported backup format.');
    }
    final schema = data['schemaVersion'];
    if ((!legacy && schema == null) ||
        (schema != null &&
            (schema is! int ||
                schema < 1 ||
                schema > DatabaseSchema.version))) {
      throw const FormatException('Unsupported database schema.');
    }
    Map<String, Object?> row(Object? value, String table) {
      if (value is! Map || value.keys.any((key) => key is! String)) {
        throw FormatException('Invalid row in $table.');
      }
      return Map<String, Object?>.from(value);
    }

    final player = row(data['player'], 'player');
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in tableNames) {
      final raw = data[table];
      if (raw == null &&
          legacy &&
          !data.containsKey(table) &&
          table != 'missions' &&
          table != 'skills') {
        tables[table] = [];
      } else {
        if (raw is! List)
          throw FormatException('Invalid or missing table: $table.');
        tables[table] = raw.map((value) => row(value, table)).toList();
      }
    }
    if (legacy &&
        schema == null &&
        tables['missions']!.any(
          (mission) =>
              !mission.containsKey('location_name') &&
              !mission.containsKey('notes'),
        )) {
      throw const FormatException(
        'Legacy mission scale is ambiguous. Specify its original schemaVersion before restoring.',
      );
    }
    if (schema is int && schema < 5) {
      for (final mission in tables['missions']!) {
        for (final field in ['difficulty', 'urgency', 'fear']) {
          final value = mission[field];
          if (value is! int || value < 1 || value > 5) {
            throw FormatException('Invalid legacy attribute: $field.');
          }
          mission[field] = value * 20;
        }
      }
    }
    _validateRow('player', player);
    if (player['id'] != 1)
      throw const FormatException('Backup requires player id 1.');
    for (final entry in tables.entries) {
      final ids = <int>{};
      for (final value in entry.value) {
        _validateRow(entry.key, value);
        if (entry.key != 'mission_skills' && !ids.add(value['id'] as int)) {
          throw FormatException('Duplicate id in ${entry.key}.');
        }
      }
    }
    final document = BackupDocument._(player, tables);
    document._validateReferences();
    return document;
  }

  static void _validateRow(String table, Map<String, Object?> row) {
    final columns = _columns[table]!.split(' ').toSet();
    for (final field in _required[table]!.split(' ')) {
      if (row[field] == null) throw FormatException('Missing $table.$field.');
    }
    for (final entry in row.entries) {
      final field = entry.key;
      final value = entry.value;
      if (!columns.contains(field))
        throw FormatException('Unknown $table.$field.');
      if (value == null) continue;
      if (_integerFields.contains(field)) {
        if (value is! int || value.abs() > 9007199254740991) {
          throw FormatException('Invalid integer $table.$field.');
        }
        final minimum =
            field == 'id' ||
                field.endsWith('_id') ||
                [
                  'level',
                  'quantity',
                  'total_pages',
                  'recurrence_interval',
                  'energy_required',
                  'planned_minutes',
                  'completed_minutes',
                ].contains(field)
            ? 1
            : 0;
        if (field != 'order_index' && value < minimum) {
          throw FormatException('Out of range: $table.$field.');
        }
        final maximum = switch (field) {
          'difficulty' ||
          'urgency' ||
          'fear' ||
          'current_energy' ||
          'chance_percent' => 100,
          'energy_required' => 5,
          'planned_minutes' || 'completed_minutes' => 240,
          'is_active' ||
          'is_recurring' ||
          'is_unlimited_stock' ||
          'was_awarded' => 1,
          _ => null,
        };
        if (maximum != null && value > maximum) {
          throw FormatException('Out of range: $table.$field.');
        }
      } else if (field == 'latitude' || field == 'longitude') {
        final limit = field == 'latitude' ? 90 : 180;
        if (value is! num || !value.isFinite || value.abs() > limit) {
          throw FormatException('Invalid $table.$field.');
        }
      } else {
        if (value is! String)
          throw FormatException('Invalid text $table.$field.');
        if ((field.endsWith('_at') || field == 'due_date') &&
            DateTime.tryParse(value) == null) {
          throw FormatException('Invalid date $table.$field.');
        }
      }
    }
    if (table == 'missions' &&
        row['status'] != null &&
        !['active', 'completed', 'archived'].contains(row['status'])) {
      throw const FormatException('Invalid mission status.');
    }
    if (table == 'player' &&
        row['energy_mode'] != null &&
        !['auto', 'manual'].contains(row['energy_mode'])) {
      throw const FormatException('Invalid energy mode.');
    }
    if (table == 'skills' &&
        row['color'] != null &&
        !RegExp(
          r'^#[a-fA-F0-9]{6}([a-fA-F0-9]{2})?$',
        ).hasMatch(row['color'] as String)) {
      throw const FormatException('Invalid skill color.');
    }
  }

  void _validateReferences() {
    final ids = {
      for (final table in tableNames)
        table: tables[table]!.map((row) => row['id']).whereType<int>().toSet(),
    };
    void reference(String table, String field, String target) {
      for (final row in tables[table]!) {
        final id = row[field];
        if (id != null && !ids[target]!.contains(id)) {
          throw FormatException('Missing reference $table.$field → $target.');
        }
      }
    }

    reference('missions', 'parent_mission_id', 'missions');
    reference('mission_skills', 'mission_id', 'missions');
    reference('mission_skills', 'skill_id', 'skills');
    reference('mission_completion_events', 'mission_id', 'missions');
    reference(
      'mission_completion_skill_rewards',
      'event_id',
      'mission_completion_events',
    );
    reference('mission_completion_skill_rewards', 'skill_id', 'skills');
    reference('inventory_items', 'reward_id', 'rewards');
    reference('reward_redemptions', 'reward_id', 'rewards');
    reference('reward_redemptions', 'inventory_item_id', 'inventory_items');
    reference('mission_reward_drops', 'mission_id', 'missions');
    reference('mission_reward_drops', 'reward_id', 'rewards');
    reference(
      'mission_completion_reward_drops',
      'event_id',
      'mission_completion_events',
    );
    reference('mission_completion_reward_drops', 'reward_id', 'rewards');
    reference(
      'mission_completion_reward_drops',
      'inventory_item_id',
      'inventory_items',
    );
    reference('notes', 'notebook_id', 'notebooks');
    final links = <String>{};
    for (final row in tables['mission_skills']!) {
      if (!links.add('${row['mission_id']}:${row['skill_id']}')) {
        throw const FormatException('Duplicate mission skill link.');
      }
    }
  }

  Map<String, dynamic> toMap() => {
    'version': '2.0',
    'formatVersion': 2,
    'schemaVersion': DatabaseSchema.version,
    'player': player,
    ...tables,
  };

  static const _required = {
    'player': 'id name title created_at updated_at',
    'skills': 'id name created_at updated_at',
    'missions': 'id title created_at updated_at',
    'mission_skills': 'mission_id skill_id',
    'mission_completion_events':
        'id mission_id mission_title_snapshot completed_at',
    'mission_completion_skill_rewards':
        'id event_id skill_id skill_name_snapshot',
    'rewards': 'id name price_rp created_at updated_at',
    'inventory_items': 'id name quantity created_at updated_at',
    'reward_redemptions': 'id reward_name_snapshot price_paid_rp redeemed_at',
    'mission_reward_drops':
        'id mission_id reward_id chance_percent quantity created_at updated_at',
    'mission_completion_reward_drops':
        'id event_id reward_id reward_name_snapshot',
    'focus_sessions':
        'id planned_minutes completed_minutes xp_granted status started_at completed_at',
    'notebooks': 'id name created_at updated_at',
    'notes': 'id notebook_id title created_at updated_at',
    'tomes': 'id title file_path current_page created_at updated_at',
    'audio_tracks': 'id title file_path position_ms created_at updated_at',
  };
  static const _integerFields = {
    'id',
    'total_xp',
    'level',
    'reward_points',
    'current_energy',
    'current_xp',
    'is_active',
    'difficulty',
    'urgency',
    'fear',
    'energy_required',
    'xp_reward',
    'estimated_duration',
    'is_recurring',
    'recurrence_interval',
    'streak',
    'parent_mission_id',
    'order_index',
    'mission_id',
    'skill_id',
    'xp_granted',
    'reward_points_granted',
    'resulting_streak',
    'event_id',
    'price_rp',
    'is_unlimited_stock',
    'stock_remaining',
    'reward_id',
    'quantity',
    'inventory_item_id',
    'price_paid_rp',
    'chance_percent',
    'was_awarded',
    'planned_minutes',
    'completed_minutes',
    'notebook_id',
    'current_page',
    'total_pages',
    'duration_ms',
    'position_ms',
  };
  static const _columns = {
    'player':
        'id name title description total_xp level reward_points avatar_path current_energy energy_mode wake_up_time sleep_time theme_mode created_at updated_at',
    'skills':
        'id name description current_xp level color icon is_active created_at updated_at',
    'missions':
        'id title description notes reminder_note difficulty urgency fear energy_required xp_reward reward_points status due_date estimated_duration is_recurring recurrence_type recurrence_interval last_completed_at streak parent_mission_id order_index icon emoji location_name latitude longitude reminder_at recurrence_days created_at updated_at completed_at',
    'mission_skills': 'mission_id skill_id',
    'mission_completion_events':
        'id mission_id mission_title_snapshot xp_granted reward_points_granted completed_at recurrence_type resulting_streak',
    'mission_completion_skill_rewards':
        'id event_id skill_id skill_name_snapshot xp_granted',
    'rewards':
        'id name description price_rp is_unlimited_stock stock_remaining icon is_active created_at updated_at',
    'inventory_items':
        'id reward_id name description icon quantity created_at updated_at',
    'reward_redemptions':
        'id reward_id inventory_item_id reward_name_snapshot reward_description_snapshot reward_icon_snapshot price_paid_rp redeemed_at',
    'mission_reward_drops':
        'id mission_id reward_id chance_percent quantity created_at updated_at',
    'mission_completion_reward_drops':
        'id event_id reward_id inventory_item_id reward_name_snapshot quantity chance_percent was_awarded',
    'focus_sessions':
        'id planned_minutes completed_minutes xp_granted status started_at completed_at',
    'notebooks': 'id name description is_active created_at updated_at',
    'notes': 'id notebook_id title body created_at updated_at',
    'tomes':
        'id title author description file_path current_page total_pages is_active last_opened_at created_at updated_at',
    'audio_tracks':
        'id title artist album file_path duration_ms position_ms is_active last_played_at created_at updated_at',
  };
}
