class EnergyComputationResult {
  final bool isAutoConfigured;
  final bool isCharging;
  final double energyPercent;

  const EnergyComputationResult({
    required this.isAutoConfigured,
    required this.isCharging,
    required this.energyPercent,
  });
}

class EnergyScheduleCalculator {
  static EnergyComputationResult compute({
    required DateTime now,
    required String? wakeUpTime,
    required String? sleepTime,
  }) {
    final wakeMinutes = _parseMinutes(wakeUpTime);
    final sleepMinutes = _parseMinutes(sleepTime);

    if (wakeMinutes == null || sleepMinutes == null) {
      return const EnergyComputationResult(
        isAutoConfigured: false,
        isCharging: false,
        energyPercent: 0,
      );
    }

    final awakeMinutes =
        (sleepMinutes - wakeMinutes + _minutesPerDay) % _minutesPerDay;
    if (awakeMinutes == 0) {
      return const EnergyComputationResult(
        isAutoConfigured: false,
        isCharging: false,
        energyPercent: 0,
      );
    }

    final sleepMinutesTotal = _minutesPerDay - awakeMinutes;
    final nowMinutes = now.hour * 60 + now.minute + (now.second / 60.0);
    final elapsedFromWake =
        (nowMinutes - wakeMinutes + _minutesPerDay) % _minutesPerDay;

    if (elapsedFromWake < awakeMinutes) {
      final awakeProgress = elapsedFromWake / awakeMinutes;
      return EnergyComputationResult(
        isAutoConfigured: true,
        isCharging: false,
        energyPercent: (100 * (1 - awakeProgress)).clamp(0, 100),
      );
    }

    final sleepElapsed = elapsedFromWake - awakeMinutes;
    final sleepProgress = sleepElapsed / sleepMinutesTotal;
    return EnergyComputationResult(
      isAutoConfigured: true,
      isCharging: true,
      energyPercent: (100 * sleepProgress).clamp(0, 100),
    );
  }

  static int? _parseMinutes(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return (hour * 60) + minute;
  }

  static const int _minutesPerDay = 24 * 60;
}
