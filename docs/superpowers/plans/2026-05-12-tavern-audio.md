# Tavern Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build phase 3 `Tavern`: a local-first audio library with mobile background playback support.

**Architecture:** Add an `audio_tracks` SQLite table and expose it through model/repository/provider layers. Playback is isolated behind `TavernAudioService`, which wraps `audio_service` and `just_audio`; the UI only talks to `TavernProvider`.

**Tech Stack:** Flutter, Provider, sqflite/sqflite_common_ffi, file_picker, audio_service, just_audio, existing AppTheme/AppLocalizations.

---

## File Structure

- Create `lib/data/models/audio_track.dart`: typed `AudioTrack` model with persistence helpers and display helpers.
- Create `lib/data/repositories/audio_track_repository.dart`: CRUD, archive, progress update, last-played update.
- Modify `lib/data/database/database_helper.dart`: schema version 13, `audio_tracks`, backup/restore/reset.
- Create `lib/services/tavern_audio_service.dart`: `AudioHandler` facade plus testable playback interface.
- Create `lib/providers/tavern_provider.dart`: library state, search, import metadata, playback state, active track.
- Create `lib/ui/screens/tavern/tavern_screen.dart`: library-first screen with mini player.
- Modify `lib/main.dart`: initialize audio service and register `TavernProvider`.
- Modify navigation files: `lib/ui/screens/main_screen.dart`, `lib/ui/widgets/common/app_drawer.dart`, `lib/ui/widgets/common/liferpg_app_bar.dart`.
- Modify `lib/l10n/app_localizations.dart`: English, Portuguese, Spanish strings.
- Review Android/iOS generated plugin registrants after package install and keep the changes produced by Flutter tooling.
- Test files:
  - `test/data/repositories/audio_track_repository_test.dart`
  - `test/providers/tavern_provider_test.dart`
  - `test/ui/screens/tavern/tavern_screen_test.dart`
  - update `test/ui/screens/main_screen_mission_actions_test.dart`

---

### Task 1: Dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Review: platform plugin registrants changed by Flutter tooling

- [ ] Add playback dependencies.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/flutter pub add just_audio audio_service
```

Expected: `pubspec.yaml` includes direct dependencies in this shape:

```yaml
dependencies:
  audio_service: ^0.18.0
  just_audio: ^0.10.0
```

Do not pin exact versions manually if `flutter pub add` selects newer compatible versions.

- [ ] Verify dependency resolution.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/flutter pub get
```

Expected: exits `0`.

---

### Task 2: Audio Track Data Layer

**Files:**
- Create: `lib/data/models/audio_track.dart`
- Create: `lib/data/repositories/audio_track_repository.dart`
- Modify: `lib/data/database/database_helper.dart`
- Test: `test/data/repositories/audio_track_repository_test.dart`

- [ ] Write repository tests first.

Create `test/data/repositories/audio_track_repository_test.dart`:

```dart
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
        title: 'Campfire Song',
        artist: 'Bard',
        album: 'Tavern Songs',
        filePath: '/tmp/campfire.mp3',
        durationMs: 180000,
      ),
    );

    var stored = await tracks.getTrackById(id);
    expect(stored!.title, 'Campfire Song');
    expect(stored.artist, 'Bard');
    expect(stored.duration, const Duration(minutes: 3));

    await tracks.updateTrack(
      stored.copyWith(title: 'Night Campfire', positionMs: 30000),
    );

    stored = await tracks.getTrackById(id);
    expect(stored!.title, 'Night Campfire');
    expect(stored.position, const Duration(seconds: 30));

    expect(await tracks.getActiveTracks(), hasLength(1));
    await tracks.archiveTrack(id);
    expect(await tracks.getActiveTracks(), isEmpty);
    expect((await tracks.getTrackById(id))!.isActive, isFalse);
  });

  test('updates playback metadata', () async {
    final id = await tracks.insertTrack(
      AudioTrack(title: 'Progress', filePath: '/tmp/progress.mp3'),
    );

    await tracks.updatePlaybackProgress(
      id: id,
      position: const Duration(seconds: 42),
      duration: const Duration(minutes: 4),
    );
    await tracks.markPlayed(id);

    final stored = await tracks.getTrackById(id);
    expect(stored!.positionMs, 42000);
    expect(stored.durationMs, 240000);
    expect(stored.lastPlayedAt, isNotNull);
  });

  test('backup and restore preserve audio track metadata', () async {
    await tracks.insertTrack(
      AudioTrack(
        title: 'Restore Track',
        artist: 'Archivist',
        filePath: '/tmp/restore.mp3',
        positionMs: 12000,
      ),
    );

    final backup = await DatabaseHelper().getAllDataForBackup();
    expect(backup['audio_tracks'], hasLength(1));

    await DatabaseHelper().restoreData(backup);

    final restored = await tracks.getActiveTracks();
    expect(restored.single.title, 'Restore Track');
    expect(restored.single.positionMs, 12000);
  });
}
```

