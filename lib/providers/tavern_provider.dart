import '../data/database/data_operations.dart';
import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../data/repositories/audio_track_repository.dart';
import '../services/local_media_import_service.dart';
import '../services/tavern_audio_service.dart';

enum TavernRepeatMode { off, all, one }

class TavernProvider extends ChangeNotifier {
  final AudioTrackRepository _repo;
  final LocalMediaImportService _mediaImporter;
  final TavernPlayback _playback;
  late final StreamSubscription<bool> _playingSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  late final StreamSubscription<TavernPlaybackCommand> _commandSubscription;

  List<AudioTrack> _tracks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  AudioTrack? _activeTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _shuffleEnabled = false;
  TavernRepeatMode _repeatMode = TavernRepeatMode.off;
  bool _disposed = false;
  String? _error;
  int _playRequest = 0;
  int _loadRequest = 0;
  String? get error => _error;
  final Random _random = Random();

  TavernProvider({
    required TavernPlayback playback,
    AudioTrackRepository? repo,
    LocalMediaImportService? mediaImporter,
  }) : _repo = repo ?? AudioTrackRepository(),
       _mediaImporter = mediaImporter ?? createLocalMediaImportService(),
       _playback = playback {
    _playingSubscription = _playback.playingStream.listen((isPlaying) {
      _isPlaying = isPlaying;
      _notify();
    });
    _positionSubscription = _playback.positionStream.listen((position) {
      _position = position;
      _notify();
    });
    _durationSubscription = _playback.durationStream.listen((duration) {
      _duration = duration;
      _notify();
    });
    _commandSubscription = _playback.commandStream.listen((command) {
      if (DataOperations.instance.isReplacing) return;
      unawaited(
        _handlePlaybackCommand(command).catchError((Object error) {
          debugPrint('Error handling playback command: $error');
        }),
      );
    });
  }

  List<AudioTrack> get tracks => _tracks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  AudioTrack? get activeTrack => _activeTrack;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration? get duration => _duration;
  bool get shuffleEnabled => _shuffleEnabled;
  TavernRepeatMode get repeatMode => _repeatMode;

  List<AudioTrack> get filteredTracks {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _tracks;

    return _tracks
        .where(
          (track) =>
              track.title.toLowerCase().contains(query) ||
              track.artist.toLowerCase().contains(query) ||
              track.album.toLowerCase().contains(query) ||
              path.basename(track.filePath).toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> loadTracks() => DataOperations.instance.run(() async {
    _isLoading = true;
    _notify();
    try {
      _tracks = await _repo.getActiveTracks();
    } catch (e) {
      debugPrint('Error loading audio tracks: $e');
    } finally {
      _isLoading = false;
      _notify();
    }
  }, readOnly: true);

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    _notify();
  }

  Future<int?> importTrackFromPath(String filePath) =>
      DataOperations.instance.run(() async {
        final trimmedPath = filePath.trim();
        final title = path.basenameWithoutExtension(trimmedPath).trim();
        if (trimmedPath.isEmpty || title.isEmpty) return null;
        try {
          final id = await _repo.insertTrack(
            AudioTrack(title: title, filePath: trimmedPath),
          );
          await loadTracks();
          return id;
        } catch (e) {
          debugPrint('Error importing audio track: $e');
          return null;
        }
      }, readOnly: false);

  Future<int?> importTrack(PlatformFile file) => DataOperations.instance.run(
    () async {
      try {
        final imported = await _mediaImporter.importPlatformFile(
          file,
          library: LocalMediaLibrary.tavern,
          allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
        );
        int id;
        try {
          id = await _repo.insertTrack(
            AudioTrack(title: imported.title, filePath: imported.path),
          );
        } catch (_) {
          await _mediaImporter.discardImport(imported);
          rethrow;
        }
        await loadTracks();
        return id;
      } catch (e) {
        debugPrint('Error importing audio track: $e');
        return null;
      }
    },
    readOnly: false,
  );

  Future<void> playTrack(AudioTrack track) =>
      DataOperations.instance.run(() async {
        if (_isSameTrack(track)) {
          if (!_isPlaying) {
            try {
              _requestPlay();
            } catch (e) {
              debugPrint('Error resuming audio track: $e');
              rethrow;
            }
          }
          return;
        }
        final request = ++_loadRequest;
        final previousTrack = _activeTrack;
        final previousPosition = _position;
        final previousDuration = _duration;
        final previousIsPlaying = _isPlaying;
        if (previousTrack != null) {
          await _persistActiveProgress();
        }
        _activeTrack = track;
        _position = track.position;
        _duration = track.duration;
        _notify();
        try {
          final loadedDuration = await _playback.load(track);
          if (request != _loadRequest) return;
          _duration = loadedDuration;
          _requestPlay();
          final id = track.id;
          if (id != null) {
            await _repo.markPlayed(id);
            await _repo.updatePlaybackProgress(
              id: id,
              position: _position,
              duration: _duration,
            );
          }
          await loadTracks();
        } catch (e) {
          if (request != _loadRequest) return;
          _activeTrack = previousTrack;
          _position = previousTrack == null ? Duration.zero : previousPosition;
          _duration = previousTrack == null ? null : previousDuration;
          _isPlaying = previousTrack == null ? false : previousIsPlaying;
          _notify();
          debugPrint('Error playing audio track: $e');
          rethrow;
        } finally {
          _notify();
        }
      }, readOnly: false);

  Future<void> togglePlayPause() => DataOperations.instance.run(() async {
    if (_activeTrack == null) return;
    try {
      if (_isPlaying) {
        await _persistActiveProgress();
        await _playback.pause();
      } else {
        _requestPlay();
      }
    } catch (e) {
      debugPrint('Error toggling tavern playback: $e');
    }
  }, readOnly: false);

  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    _notify();
  }

