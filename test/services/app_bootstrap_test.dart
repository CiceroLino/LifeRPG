import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/services/app_bootstrap.dart';
import 'package:liferpg/services/local_media_import_service_stub.dart'
    as unsupported;
import 'package:liferpg/services/mission_reminder_service.dart';
import 'package:liferpg/services/tavern_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('unsupported import service is safe to construct', () {
    expect(() => unsupported.createLocalMediaImportService(), returnsNormally);
  });
  test(
    'optional playback failure produces an explicit unavailable service',
    () async {
      final service = await initializeTavernPlayback(
        initializer: () async {
          throw StateError('device unavailable');
        },
      );
      expect(service, isA<UnavailableTavernPlayback>());
      await expectLater(service.play(), throwsStateError);
      await service.stop();
    },
  );
  test(
    'Windows notification setup does not fail for missing settings',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await MissionReminderService.instance.initialize();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
