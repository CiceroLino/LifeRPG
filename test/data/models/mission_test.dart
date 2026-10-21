import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';
import '../../support/test_database.dart';

void main() {
  setUp(resetTestDatabase);
  test(
    'nullable mission fields can be cleared while omission preserves them',
    () {
      final now = DateTime(2026, 10, 20);
      final mission = Mission(
        id: 7,
        title: 'Quest',
        parentMissionId: 3,
        dueDate: now,
        reminderAt: now,
        completedAt: now,
        lastCompletedAt: now,
        locationName: 'Park',
        latitude: 1,
        longitude: 2,
        recurrenceType: 'weekly',
        recurrenceInterval: 2,
        estimatedDuration: 30,
        icon: 'old.svg',
        emoji: 'x',
      );
      expect(mission.copyWith().toMap(), mission.toMap());
      final cleared = mission.copyWith(
        id: null,
        parentMissionId: null,
        dueDate: null,
        reminderAt: null,
        completedAt: null,
        lastCompletedAt: null,
        locationName: null,
        latitude: null,
        longitude: null,
        recurrenceType: null,
        recurrenceInterval: null,
        estimatedDuration: null,
        icon: null,
        emoji: null,
      );
      for (final field in [
        'id',
        'parent_mission_id',
        'due_date',
        'reminder_at',
        'completed_at',
        'last_completed_at',
        'location_name',
        'latitude',
        'longitude',
        'recurrence_type',
        'recurrence_interval',
        'estimated_duration',
        'icon',
        'emoji',
      ]) {
        expect(cleared.toMap()[field], isNull, reason: field);
      }
    },
  );
  test(
    'duplicate receives a new identity without changing the original',
    () async {
      final repo = MissionRepository();
      final id = await repo.insert(
        Mission(
          title: 'Original',
          status: 'completed',
          completedAt: DateTime.now(),
        ),
      );
      final original = (await repo.getById(id))!;
      final duplicate = original.copyWith(
        id: null,
        title: 'Copy',
        status: 'active',
        completedAt: null,
        lastCompletedAt: null,
        streak: 0,
      );
      final copyId = await repo.insert(duplicate);
      expect(copyId, isNot(id));
      expect((await repo.getById(id))!.status, 'completed');
      expect((await repo.getById(copyId))!.completedAt, isNull);
      expect(await repo.getAll(), hasLength(2));
    },
  );
  test(
    'moving a mission back to the root clears its persisted parent',
    () async {
      final repo = MissionRepository();
      final parent = await repo.insert(Mission(title: 'Parent'));
      final child = await repo.insert(
        Mission(title: 'Child', parentMissionId: parent),
      );
      await repo.update(
        (await repo.getById(child))!.copyWith(parentMissionId: null),
      );
      expect((await repo.getById(child))!.parentMissionId, isNull);
    },
  );
}
