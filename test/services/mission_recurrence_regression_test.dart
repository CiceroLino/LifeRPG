import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';
import 'package:liferpg/data/repositories/player_repository.dart';
import 'package:liferpg/services/mission_completion_service.dart';
import '../support/test_database.dart';

void main() {
  setUp(resetTestDatabase);
  test('biweekly selected weekday skips the intervening week', () async {
    final now = DateTime(2026, 10, 19, 12);
    final id = await MissionRepository().insert(
      Mission(
        title: 'Biweekly',
        isRecurring: true,
        recurrenceType: 'weekly',
        recurrenceInterval: 2,
        recurrenceDays: [DateTime.monday],
        dueDate: now,
      ),
    );
    await MissionCompletionService(clock: () => now).completeMission(id);
    expect(
      (await MissionRepository().getById(id))!.dueDate,
      DateTime(2026, 11, 2, 12),
    );
  });
  test('selected days remain inside eligible biweekly weeks', () async {
    var now = DateTime(2026, 10, 19, 12);
    final id = await MissionRepository().insert(
      Mission(
        title: 'Multi',
        isRecurring: true,
        recurrenceType: 'weekly',
        recurrenceInterval: 2,
        recurrenceDays: [1, 3],
        dueDate: now,
      ),
    );
    final service = MissionCompletionService(clock: () => now);
    await service.completeMission(id);
    expect(
      (await MissionRepository().getById(id))!.dueDate,
      DateTime(2026, 10, 21, 12),
    );
    now = DateTime(2026, 10, 21, 12);
    await service.completeMission(id);
    expect(
      (await MissionRepository().getById(id))!.dueDate,
      DateTime(2026, 11, 2, 12),
    );
  });
  test(
    'a daily mission overdue by 2005 days advances beyond now only once',
    () async {
      final now = DateTime(2026, 10, 21, 12);
      final id = await MissionRepository().insert(
        Mission(
          title: 'Old',
          isRecurring: true,
          recurrenceType: 'daily',
          dueDate: now.subtract(const Duration(days: 2005)),
          xpReward: 100,
        ),
      );
      final service = MissionCompletionService(clock: () => now);
      await service.completeMission(id);
      expect(
        (await MissionRepository().getById(id))!.dueDate!.isAfter(now),
        isTrue,
      );
      expect(
        (await service.completeMission(id)).status,
        MissionCompletionStatus.duplicateBlocked,
      );
      expect((await PlayerRepository().get()).totalXP, 100);
    },
  );
  test('existing month overflow behavior is preserved', () async {
    final now = DateTime(2026, 1, 31, 12);
    final id = await MissionRepository().insert(
      Mission(
        title: 'Monthly',
        isRecurring: true,
        recurrenceType: 'monthly',
        dueDate: now,
      ),
    );
    await MissionCompletionService(clock: () => now).completeMission(id);
    expect(
      (await MissionRepository().getById(id))!.dueDate,
      DateTime(2026, 3, 3, 12),
    );
  });
  test(
    'recurring reminder keeps its offset relative to the next due date',
    () async {
      final now = DateTime(2026, 10, 21, 12);
      final id = await MissionRepository().insert(
        Mission(
          title: 'Reminder',
          isRecurring: true,
          recurrenceType: 'daily',
          dueDate: now,
          reminderAt: now.subtract(const Duration(hours: 1)),
        ),
      );
      await MissionCompletionService(clock: () => now).completeMission(id);
      expect(
        (await MissionRepository().getById(id))!.reminderAt,
        DateTime(2026, 10, 22, 11),
      );
    },
  );
}
