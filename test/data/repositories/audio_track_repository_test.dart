import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/audio_track.dart';
import 'package:liferpg/data/repositories/audio_track_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AudioTrackRepository tracks;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    tracks = AudioTrackRepository();
  });

  test('creates, updates, lists, and archives audio tracks', () async {
    final id = await tracks.insertTrack(
      AudioTrack(
        title: 'The First Track',
        artist: 'Bard',
        album: 'Tavern Songs',
        filePath: '/tmp/a.mp3',
      ),
    );

    var stored = await tracks.getTrackById(id);
    expect(stored!.title, 'The First Track');
    expect(stored.artist, 'Bard');
    expect(stored.album, 'Tavern Songs');
    expect(stored.duration, isNull);
    expect(stored.position, Duration.zero);
    expect(stored.progress, 0);

    await tracks.updateTrack(
      stored.copyWith(
        title: 'The Second Track',
        durationMs: 200000,
        positionMs: 50000,
      ),
    );

    stored = await tracks.getTrackById(id);
    expect(stored!.title, 'The Second Track');
    expect(stored.duration, const Duration(milliseconds: 200000));
    expect(stored.position, const Duration(milliseconds: 50000));
    expect(stored.progress, 0.25);

    expect(await tracks.getActiveTracks(), hasLength(1));
    await tracks.archiveTrack(id);
    expect(await tracks.getActiveTracks(), isEmpty);
    expect((await tracks.getTrackById(id))!.isActive, isFalse);
  });

  test('updates playback metadata', () async {
    final id = await tracks.insertTrack(
      AudioTrack(title: 'Progress Track', filePath: '/tmp/progress.mp3'),
    );

    await tracks.updatePlaybackProgress(
      id: id,
      position: const Duration(seconds: 30),
      duration: const Duration(minutes: 2),
    );

    var stored = await tracks.getTrackById(id);
    expect(stored!.position, const Duration(seconds: 30));
    expect(stored.duration, const Duration(minutes: 2));
    expect(stored.progress, 0.25);
    expect(stored.lastPlayedAt, isNull);

    await tracks.markPlayed(id);
    stored = await tracks.getTrackById(id);
    expect(stored!.lastPlayedAt, isNotNull);
  });

  test('backup and restore preserve audio track metadata', () async {
    final lastPlayedAt = DateTime(2026, 5, 13, 10);
    await tracks.insertTrack(
      AudioTrack(
        title: 'Restore Track',
        artist: 'Archivist',
        album: 'Portable Audio',
        filePath: '/tmp/restore.mp3',
        durationMs: 180000,
        positionMs: 45000,
        lastPlayedAt: lastPlayedAt,
      ),
    );

    final backup = await DatabaseHelper().getAllDataForBackup();
    expect(backup['audio_tracks'], hasLength(1));

    await DatabaseHelper().restoreData(backup);

    final restored = await tracks.getActiveTracks();
    expect(restored.single.title, 'Restore Track');
    expect(restored.single.artist, 'Archivist');
    expect(restored.single.album, 'Portable Audio');
    expect(restored.single.duration, const Duration(milliseconds: 180000));
    expect(restored.single.position, const Duration(milliseconds: 45000));
    expect(restored.single.lastPlayedAt, lastPlayedAt);
  });
}
