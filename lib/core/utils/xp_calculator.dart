enum MissionAttribute { difficulty, urgency, fear }

class XPCalculator {
  static const _difficultyLabels = [
    'Trivial',
    'Beginner',
    'Breeze',
    'Easy',
    'Medium',
    'Hard',
    'Challenge',
    'Expert',
    'Extreme',
    'Transformational',
  ];

  static const _urgencyLabels = [
    'Optional',
    'Non-urgent',
    'Free',
    'Low',
    'Middle',
    'High',
    'Major',
    'Superlative',
    'Immediate',
    'Critical',
  ];

  static const _fearLabels = [
    'Negligible',
    'Eustress',
    'Excitement',
    'Jitters',
    'Moderate',
    'Worry',
    'Gloom',
    'Obsession',
    'Dread',
    'Mortal',
  ];

  static int xpForNextLevel(int currentLevel) {
    return currentLevel * 100;
  }

  static int calculateLevel(int totalXP) {
    if (totalXP <= 0) return 1;
    // Level < 2^29 for every signed 64-bit XP total. Avoid linear work on imports.
    var low = 1;
    var high = 1 << 29;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      // Divide first to avoid overflowing the triangular product on native Dart.
      final fits = middle - 1 <= (totalXP ~/ 50) ~/ middle;
      if (fits) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  static int accumulatedXP({required int level, required int currentXP}) =>
      50 * level * (level - 1) + currentXP;

  static int xpInCurrentLevel(int totalXP, int level) =>
      totalXP - accumulatedXP(level: level, currentXP: 0);

  static int calculateMissionXP({
    required int difficulty,
    required int urgency,
    required int fear,
  }) {
    final safeDifficulty = difficulty.clamp(0, 100);
    final safeUrgency = urgency.clamp(0, 100);
    final safeFear = fear.clamp(0, 100);

    if (safeDifficulty == 0 || safeUrgency == 0) {
      return 0;
    }

    return (safeDifficulty * safeUrgency * (1 + safeFear / 100)).round();
  }

  static String attributeBand(int value) {
    final safeValue = value.clamp(0, 100);
    if (safeValue <= 25) return 'Low';
    if (safeValue <= 50) return 'Medium';
    if (safeValue <= 75) return 'High';
    return 'Extreme';
  }

  static String attributeGuideLabel(MissionAttribute attribute, int value) {
    final safeValue = value.clamp(0, 100);
    final index = ((safeValue - 1).clamp(0, 99) ~/ 10).clamp(0, 9);
    return switch (attribute) {
      MissionAttribute.difficulty => _difficultyLabels[index],
      MissionAttribute.urgency => _urgencyLabels[index],
      MissionAttribute.fear => _fearLabels[index],
    };
  }
}
