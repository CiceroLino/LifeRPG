import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

import '../data/models/audio_track.dart';

export '../data/models/audio_track.dart';

enum TavernPlaybackCommandType { pause, stop, seek }

class TavernPlaybackCommand {
  const TavernPlaybackCommand(this.type, {this.position});

  final TavernPlaybackCommandType type;
  final Duration? position;
}

abstract class TavernPlayback {
  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<TavernPlaybackCommand> get commandStream;

  Future<Duration?> load(AudioTrack track);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
}

class TavernAudioService implements TavernPlayback {
  final TavernAudioHandler _handler;

  TavernAudioService(this._handler);

  @override
  Stream<bool> get playingStream => _handler.playingStream;

  @override
  Stream<Duration> get positionStream => _handler.positionStream;

  @override
  Stream<Duration?> get durationStream => _handler.durationStream;

  @override
  Stream<TavernPlaybackCommand> get commandStream => _handler.commandStream;

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
  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();
  final StreamController<TavernPlaybackCommand> _commandController =
      StreamController<TavernPlaybackCommand>.broadcast();
  late final Stream<Duration?> _durationStream = _player.durationStream
      .asBroadcastStream();

  TavernAudioHandler() {
    _player.playbackEventStream.listen(_broadcastPlaybackState);
  }

  Stream<bool> get playingStream => _player.playingStream;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _durationStream;

  Stream<TavernPlaybackCommand> get commandStream => _commandController.stream;

  Future<Duration?> load(AudioTrack track) async {
    final item = MediaItem(
      id: track.filePath,
      title: track.title,
      artist: track.artist.isEmpty ? null : track.artist,
      album: track.album.isEmpty ? null : track.album,
      duration: track.duration,
    );

    mediaItem.add(item);

    return _player.setFilePath(
      track.filePath,
      initialPosition: track.position,
      tag: item,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() async {
    await _player.pause();
    _commandController.add(
      const TavernPlaybackCommand(TavernPlaybackCommandType.pause),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _commandController.add(
      TavernPlaybackCommand(TavernPlaybackCommandType.seek, position: position),
    );
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _commandController.add(
      const TavernPlaybackCommand(TavernPlaybackCommandType.stop),
    );
  }

  void _broadcastPlaybackState(just_audio.PlaybackEvent event) {
    playbackState.add(
      PlaybackState(
        controls: [
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1],
        processingState: _mapProcessingState(event.processingState),
        playing: _player.playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(just_audio.ProcessingState state) {
    return switch (state) {
      just_audio.ProcessingState.idle => AudioProcessingState.idle,
      just_audio.ProcessingState.loading => AudioProcessingState.loading,
      just_audio.ProcessingState.buffering => AudioProcessingState.buffering,
      just_audio.ProcessingState.ready => AudioProcessingState.ready,
      just_audio.ProcessingState.completed => AudioProcessingState.completed,
    };
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
