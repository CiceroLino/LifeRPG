import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/database/data_operations.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';
import 'package:liferpg/services/app_data_coordinator.dart';
import '../support/test_database.dart';

void main() {
  setUp(resetTestDatabase);
  test(
    'replacement waits for old writes and rejects new edits until reopening',
    () async {
      final operations = DataOperations.instance;
      final gate = Completer<void>();
      final started = Completer<void>();
      final write = operations.run(() async {
        started.complete();
        await gate.future;
        await MissionRepository().insert(Mission(title: 'Old operation'));
      });
      await started.future;
      var reloaded = false;
      final coordinator = AppDataCoordinator(
        quiesce: () async {},
        reload: [
          () async {
            reloaded = true;
          },
        ],
      );
      final reset = coordinator.replaceData(DatabaseHelper().factoryReset);
      await Future<void>.delayed(Duration.zero);
      expect(operations.isReplacing, isTrue);
      await expectLater(
        MissionRepository().insert(Mission(title: 'Rejected')),
        throwsStateError,
      );
      gate.complete();
      await write;
      await reset;
      expect(await MissionRepository().getAll(), isEmpty);
      expect(reloaded, isTrue);
      expect(operations.isReplacing, isFalse);
      await MissionRepository().insert(Mission(title: 'New data'));
      expect((await MissionRepository().getAll()).single.title, 'New data');
    },
  );
  test(
    'failed replacement preserves data and reopens normal operations',
    () async {
      await MissionRepository().insert(Mission(title: 'Keep'));
      final coordinator = AppDataCoordinator(quiesce: () async {}, reload: []);
      await expectLater(
        coordinator.replaceData(
          () => DatabaseHelper().restoreData({'version': 'invalid'}),
        ),
        throwsFormatException,
      );
      expect(DataOperations.instance.isReplacing, isFalse);
      expect((await MissionRepository().getAll()).single.title, 'Keep');
    },
  );
}
