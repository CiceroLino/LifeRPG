import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/core/utils/daily_time_budget_advisor.dart';
import 'package:liferpg/data/models/mission.dart';

void main() {
  group('DailyTimeBudgetAdvisor', () {
    test(
      'flags when planned mission minutes exceed remaining awake minutes',
      () {
        final now = DateTime(2026, 5, 11, 18);
        final result = DailyTimeBudgetAdvisor.assess(
          now: now,
          wakeUpTime: '08:00',
          sleepTime: '20:00',
          missions: [
            Mission(
              title: 'Deep work',
              estimatedDuration: 90,
              dueDate: DateTime(2026, 5, 11, 19),
            ),
            Mission(
              title: 'Workout',
              estimatedDuration: 45,
              dueDate: DateTime(2026, 5, 11, 19, 30),
            ),
          ],
        );

        expect(result.remainingAwakeMinutes, 120);
        expect(result.scheduledMissionMinutes, 135);
        expect(result.exceedsAvailableTime, isTrue);
        expect(result.message, contains('Tempo requerido excede'));
      },
    );

    test('ignores completed, untimed, and non-today missions', () {
      final now = DateTime(2026, 5, 11, 10);
      final result = DailyTimeBudgetAdvisor.assess(
        now: now,
        wakeUpTime: '08:00',
        sleepTime: '20:00',
        missions: [
          Mission(
            title: 'Today',
            estimatedDuration: 60,
            dueDate: DateTime(2026, 5, 11, 12),
          ),
          Mission(
            title: 'Done',
            estimatedDuration: 300,
            dueDate: DateTime(2026, 5, 11, 13),
            status: 'completed',
          ),
          Mission(
            title: 'Tomorrow',
            estimatedDuration: 300,
            dueDate: DateTime(2026, 5, 12, 13),
          ),
          Mission(title: 'No duration', dueDate: DateTime(2026, 5, 11, 15)),
        ],
      );

      expect(result.remainingAwakeMinutes, 600);
      expect(result.scheduledMissionMinutes, 60);
      expect(result.exceedsAvailableTime, isFalse);
      expect(result.message, isNull);
    });
  });
}