  void cycleRepeatMode() {
    _repeatMode = switch (_repeatMode) {
      TavernRepeatMode.off => TavernRepeatMode.all,
      TavernRepeatMode.all => TavernRepeatMode.one,
      TavernRepeatMode.one => TavernRepeatMode.off,
    };
    _notify();
  }

  Future<void> playNextTrack({bool fromCompletion = false}) =>
      DataOperations.instance.run(() async {
        final activeTrack = _activeTrack;
        if (activeTrack == null) return;
        if (fromCompletion && _repeatMode == TavernRepeatMode.one) {
          await _restartActiveTrack();
          return;
        }
        final nextTrack = _selectNextTrack(activeTrack, fromCompletion);
        if (nextTrack == null) {
          if (fromCompletion) {
            await _persistActiveProgress();
            await _playback.pause();
          }
          return;
        }
        if (_isSameTrack(nextTrack)) {
          await _restartActiveTrack();
        } else {
          await playTrack(nextTrack);
        }
      }, readOnly: false);

  Future<void> playPreviousTrack() => DataOperations.instance.run(() async {
    final activeTrack = _activeTrack;
    if (activeTrack == null) return;
    final previousTrack = _selectPreviousTrack(activeTrack);
    if (previousTrack == null) return;
    await playTrack(previousTrack);
  }, readOnly: false);

  Future<void> seek(Duration position) => DataOperations.instance.run(() async {
    try {
      _position = position;
      _notify();
      await _playback.seek(position);
      await _persistActiveProgress();
    } catch (e) {
      debugPrint('Error seeking tavern playback: $e');
    }
  }, readOnly: false);

  Future<void> archiveTrack(int id) => DataOperations.instance.run(() async {
    try {
      if (_activeTrack?.id == id) {
        await _persistActiveProgress();
        await _playback.stop();
        _activeTrack = null;
        _position = Duration.zero;
        _duration = null;
        _isPlaying = false;
        _notify();
      }
      await _repo.archiveTrack(id);
      await loadTracks();
    } catch (e) {
      debugPrint('Error archiving audio track: $e');
    }
  }, readOnly: false);

  Future<void> _persistActiveProgress() async {
    if (DataOperations.instance.isReplacing &&
        !DataOperations.instance.ownsOperation) {
      return;
    }
    final id = _activeTrack?.id;
    if (id == null) return;

    try {
      await _repo.updatePlaybackProgress(
        id: id,
        position: _position,
        duration: _duration,
      );
    } catch (e) {
      debugPrint('Error persisting audio progress: $e');
    }
  }

