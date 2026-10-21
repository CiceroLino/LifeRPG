import '../database/data_operations.dart';
import '../database/database_helper.dart';
import '../models/audio_track.dart';

class AudioTrackRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertTrack(AudioTrack track) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        return db.insert('audio_tracks', track.toMap());
      }, readOnly: false);

  Future<List<AudioTrack>> getActiveTracks() =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final maps = await db.query(
          'audio_tracks',
          where: 'is_active = 1',
          orderBy: 'updated_at DESC',
        );
        return maps.map(AudioTrack.fromMap).toList();
      }, readOnly: true);

  Future<AudioTrack?> getTrackById(int id) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        final maps = await db.query(
          'audio_tracks',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (maps.isEmpty) return null;
        return AudioTrack.fromMap(maps.first);
      }, readOnly: true);

  Future<int> updateTrack(AudioTrack track) =>
      DataOperations.instance.run(() async {
        final db = await _dbHelper.database;
        return db.update(
          'audio_tracks',
          track.copyWith(updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [track.id],
        );
      }, readOnly: false);

  Future<int> archiveTrack(int id) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    return db.update(
      'audio_tracks',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }, readOnly: false);

  Future<int> updatePlaybackProgress({
    required int id,
    required Duration position,
    Duration? duration,
  }) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    final values = <String, dynamic>{
      'position_ms': position.inMilliseconds,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (duration != null) {
      values['duration_ms'] = duration.inMilliseconds;
    }
    return db.update('audio_tracks', values, where: 'id = ?', whereArgs: [id]);
  }, readOnly: false);

  Future<int> markPlayed(int id) => DataOperations.instance.run(() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'audio_tracks',
      {'last_played_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }, readOnly: false);
}
