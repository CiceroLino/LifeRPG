import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liferpg/main.dart';
import 'package:liferpg/services/tavern_audio_service.dart';

class FakeTavernPlayback implements TavernPlayback {
  @override
  Stream<bool> get playingStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<TavernPlaybackCommand> get commandStream => const Stream.empty();

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

void main() {
  testWidgets('MyApp renders MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(tavernAudioService: FakeTavernPlayback()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
