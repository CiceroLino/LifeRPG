class RewardPointAdvisor {
  static const _historySampleLimit = 12;

  static int recommendMissionRewardPoints({
    required int xpReward,
    required bool isChildMission,
    String? recurrenceType,
    List<RewardPointHistorySample>? historicalSamples,
  }) {
    final recurrence = recurrenceType?.toLowerCase();
    if (!isChildMission && recurrence == 'daily') {
      return 1;
    }
    if (isChildMission && (recurrence == 'daily' || recurrence == 'weekly')) {
      return 1;
    }

    final safeXP = xpReward < 0 ? 0 : xpReward;
    final baseRecommendation = isChildMission
        ? _recommendForChildMission(safeXP)
        : _recommendForStandaloneMission(safeXP);
    if (baseRecommendation == 0) {
      return 0;
    }

    final history = _normalizeHistorySamples(historicalSamples);
    if (history.isEmpty) {
      return baseRecommendation;
    }

    final historicalRecommendation = _recommendFromHistory(
      xpReward: safeXP,
      history: history,
    );

    return _blendRecommendation(
      baseline: baseRecommendation,
      historical: historicalRecommendation,
    );
  }

  static int _blendRecommendation({
    required int baseline,
    required int historical,
  }) {
    const historyWeight = 0.6;
    const baselineWeight = 1 - historyWeight;
    final blended = (baseline * baselineWeight) + (historical * historyWeight);
    return _clampRewardPoints(blended.round());
  }

  static int _recommendFromHistory({
    required int xpReward,
    required List<RewardPointHistorySample> history,
  }) {
    if (history.isEmpty) return 0;

    final rankedHistory = [...history]
      ..sort((a, b) {
        final left = (a.xpReward - xpReward).abs();
        final right = (b.xpReward - xpReward).abs();
        return left.compareTo(right);
      });

    final selected = rankedHistory.take(_historySampleLimit);
    double weightedSum = 0;
    double totalWeight = 0;

    for (final sample in selected) {
      final distance = (sample.xpReward - xpReward).abs();
      final weight = 1 / (1 + (distance / 200));
      weightedSum += sample.rewardPoints * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return 0;
    return _clampRewardPoints((weightedSum / totalWeight).round());
  }

  static List<RewardPointHistorySample> _normalizeHistorySamples(
    List<RewardPointHistorySample>? history,
  ) {
    if (history == null || history.isEmpty) return const [];

    return history
        .where((sample) => sample.xpReward > 0 && sample.rewardPoints >= 0)
        .map(
          (sample) => RewardPointHistorySample(
            xpReward: sample.xpReward,
            rewardPoints: sample.rewardPoints,
          ),
        )
        .toList(growable: false);
  }

  static int _clampRewardPoints(int value) {
    if (value < 1) return 1;
    if (value > 250) return 250;
    return value;
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

class RewardPointHistorySample {
  final int xpReward;
  final int rewardPoints;

  const RewardPointHistorySample({
    required this.xpReward,
    required this.rewardPoints,
  });
}
