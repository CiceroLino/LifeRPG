class XPCalculator {
  static int xpForNextLevel(int currentLevel) {
    return currentLevel * 100;
  }

  static int calculateLevel(int totalXP) {
    int level = 1;
    int xpNeeded = xpForNextLevel(level);

    while (totalXP >= xpNeeded) {
      level++;
      xpNeeded += xpForNextLevel(level);
    }

    return level;
  }

  static int xpInCurrentLevel(int totalXP, int level) {
    int xpForPreviousLevels = 0;
    for (int i = 1; i < level; i++) {
      xpForPreviousLevels += xpForNextLevel(i);
    }
    return totalXP - xpForPreviousLevels;
  }
}

