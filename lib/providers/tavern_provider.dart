import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../data/repositories/audio_track_repository.dart';
import '../services/tavern_audio_service.dart';

class TavernProvider extends ChangeNotifier {
  final AudioTrackRepository _repo = AudioTrackRepository();
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
  bool _disposed = false;

  TavernProvider({required TavernPlayback playback}) : _playback = playback {
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
      unawaited(_handlePlaybackCommand(command));
    });
  }

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
              path.basename(track.filePath).toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> loadTracks() async {
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
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    _notify();
  }

  Future<int?> importTrackFromPath(String filePath) async {
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
  }

  Future<void> playTrack(AudioTrack track) async {
    if (_isSameTrack(track)) {
      if (!_isPlaying) {
        try {
          await _playback.play();
        } catch (e) {
          debugPrint('Error resuming audio track: $e');
          rethrow;
        }
      }
      return;
    }

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
      _duration = await _playback.load(track);
      await _playback.play();

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
  }

  Future<void> togglePlayPause() async {
    if (_activeTrack == null) return;

    try {
      if (_isPlaying) {
        await _persistActiveProgress();
        await _playback.pause();
      } else {
        await _playback.play();
      }
    } catch (e) {
      debugPrint('Error toggling tavern playback: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      _position = position;
      _notify();
      await _playback.seek(position);
      await _persistActiveProgress();
    } catch (e) {
      debugPrint('Error seeking tavern playback: $e');
    }
  }

  Future<void> archiveTrack(int id) async {
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
  }

  Future<void> _persistActiveProgress() async {
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

  bool _isSameTrack(AudioTrack track) {
    final activeTrack = _activeTrack;
    if (activeTrack == null) return false;
    if (activeTrack.id != null && track.id != null) {
      return activeTrack.id == track.id;
    }
    return activeTrack.filePath == track.filePath;
  }

  Future<void> _handlePlaybackCommand(TavernPlaybackCommand command) async {
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