- [ ] Run the failing test.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/flutter test test/data/repositories/audio_track_repository_test.dart
```

Expected: fails because `AudioTrack` and `AudioTrackRepository` do not exist.

- [ ] Implement `AudioTrack`.

Create `lib/data/models/audio_track.dart`:

```dart
class AudioTrack {
  final int? id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final int? durationMs;
  final int positionMs;
  final bool isActive;
  final DateTime? lastPlayedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AudioTrack({
    this.id,
    required this.title,
    this.artist = '',
    this.album = '',
    required this.filePath,
    this.durationMs,
    this.positionMs = 0,
    this.isActive = true,
    this.lastPlayedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Duration? get duration =>
      durationMs == null ? null : Duration(milliseconds: durationMs!);

  Duration get position => Duration(milliseconds: positionMs);

  double get progress {
    final duration = durationMs;
    if (duration == null || duration <= 0 || positionMs <= 0) return 0;
    return (positionMs / duration).clamp(0, 1);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'file_path': filePath,
      'duration_ms': durationMs,
      'position_ms': positionMs,
      'is_active': isActive ? 1 : 0,
      'last_played_at': lastPlayedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AudioTrack.fromMap(Map<String, dynamic> map) {
    return AudioTrack(
      id: map['id'] as int?,
      title: map['title'] as String,
      artist: map['artist'] as String? ?? '',
      album: map['album'] as String? ?? '',
      filePath: map['file_path'] as String,
      durationMs: map['duration_ms'] as int?,
      positionMs: map['position_ms'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      lastPlayedAt: map['last_played_at'] == null
          ? null
          : DateTime.parse(map['last_played_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  AudioTrack copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    int? durationMs,
    bool clearDuration = false,
    int? positionMs,
    bool? isActive,
    DateTime? lastPlayedAt,
    bool clearLastPlayedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      durationMs: clearDuration ? null : durationMs ?? this.durationMs,
      positionMs: positionMs ?? this.positionMs,
      isActive: isActive ?? this.isActive,
      lastPlayedAt: clearLastPlayedAt
          ? null
          : lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

- [ ] Add schema version 13 and backup/restore hooks.

In `lib/data/database/database_helper.dart`:

```dart
version: 13,
```

Add `_createAudioTrackTables`:

```dart
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
```

Call it from `_onCreate` after `_createTomeTables(db)` and from `_onUpgrade`:

```dart
if (oldVersion < 13) {
  await _createAudioTrackTables(db);
}
```

In `getAllDataForBackup`, query and return:

```dart
final audioTracksMaps = await db.query('audio_tracks');
// ...
'audio_tracks': audioTracksMaps,
```

In `factoryReset` and `restoreData`, delete `audio_tracks` before parent tables:

```dart
await txn.delete('audio_tracks');
```

In `restoreData`, insert restored rows:

```dart
final audioTracks = data['audio_tracks'] as List<dynamic>?;
if (audioTracks != null) {
  for (final track in audioTracks) {
    await txn.insert('audio_tracks', track as Map<String, dynamic>);
  }
}
```

- [ ] Implement repository.

Create `lib/data/repositories/audio_track_repository.dart`:

```dart
import '../database/database_helper.dart';
import '../models/audio_track.dart';

class AudioTrackRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertTrack(AudioTrack track) async {
    final db = await _dbHelper.database;
    return db.insert('audio_tracks', track.toMap());
  }

  Future<List<AudioTrack>> getActiveTracks() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'audio_tracks',
      where: 'is_active = 1',
      orderBy: 'updated_at DESC',
    );
    return maps.map(AudioTrack.fromMap).toList();
  }

  Future<AudioTrack?> getTrackById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'audio_tracks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return AudioTrack.fromMap(maps.first);
  }

  Future<int> updateTrack(AudioTrack track) async {
    final db = await _dbHelper.database;
    return db.update(
      'audio_tracks',
      track.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [track.id],
    );
  }

  Future<int> archiveTrack(int id) async {
    final db = await _dbHelper.database;
    return db.update(
      'audio_tracks',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updatePlaybackProgress({
    required int id,
    required Duration position,
    Duration? duration,
  }) async {
    final db = await _dbHelper.database;
    return db.update(
      'audio_tracks',
      {
        'position_ms': position.inMilliseconds < 0
            ? 0
            : position.inMilliseconds,
        if (duration != null) 'duration_ms': duration.inMilliseconds,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markPlayed(int id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'audio_tracks',
      {'last_played_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

- [ ] Run repository tests.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/flutter test test/data/repositories/audio_track_repository_test.dart
```

Expected: all tests pass.

---

### Task 3: Playback Service

**Files:**
- Create: `lib/services/tavern_audio_service.dart`
- Modify: `lib/main.dart`

- [ ] Implement a testable playback abstraction and real service.

Create `lib/services/tavern_audio_service.dart`:

```dart
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models/audio_track.dart';

abstract class TavernPlayback {
  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;

  Future<Duration?> load(AudioTrack track);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
}

class TavernAudioService implements TavernPlayback {
  TavernAudioService(this._handler);

  final TavernAudioHandler _handler;

  @override
  Stream<bool> get playingStream =>
      _handler.playbackState.map((state) => state.playing).distinct();

  @override
  Stream<Duration> get positionStream => _handler.positionStream;

  @override
  Stream<Duration?> get durationStream => _handler.durationStream;

  @override
  Future<Duration?> load(AudioTrack track) => _handler.load(track);

  @override
  Future<void> play() => _handler.play();

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  @override
  Future<void> stop() => _handler.stop();
}

class TavernAudioHandler extends BaseAudioHandler with SeekHandler {
  TavernAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.durationStream.listen(_durationController.add);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playbackState.add(
          playbackState.value.copyWith(
            playing: false,
            processingState: AudioProcessingState.completed,
          ),
        );
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _durationController.stream;

  Future<Duration?> load(AudioTrack track) async {
    final item = MediaItem(
      id: track.filePath,
      title: track.title,
      artist: track.artist.isEmpty ? null : track.artist,
      album: track.album.isEmpty ? null : track.album,
      duration: track.duration,
    );
    mediaItem.add(item);
    final duration = await _player.setFilePath(
      track.filePath,
      initialPosition: track.position,
      tag: item,
    );
    _durationController.add(duration);
    return duration;
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      PlaybackState(
        controls: [
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }
}

Future<TavernAudioService> initTavernAudioService() async {
  final handler = await AudioService.init<TavernAudioHandler>(
    builder: TavernAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.liferpg.tavern.audio',
      androidNotificationChannelName: 'Tavern playback',
      androidNotificationOngoing: true,
    ),
  );
  return TavernAudioService(handler);
}
```

- [ ] Initialize the service before `runApp`.

In `lib/main.dart`, add:

```dart
import 'services/tavern_audio_service.dart';
```

Then initialize:

```dart
final tavernAudioService = await initTavernAudioService();

runApp(MyApp(tavernAudioService: tavernAudioService));
```

Update `MyApp`:

```dart
class MyApp extends StatelessWidget {
  final TavernPlayback tavernAudioService;

  const MyApp({super.key, required this.tavernAudioService});
```

Tests that instantiate `MyApp` must pass a fake service in Task 5.

---

### Task 4: Tavern Provider

**Files:**
- Create: `lib/providers/tavern_provider.dart`
- Test: `test/providers/tavern_provider_test.dart`

- [ ] Write provider tests with a fake playback service.

Create `test/providers/tavern_provider_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/audio_track.dart';
import 'package:liferpg/providers/tavern_provider.dart';
import 'package:liferpg/services/tavern_audio_service.dart';

class FakeTavernPlayback implements TavernPlayback {
  final playing = StreamController<bool>.broadcast();
  final position = StreamController<Duration>.broadcast();
  final duration = StreamController<Duration?>.broadcast();
  AudioTrack? loadedTrack;
  bool playCalled = false;
  bool pauseCalled = false;

  @override
  Stream<bool> get playingStream => playing.stream;

  @override
  Stream<Duration> get positionStream => position.stream;

  @override
  Stream<Duration?> get durationStream => duration.stream;

  @override
  Future<Duration?> load(AudioTrack track) async {
    loadedTrack = track;
    return const Duration(minutes: 3);
  }

  @override
  Future<void> play() async {
    playCalled = true;
    playing.add(true);
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    playing.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    this.position.add(position);
  }

  @override
  Future<void> stop() async {}

  Future<void> dispose() async {
    await playing.close();
    await position.close();
    await duration.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTavernPlayback playback;
  late TavernProvider provider;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    playback = FakeTavernPlayback();
    provider = TavernProvider(playback: playback);
  });

  tearDown(() async {
    await playback.dispose();
  });

  test('imports local audio metadata and filters tracks', () async {
    await provider.importTrackFromPath('/tmp/Campfire Song.mp3');
    await provider.importTrackFromPath('/tmp/Training Bell.wav');

    provider.setSearchQuery('campfire');

    expect(provider.filteredTracks, hasLength(1));
    expect(provider.filteredTracks.single.title, 'Campfire Song');
  });

  test('plays selected track and reflects playback streams', () async {
    final id = await provider.importTrackFromPath('/tmp/Bard.mp3');

    await provider.playTrack(provider.tracks.first);
    playback.position.add(const Duration(seconds: 10));
    playback.duration.add(const Duration(minutes: 3));
    await Future<void>.delayed(Duration.zero);

    expect(id, isNotNull);
    expect(playback.loadedTrack!.title, 'Bard');
    expect(playback.playCalled, isTrue);
    expect(provider.activeTrack!.title, 'Bard');
    expect(provider.isPlaying, isTrue);
    expect(provider.position, const Duration(seconds: 10));
    expect(provider.duration, const Duration(minutes: 3));
  });

  test('toggles play and pause', () async {
    await provider.importTrackFromPath('/tmp/Bard.mp3');
    await provider.playTrack(provider.tracks.first);

    await provider.togglePlayPause();
    expect(playback.pauseCalled, isTrue);
  });
}
```

- [ ] Implement provider.

Create `lib/providers/tavern_provider.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../data/models/audio_track.dart';
import '../data/repositories/audio_track_repository.dart';
import '../services/tavern_audio_service.dart';

class TavernProvider extends ChangeNotifier {
  TavernProvider({required TavernPlayback playback}) : _playback = playback {
    _subscriptions.add(
      _playback.playingStream.listen((value) {
        _isPlaying = value;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _playback.positionStream.listen((value) {
        _position = value;
        final id = _activeTrack?.id;
        if (id != null) {
          _repo.updatePlaybackProgress(
            id: id,
            position: value,
            duration: _duration,
          );
        }
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _playback.durationStream.listen((value) {
        _duration = value;
        notifyListeners();
      }),
    );
  }

  final TavernPlayback _playback;
  final AudioTrackRepository _repo = AudioTrackRepository();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<AudioTrack> _tracks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  AudioTrack? _activeTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;

  List<AudioTrack> get tracks => _tracks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  AudioTrack? get activeTrack => _activeTrack;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration? get duration => _duration;

  List<AudioTrack> get filteredTracks {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _tracks;
    return _tracks
        .where(
          (track) =>
              track.title.toLowerCase().contains(query) ||
              track.artist.toLowerCase().contains(query) ||
              track.album.toLowerCase().contains(query) ||
              p.basename(track.filePath).toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> loadTracks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tracks = await _repo.getActiveTracks();
    } catch (e) {
      debugPrint('Error loading audio tracks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  Future<int?> importTrackFromPath(String filePath) async {
    final name = p.basenameWithoutExtension(filePath).trim();
    if (name.isEmpty || filePath.trim().isEmpty) return null;
    final id = await _repo.insertTrack(
      AudioTrack(title: name, filePath: filePath),
    );
    await loadTracks();
    return id;
  }

  Future<void> playTrack(AudioTrack track) async {
    try {
      _activeTrack = track;
      _position = track.position;
      final duration = await _playback.load(track);
      _duration = duration ?? track.duration;
      if (track.id != null) {
        await _repo.markPlayed(track.id!);
        await _repo.updatePlaybackProgress(
          id: track.id!,
          position: _position,
          duration: _duration,
        );
      }
      await _playback.play();
      await loadTracks();
    } catch (e) {
      debugPrint('Error playing audio track: $e');
      rethrow;
    }
  }

  Future<void> togglePlayPause() async {
    if (_activeTrack == null) return;
    if (_isPlaying) {
      await _playback.pause();
    } else {
      await _playback.play();
    }
  }

  Future<void> seek(Duration position) => _playback.seek(position);

  Future<void> archiveTrack(int id) async {
    await _repo.archiveTrack(id);
    await loadTracks();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
```

- [ ] Run provider tests.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/flutter test test/providers/tavern_provider_test.dart
```

Expected: all tests pass.

---

### Task 5: UI and Navigation

**Files:**
- Create: `lib/ui/screens/tavern/tavern_screen.dart`
- Modify: `lib/main.dart`
- Modify: `lib/ui/screens/main_screen.dart`
- Modify: `lib/ui/widgets/common/app_drawer.dart`
- Modify: `lib/ui/widgets/common/liferpg_app_bar.dart`
- Modify: `lib/l10n/app_localizations.dart`
- Test: `test/ui/screens/tavern/tavern_screen_test.dart`
- Test update: `test/ui/screens/main_screen_mission_actions_test.dart`
- Test update: `test/widget_test.dart`

- [ ] Add localized strings.

Add keys in `lib/l10n/app_localizations.dart` for all locales:

```dart
'tavern': 'Tavern',
'import_audio': 'Import audio',
'search_audio': 'Search audio',
'no_audio_yet': 'No audio yet',
'no_audio_found': 'No audio found',
'tavern_empty_hint': 'Import audio to start your local Tavern library.',
'audio_file_unavailable': 'Selected audio file is unavailable.',
'audio_play_failed': 'Could not play this audio.',
'unknown_artist': 'Unknown artist',
'now_playing': 'Now playing',
```

Portuguese:

```dart
'tavern': 'Taverna',
'import_audio': 'Importar áudio',
'search_audio': 'Buscar áudio',
'no_audio_yet': 'Nenhum áudio ainda',
'no_audio_found': 'Nenhum áudio encontrado',
'tavern_empty_hint': 'Importe áudio para iniciar sua biblioteca local da Taverna.',
'audio_file_unavailable': 'O arquivo de áudio selecionado está indisponível.',
'audio_play_failed': 'Não foi possível tocar este áudio.',
'unknown_artist': 'Artista desconhecido',
'now_playing': 'Tocando agora',
```

Spanish:

```dart
'tavern': 'Taberna',
'import_audio': 'Importar audio',
'search_audio': 'Buscar audio',
'no_audio_yet': 'Aún no hay audio',
'no_audio_found': 'No se encontró audio',
'tavern_empty_hint': 'Importa audio para iniciar tu biblioteca local de Taberna.',
'audio_file_unavailable': 'El archivo de audio seleccionado no está disponible.',
'audio_play_failed': 'No se pudo reproducir este audio.',
'unknown_artist': 'Artista desconocido',
'now_playing': 'Reproduciendo',
```

- [ ] Write widget tests.

Create `test/ui/screens/tavern/tavern_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/audio_track.dart';
import 'package:liferpg/l10n/app_localizations.dart';
import 'package:liferpg/providers/tavern_provider.dart';
import 'package:liferpg/services/tavern_audio_service.dart';
import 'package:liferpg/ui/screens/tavern/tavern_screen.dart';

class FakePlayback implements TavernPlayback {
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Future<Duration?> load(AudioTrack track) async => track.duration;
  @override
  Future<void> pause() async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> stop() async {}
}

class FakeTavernProvider extends TavernProvider {
  FakeTavernProvider({
    required this.fakeTracks,
    this.fakeActiveTrack,
    this.fakeIsPlaying = false,
  }) : super(playback: FakePlayback());

  final List<AudioTrack> fakeTracks;
  final AudioTrack? fakeActiveTrack;
  final bool fakeIsPlaying;

  @override
  List<AudioTrack> get filteredTracks => fakeTracks;

  @override
  List<AudioTrack> get tracks => fakeTracks;

  @override
  AudioTrack? get activeTrack => fakeActiveTrack;

  @override
  bool get isPlaying => fakeIsPlaying;

  @override
  bool get isLoading => false;

  @override
  Future<void> loadTracks() async {}
}

void main() {
  testWidgets('shows tavern empty state and import action', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<TavernProvider>.value(
        value: FakeTavernProvider(fakeTracks: const []),
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TavernScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No audio yet'), findsOneWidget);
    expect(find.byTooltip('Import audio'), findsOneWidget);
  });

  testWidgets('renders track cards and mini player', (tester) async {
    final track = AudioTrack(
      id: 1,
      title: 'Campfire Song',
      artist: 'Bard',
      album: 'Tavern Songs',
      filePath: '/tmp/campfire.mp3',
      durationMs: 180000,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<TavernProvider>.value(
        value: FakeTavernProvider(
          fakeTracks: [track],
          fakeActiveTrack: track,
          fakeIsPlaying: true,
        ),
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TavernScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Campfire Song'), findsWidgets);
    expect(find.text('Bard · Tavern Songs'), findsOneWidget);
    expect(find.text('Now playing'), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });
}
```

- [ ] Implement `TavernScreen`.

Create `lib/ui/screens/tavern/tavern_screen.dart` with:

```dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/audio_track.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/tavern_provider.dart';

class TavernScreen extends StatefulWidget {
  const TavernScreen({super.key});

  @override
  State<TavernScreen> createState() => _TavernScreenState();
}

class _TavernScreenState extends State<TavernScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TavernProvider>().loadTracks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<TavernProvider>(
      builder: (context, provider, _) {
        final tracks = provider.filteredTracks;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('tavern-search-field'),
                      controller: _searchController,
                      onChanged: provider.setSearchQuery,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.surface,
                        hintText: l10n.translate('search_audio'),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: provider.searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: l10n.translate('search_clear'),
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: l10n.translate('import_audio'),
                    icon: const Icon(Icons.library_music_outlined),
                    onPressed: () => _pickAudio(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tracks.isEmpty
                  ? _TavernEmptyState(
                      message: provider.searchQuery.isEmpty
                          ? l10n.translate('no_audio_yet')
                          : l10n.translate('no_audio_found'),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        8,
                        4,
                        8,
                        provider.activeTrack == null ? 88 : 142,
                      ),
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return _TrackTile(
                          track: track,
                          selected: provider.activeTrack?.id == track.id,
                          onTap: () => _playTrack(context, track),
                          onArchive: track.id == null
                              ? null
                              : () => provider.archiveTrack(track.id!),
                        );
                      },
                    ),
            ),
            if (provider.activeTrack != null)
              _MiniPlayer(provider: provider, track: provider.activeTrack!),
          ],
        );
      },
    );
  }

  Future<void> _pickAudio(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
      allowMultiple: true,
    );
    if (!context.mounted || result == null) return;
    for (final file in result.files) {
      final path = file.path;
      if (path == null || path.isEmpty) continue;
      await context.read<TavernProvider>().importTrackFromPath(path);
    }
  }

  Future<void> _playTrack(BuildContext context, AudioTrack track) async {
    final l10n = AppLocalizations.of(context);
    try {
      await context.read<TavernProvider>().playTrack(track);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('audio_play_failed'))),
      );
    }
  }
}
```

Then add private widgets `_TavernEmptyState`, `_TrackTile`, and `_MiniPlayer` in the same file. Keep them compact, use `Icons.music_note`, `Icons.play_arrow`, `Icons.pause`, `LinearProgressIndicator`, and `PopupMenuButton` for archive. Format duration as `mm:ss` using a private helper.

- [ ] Register provider and navigation.

In `lib/main.dart`, register:

```dart
ChangeNotifierProvider(
  create: (_) => TavernProvider(playback: tavernAudioService)..loadTracks(),
),
```

In `MainScreen`:

- import `tavern/tavern_screen.dart`
- add `TavernScreen()` after `TomesScreen()`
- add `'tavern'` after `'tomes'`
- shift indexes after Tomes by `+1`
- hide header on Tavern like Notebooks/Tomes.

In drawer/app bar, add:

```dart
const _DrawerItem(labelKey: 'tavern', icon: Icons.local_bar_outlined),
```

and navigation destination:

```dart
_AppBarDestination(
  index: 3,
  label: l10n.translate('tavern'),
  icon: Icons.local_bar_outlined,
),
```

- [ ] Update existing tests that construct providers.

In `test/ui/screens/main_screen_mission_actions_test.dart`, add a `FakeTavernProvider`.

In `test/widget_test.dart`, update `MyApp` construction to pass a fake playback service after `MyApp` receives the required `tavernAudioService` constructor argument.

- [ ] Run UI tests.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/flutter test test/ui/screens/tavern/tavern_screen_test.dart test/ui/screens/main_screen_mission_actions_test.dart test/widget_test.dart
```

Expected: all tests pass.

---

### Task 6: Documentation and Verification

**Files:**
- Modify: `docs/project-guide.md`
- Optional modify: `docs/superpowers/specs/2026-05-12-tavern-audio-design.md` if implementation discovers a necessary clarification.

- [ ] Update project guide.

Add Tavern to product model, providers, schema table list, migration notes, and runtime setup:

```markdown
- Tavern is a local audio library/player with mobile background playback support.
- `TavernProvider`
- `audio_tracks`: local audio metadata and playback progress.
- A versão 13 adiciona `audio_tracks`.
```

- [ ] Run formatting.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/dart format lib test
```

Expected: exits `0`.

- [ ] Run static analysis.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/flutter analyze
```

Expected: `No issues found!`.

- [ ] Run the full test suite.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/flutter test
```

Expected: all tests pass.

- [ ] Build Linux debug.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/flutter build linux --debug
```

Expected: `✓ Built build/linux/x64/debug/bundle/liferpg`.

- [ ] Run app smoke test.

Run:

```bash
/home/cicero/fvm/versions/stable/bin/flutter run -d linux
```

Expected:

- app launches
- Tavern appears in navigation
- import button opens file picker
- selecting a supported audio file adds it to the list
- tapping the track starts playback
- mini player appears and toggles play/pause

The OSM warning from `flutter_map` is acceptable and unrelated.
