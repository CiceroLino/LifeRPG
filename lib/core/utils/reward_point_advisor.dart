class RewardPointAdvisor {
  static int recommendMissionRewardPoints({
    required int xpReward,
    required bool isChildMission,
    String? recurrenceType,
  }) {
    final recurrence = recurrenceType?.toLowerCase();
    if (!isChildMission && recurrence == 'daily') {
      return 1;
    }
    if (isChildMission && (recurrence == 'daily' || recurrence == 'weekly')) {
      return 1;
    }

    final safeXP = xpReward < 0 ? 0 : xpReward;
    return isChildMission
        ? _recommendForChildMission(safeXP)
        : _recommendForStandaloneMission(safeXP);
  }

  static int _recommendForStandaloneMission(int xpReward) {
    if (xpReward <= 100) return 5;
    if (xpReward <= 1000) return 10;
    if (xpReward <= 10000) return 25;
    if (xpReward <= 100000) return 50;
    if (xpReward <= 1000000) return 75;
    return 100;
  }

  static int _recommendForChildMission(int xpReward) {
    if (xpReward <= 1000) return 5;
    if (xpReward <= 10000) return 10;
    if (xpReward <= 100000) return 25;
    if (xpReward <= 1000000) return 50;
    return 75;
  }
}
