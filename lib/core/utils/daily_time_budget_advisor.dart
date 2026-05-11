import '../../data/models/mission.dart';

class DailyTimeBudgetResult {
  final int remainingAwakeMinutes;
  final int scheduledMissionMinutes;
  final bool exceedsAvailableTime;
  final String? message;

  const DailyTimeBudgetResult({
    required this.remainingAwakeMinutes,
    required this.scheduledMissionMinutes,
    required this.exceedsAvailableTime,
    this.message,
  });
}

class DailyTimeBudgetAdvisor {
  static DailyTimeBudgetResult assess({
    required DateTime now,
    required String? wakeUpTime,
    required String? sleepTime,
    required List<Mission> missions,
  }) {
    final remainingAwakeMinutes = _remainingAwakeMinutes(
      now: now,
      wakeUpTime: wakeUpTime,
      sleepTime: sleepTime,
    );
    final scheduledMissionMinutes = missions
        .where((mission) => _isActiveToday(mission, now))
        .fold<int>(0, (sum, mission) => sum + (mission.estimatedDuration ?? 0));
    final exceedsAvailableTime =
        remainingAwakeMinutes > 0 &&
        scheduledMissionMinutes > remainingAwakeMinutes;

    return DailyTimeBudgetResult(
      remainingAwakeMinutes: remainingAwakeMinutes,
      scheduledMissionMinutes: scheduledMissionMinutes,
      exceedsAvailableTime: exceedsAvailableTime,
      message: exceedsAvailableTime
          ? 'Tempo requerido excede o disponível hoje. Reagende ou faça em paralelo.'
          : null,
    );
  }

  static bool _isActiveToday(Mission mission, DateTime now) {
    if (mission.status != 'active') return false;
    final duration = mission.estimatedDuration;
    if (duration == null || duration <= 0) return false;
    final dueDate = mission.dueDate;
    if (dueDate == null) return false;
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  static int _remainingAwakeMinutes({
    required DateTime now,
    required String? wakeUpTime,
    required String? sleepTime,
  }) {
    final wakeMinutes = _parseMinutes(wakeUpTime);
    final sleepMinutes = _parseMinutes(sleepTime);
    if (wakeMinutes == null || sleepMinutes == null) return 0;

    final awakeMinutes =
        (sleepMinutes - wakeMinutes + _minutesPerDay) % _minutesPerDay;
    if (awakeMinutes == 0) return 0;

    final nowMinutes = now.hour * 60 + now.minute;
    final elapsedFromWake =
        (nowMinutes - wakeMinutes + _minutesPerDay) % _minutesPerDay;
    if (elapsedFromWake >= awakeMinutes) return 0;
    return awakeMinutes - elapsedFromWake;
  }

  static int? _parseMinutes(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static const int _minutesPerDay = 24 * 60;
}
