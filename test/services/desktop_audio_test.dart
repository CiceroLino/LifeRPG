import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:liferpg/services/tavern_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Linux backend decodes a local WAV file', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final directory = await Directory.systemTemp.createTemp('liferpg-audio-');
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (_) async => directory.path);
    try {
      const samples = 4800;
      final bytes = ByteData(44 + samples * 2);
      void text(int offset, String value) {
        for (var i = 0; i < value.length; i++) {
          bytes.setUint8(offset + i, value.codeUnitAt(i));
        }
      }

      text(0, 'RIFF');
      bytes.setUint32(4, 36 + samples * 2, Endian.little);
      text(8, 'WAVEfmt ');
      bytes.setUint32(16, 16, Endian.little);
      bytes.setUint16(20, 1, Endian.little);
      bytes.setUint16(22, 1, Endian.little);
      bytes.setUint32(24, 48000, Endian.little);
      bytes.setUint32(28, 96000, Endian.little);
      bytes.setUint16(32, 2, Endian.little);
      bytes.setUint16(34, 16, Endian.little);
      text(36, 'data');
      bytes.setUint32(40, samples * 2, Endian.little);
      final file = await File(
        '${directory.path}/sample.wav',
      ).writeAsBytes(bytes.buffer.asUint8List());
      final playback = await initTavernAudioService();
      final duration = await playback.load(
        AudioTrack(title: 'Sample', filePath: file.path),
      );
      expect(duration?.inMilliseconds, greaterThanOrEqualTo(90));
      await playback.stop();
      await playback.dispose();
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, null);
      await directory.delete(recursive: true);
    }
  }, skip: !Platform.isLinux);
}