  Future<void> prepareForDataReplacement() async {
    await _persistActiveProgress();
    _playRequest++;
    _loadRequest++;
    await _playback.stop();
    _activeTrack = null;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = null;
    _notify();
  }

  void _requestPlay() {
    final request = ++_playRequest;
    _error = null;
    unawaited(
      Future<void>.sync(_playback.play).catchError((Object error) {
        if (_disposed || request != _playRequest) return;
        _error = 'Unable to play audio: $error';
        _isPlaying = false;
        _notify();
      }),
    );
  }

  Future<void> _restartActiveTrack() async {
    final activeTrack = _activeTrack;
    if (activeTrack == null) return;

    _position = Duration.zero;
    _notify();
    await _playback.seek(Duration.zero);
    await _persistActiveProgress();
    _requestPlay();
  }

  AudioTrack? _selectNextTrack(AudioTrack activeTrack, bool fromCompletion) {
    final queue = _playbackQueue();
    if (queue.isEmpty) return null;
    if (queue.length == 1) {
      return _repeatMode == TavernRepeatMode.all ||
              _repeatMode == TavernRepeatMode.one
          ? queue.single
          : null;
    }

    if (_shuffleEnabled) {
      final candidates = queue
          .where((track) => !_isSameQueueTrack(track, activeTrack))
          .toList();
      if (candidates.isEmpty) return null;
      return candidates[_random.nextInt(candidates.length)];
    }

    final index = _queueIndexOf(queue, activeTrack);
    if (index < 0) return queue.first;
    if (index < queue.length - 1) return queue[index + 1];
    return _repeatMode == TavernRepeatMode.all ? queue.first : null;
  }

  AudioTrack? _selectPreviousTrack(AudioTrack activeTrack) {
    final queue = _playbackQueue();
    if (queue.isEmpty) return null;
    if (queue.length == 1) return queue.single;

    if (_shuffleEnabled) {
      final candidates = queue
          .where((track) => !_isSameQueueTrack(track, activeTrack))
          .toList();
      if (candidates.isEmpty) return null;
      return candidates[_random.nextInt(candidates.length)];
    }

    final index = _queueIndexOf(queue, activeTrack);
    if (index < 0) return queue.first;
    if (index > 0) return queue[index - 1];
    return _repeatMode == TavernRepeatMode.all ? queue.last : null;
  }

  List<AudioTrack> _playbackQueue() {
    final queue = [..._tracks];
    queue.sort((a, b) {
      final created = a.createdAt.compareTo(b.createdAt);
      if (created != 0) return created;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return queue;
  }

  int _queueIndexOf(List<AudioTrack> queue, AudioTrack track) {
    return queue.indexWhere((candidate) => _isSameQueueTrack(candidate, track));
  }

  bool _isSameQueueTrack(AudioTrack first, AudioTrack second) {
    if (first.id != null && second.id != null) {
      return first.id == second.id;
    }
    return first.filePath == second.filePath;
  }

  bool _isSameTrack(AudioTrack track) {
    final activeTrack = _activeTrack;
    if (activeTrack == null) return false;
    if (activeTrack.id != null && track.id != null) {
      return activeTrack.id == track.id;
    }
    return activeTrack.filePath == track.filePath;
  }

  Future<void> _handlePlaybackCommand(TavernPlaybackCommand command) async {
    if (command.filePath != null &&
        command.filePath != _activeTrack?.filePath) {
      return;
    }
    switch (command.type) {
      case TavernPlaybackCommandType.pause:
        await _persistActiveProgress();
        return;
      case TavernPlaybackCommandType.stop:
        await _persistActiveProgress();
        _activeTrack = null;
        _isPlaying = false;
        _position = Duration.zero;
        _duration = null;
        _notify();
        return;
      case TavernPlaybackCommandType.seek:
        final position = command.position;
        if (position != null) {
          _position = position;
          _notify();
        }
        await _persistActiveProgress();
        return;
      case TavernPlaybackCommandType.previous:
        await playPreviousTrack();
        return;
      case TavernPlaybackCommandType.next:
        await playNextTrack();
        return;
      case TavernPlaybackCommandType.completed:
        await playNextTrack(fromCompletion: true);
        return;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_persistActiveProgress());
    _playingSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _commandSubscription.cancel();
    super.dispose();
  }
}
