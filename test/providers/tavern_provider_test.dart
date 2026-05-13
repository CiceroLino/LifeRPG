import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/repositories/audio_track_repository.dart';
import 'package:liferpg/providers/tavern_provider.dart';
import 'package:liferpg/services/local_media_import_service.dart';
import 'package:liferpg/services/tavern_audio_service.dart';

class FakeTavernPlayback implements TavernPlayback {
  final _playingController = StreamController<bool>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _commandController =
      StreamController<TavernPlaybackCommand>.broadcast();

  AudioTrack? loadedTrack;
  Duration? loadedPosition;
  Duration? nextDuration;
  Duration? seekPosition;
  int loadCount = 0;
  int playCount = 0;
  int pauseCount = 0;
  int stopCount = 0;
  Object? loadError;
  Object? playError;

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<TavernPlaybackCommand> get commandStream => _commandController.stream;

  @override
  Future<Duration?> load(AudioTrack track) async {
    final error = loadError;
    if (error != null) throw error;
    loadCount += 1;
    loadedTrack = track;
    loadedPosition = track.position;
    return nextDuration;
  }

  @override
  Future<void> pause() async {
    pauseCount += 1;
    emitPlaying(false);
  }

  @override
  Future<void> play() async {
    final error = playError;
    if (error != null) throw error;
    playCount += 1;
    emitPlaying(true);
  }

  @override
  Future<void> seek(Duration position) async {
    seekPosition = position;
    emitPosition(position);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
    emitPlaying(false);
  }

  void emitPlaying(bool value) {
    _playingController.add(value);
  }

  void emitPosition(Duration value) {
    _positionController.add(value);
  }

  void emitDuration(Duration? value) {
    _durationController.add(value);
  }

  void emitCommand(TavernPlaybackCommand value) {
    _commandController.add(value);
  }

