import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/core/utils/energy_schedule_calculator.dart';

void main() {
  group('EnergyScheduleCalculator.compute', () {
    test('returns not configured when schedule is missing', () {
      final result = EnergyScheduleCalculator.compute(
        now: DateTime(2026, 1, 1, 12, 0),
        wakeUpTime: null,
        sleepTime: '22:00',
      );

      expect(result.isAutoConfigured, false);
    });

    test('returns not configured when wake and sleep are equal', () {
      final result = EnergyScheduleCalculator.compute(
        now: DateTime(2026, 1, 1, 12, 0),
        wakeUpTime: '08:00',
        sleepTime: '08:00',
      );

      expect(result.isAutoConfigured, false);
    });

    test('drains from 100 to 0 during awake period', () {
      final result = EnergyScheduleCalculator.compute(
        now: DateTime(2026, 1, 1, 14, 0),
        wakeUpTime: '08:00',
        sleepTime: '20:00',
      );

      expect(result.isAutoConfigured, true);
      expect(result.isCharging, false);
      expect(result.energyPercent, closeTo(50, 0.01));
    });

    test('charges from 0 to 100 during sleep period', () {
      final result = EnergyScheduleCalculator.compute(
        now: DateTime(2026, 1, 1, 2, 0),
        wakeUpTime: '08:00',
        sleepTime: '20:00',
      );

      expect(result.isAutoConfigured, true);
      expect(result.isCharging, true);
      expect(result.energyPercent, closeTo(50, 0.01));
    });

    test('handles awake period crossing midnight', () {
      final result = EnergyScheduleCalculator.compute(
        now: DateTime(2026, 1, 1, 22, 0),
        wakeUpTime: '16:00',
        sleepTime: '04:00',
      );

      expect(result.isAutoConfigured, true);
      expect(result.isCharging, false);
      expect(result.energyPercent, closeTo(50, 0.01));
    });
  });
}