  Future<void> dispose() async {
    await _playingController.close();
    await _positionController.close();
    await _durationController.close();
    await _commandController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTavernPlayback playback;
  late TavernProvider provider;
  late AudioTrackRepository tracks;
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    tempDir = await Directory.systemTemp.createTemp('liferpg_tavern_provider_');
    playback = FakeTavernPlayback();
    provider = TavernProvider(
      playback: playback,
      mediaImporter: createLocalMediaImportService(basePath: tempDir.path),
    );
    tracks = AudioTrackRepository();
  });

  tearDown(() async {
    provider.dispose();
    await playback.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('imports local audio metadata and filters tracks', () async {
    final firstId = await provider.importTrackFromPath(
      '/tmp/music/Arcane Melody.mp3',
    );
    final secondId = await provider.importTrackFromPath(
      '/tmp/battle_theme.ogg',
    );

    expect(firstId, isNotNull);
    expect(secondId, isNotNull);
    expect(await provider.importTrackFromPath(''), isNull);
    expect(provider.tracks, hasLength(2));
    expect(
      provider.tracks.map((track) => track.title),
      contains('Arcane Melody'),
    );

    provider.setSearchQuery('battle');
    expect(provider.filteredTracks, hasLength(1));
    expect(provider.filteredTracks.single.title, 'battle_theme');

    provider.setSearchQuery('arcane melody.mp3');
    expect(provider.filteredTracks, hasLength(1));
    expect(
      provider.filteredTracks.single.filePath,
      '/tmp/music/Arcane Melody.mp3',
    );
  });

  test(
    'imports picked audio into managed storage before saving track',
    () async {
      final id = await provider.importTrack(
        PlatformFile(
          name: 'Rain Ambience.mp3',
          size: 4,
          readStream: Stream.value([4, 3, 2, 1]),
        ),
      );

      expect(id, isNotNull);
      expect(provider.tracks.single.title, 'Rain Ambience');
      expect(provider.tracks.single.filePath, contains('tavern'));
      expect(await File(provider.tracks.single.filePath).readAsBytes(), [
        4,
        3,
        2,
        1,
      ]);
    },
  );

  test('plays selected track and reflects playback streams', () async {
    final id = await provider.importTrackFromPath('/tmp/tavern-song.mp3');
    final stored = (await tracks.getTrackById(
      id!,
    ))!.copyWith(artist: 'Inn Bard', album: 'Evening Set', positionMs: 15000);
    await tracks.updateTrack(stored);
    await provider.loadTracks();

    playback.nextDuration = const Duration(minutes: 3);
    await provider.playTrack(provider.tracks.single);

    expect(provider.activeTrack!.id, id);
    expect(provider.position, const Duration(seconds: 15));
    expect(provider.duration, const Duration(minutes: 3));
    expect(playback.loadedTrack!.id, id);
    expect(playback.loadedPosition, const Duration(seconds: 15));
    expect(playback.playCount, 1);
    expect(provider.isPlaying, isTrue);

    playback.emitDuration(const Duration(minutes: 4));
    playback.emitPosition(const Duration(seconds: 45));
    await Future<void>.delayed(Duration.zero);

    expect(provider.position, const Duration(seconds: 45));
    expect(provider.duration, const Duration(minutes: 4));

    final persisted = await tracks.getTrackById(id);
    expect(persisted!.position, const Duration(seconds: 15));
    expect(persisted.duration, const Duration(minutes: 3));
    expect(persisted.lastPlayedAt, isNotNull);
  });

  test('position ticks persist only at controlled lifecycle points', () async {
    final id = await provider.importTrackFromPath('/tmp/progress.mp3');
    playback.nextDuration = const Duration(minutes: 2);
    await provider.playTrack((await tracks.getTrackById(id!))!);

    for (var i = 1; i <= 20; i += 1) {
      playback.emitPosition(Duration(seconds: i));
    }
    await Future<void>.delayed(Duration.zero);

    var persisted = await tracks.getTrackById(id);
    expect(provider.position, const Duration(seconds: 20));
    expect(persisted!.position, Duration.zero);

    await provider.togglePlayPause();

    persisted = await tracks.getTrackById(id);
    expect(persisted!.position, const Duration(seconds: 20));
    expect(persisted.duration, const Duration(minutes: 2));
  });

  test('system pause command persists current progress', () async {
    final id = await provider.importTrackFromPath('/tmp/system-pause.mp3');
    playback.nextDuration = const Duration(minutes: 5);
    await provider.playTrack((await tracks.getTrackById(id!))!);

    playback.emitPosition(const Duration(seconds: 35));
    await Future<void>.delayed(Duration.zero);

    playback.emitCommand(
      const TavernPlaybackCommand(TavernPlaybackCommandType.pause),
    );
    await Future<void>.delayed(Duration.zero);

    final persisted = await tracks.getTrackById(id);
    expect(persisted!.position, const Duration(seconds: 35));
    expect(persisted.duration, const Duration(minutes: 5));
  });

  test(
    'system stop command persists progress and clears active state',
    () async {
      final id = await provider.importTrackFromPath('/tmp/system-stop.mp3');
      await provider.playTrack((await tracks.getTrackById(id!))!);

      playback.emitPosition(const Duration(seconds: 41));
      await Future<void>.delayed(Duration.zero);

      playback.emitCommand(
        const TavernPlaybackCommand(TavernPlaybackCommandType.stop),
      );
      await Future<void>.delayed(Duration.zero);

      final persisted = await tracks.getTrackById(id);
      expect(persisted!.position, const Duration(seconds: 41));
      expect(provider.activeTrack, isNull);
      expect(provider.isPlaying, isFalse);
      expect(provider.position, Duration.zero);
    },
  );

  test('system seek command updates and persists progress', () async {
    final id = await provider.importTrackFromPath('/tmp/system-seek.mp3');
    await provider.playTrack((await tracks.getTrackById(id!))!);

    playback.emitCommand(
      const TavernPlaybackCommand(
        TavernPlaybackCommandType.seek,
        position: Duration(seconds: 72),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final persisted = await tracks.getTrackById(id);
    expect(provider.position, const Duration(seconds: 72));
    expect(persisted!.position, const Duration(seconds: 72));
  });

  test('playing active track again does not reload stale progress', () async {
    final id = await provider.importTrackFromPath('/tmp/no-reload.mp3');
    await provider.playTrack((await tracks.getTrackById(id!))!);

    playback.emitPosition(const Duration(seconds: 45));
    await Future<void>.delayed(Duration.zero);

    await provider.playTrack(provider.tracks.single);

    expect(playback.loadCount, 1);
    expect(provider.position, const Duration(seconds: 45));
  });

  test('toggles play and pause', () async {
    await provider.togglePlayPause();
    expect(playback.playCount, 0);
    expect(playback.pauseCount, 0);

    final id = await provider.importTrackFromPath('/tmp/toggle.mp3');
    await provider.playTrack((await tracks.getTrackById(id!))!);
    await Future<void>.delayed(Duration.zero);

    await provider.togglePlayPause();
    expect(playback.pauseCount, 1);
    expect(provider.isPlaying, isFalse);

    await provider.togglePlayPause();
    expect(playback.playCount, 2);
    expect(provider.isPlaying, isTrue);
  });

  test(
    'plays next and previous tracks from the current library order',
    () async {
      final firstId = await provider.importTrackFromPath('/tmp/first.mp3');
      final secondId = await provider.importTrackFromPath('/tmp/second.mp3');
      await provider.playTrack((await tracks.getTrackById(firstId!))!);

      playback.emitPosition(const Duration(seconds: 12));
      await Future<void>.delayed(Duration.zero);

      await provider.playNextTrack();

      expect(provider.activeTrack!.id, secondId);
      expect(playback.loadedTrack!.id, secondId);
      expect(
        (await tracks.getTrackById(firstId))!.position,
        const Duration(seconds: 12),
      );

      await provider.playPreviousTrack();

      expect(provider.activeTrack!.id, firstId);
      expect(playback.loadedTrack!.id, firstId);
    },
  );

  test(
    'cycles repeat mode and restarts active track on repeat one completion',
    () async {
      final id = await provider.importTrackFromPath('/tmp/repeat-one.mp3');
      await provider.playTrack((await tracks.getTrackById(id!))!);

      expect(provider.repeatMode, TavernRepeatMode.off);
      provider.cycleRepeatMode();
      expect(provider.repeatMode, TavernRepeatMode.all);
      provider.cycleRepeatMode();
      expect(provider.repeatMode, TavernRepeatMode.one);

      playback.emitCommand(
        const TavernPlaybackCommand(TavernPlaybackCommandType.completed),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(playback.seekPosition, Duration.zero);
      expect(provider.activeTrack!.id, id);
    },
  );

  test('shuffle next selects another track when possible', () async {
    final firstId = await provider.importTrackFromPath('/tmp/shuffle-a.mp3');
    final secondId = await provider.importTrackFromPath('/tmp/shuffle-b.mp3');
    final thirdId = await provider.importTrackFromPath('/tmp/shuffle-c.mp3');
    await provider.playTrack((await tracks.getTrackById(firstId!))!);

    provider.toggleShuffle();
    await provider.playNextTrack();

    expect(provider.shuffleEnabled, isTrue);
    expect(provider.activeTrack!.id, isNot(firstId));
    expect(provider.activeTrack!.id, isIn([secondId, thirdId]));
  });

  test(
    'completion with repeat off does not restart a single-track queue',
    () async {
      final id = await provider.importTrackFromPath('/tmp/no-repeat.mp3');
      await provider.playTrack((await tracks.getTrackById(id!))!);

      playback.emitPlaying(false);
      await Future<void>.delayed(Duration.zero);
      playback.emitCommand(
        const TavernPlaybackCommand(TavernPlaybackCommandType.completed),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(playback.loadCount, 1);
      expect(playback.playCount, 1);
      expect(playback.pauseCount, 1);
    },
  );

  test(
    'archiving active track stops playback and clears active state',
    () async {
      final id = await provider.importTrackFromPath('/tmp/archive-active.mp3');
      await provider.playTrack((await tracks.getTrackById(id!))!);
      playback.emitPosition(const Duration(seconds: 30));
      await Future<void>.delayed(Duration.zero);

      await provider.archiveTrack(id);

      expect(playback.stopCount, 1);
      expect(provider.activeTrack, isNull);
      expect(provider.isPlaying, isFalse);
      expect(provider.position, Duration.zero);
      expect(provider.duration, isNull);
      expect(provider.tracks, isEmpty);

      final persisted = await tracks.getTrackById(id);
      expect(persisted!.position, const Duration(seconds: 30));
      expect(persisted.isActive, isFalse);
    },
  );

  test('seek delegates to playback', () async {
    await provider.seek(const Duration(seconds: 12));

    expect(playback.seekPosition, const Duration(seconds: 12));
  });

  test('load failure clears stale active track and rethrows', () async {
    final id = await provider.importTrackFromPath('/tmp/broken.mp3');
    final track = (await tracks.getTrackById(id!))!;
    playback.loadError = StateError('load failed');

    await expectLater(
      () => provider.playTrack(track),
      throwsA(isA<StateError>()),
    );

    expect(provider.activeTrack, isNull);
    expect(provider.isPlaying, isFalse);
    expect(provider.position, Duration.zero);
    expect(provider.duration, isNull);
  });
}
