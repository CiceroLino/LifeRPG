import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/core/utils/xp_calculator.dart';

void main() {
  test('accumulated skill XP follows triangular level curve', () {
    expect(XPCalculator.accumulatedXP(level: 3, currentXP: 0), 300);
    expect(XPCalculator.accumulatedXP(level: 2, currentXP: 190), 290);
    expect(
      XPCalculator.accumulatedXP(level: 3, currentXP: 0),
      greaterThan(XPCalculator.accumulatedXP(level: 2, currentXP: 190)),
    );
  });
  test('large totals retain exact level boundary without linear iteration', () {
    const level = 10000000;
    const boundary = 50 * level * (level - 1);
    expect(XPCalculator.calculateLevel(boundary), level);
    expect(XPCalculator.calculateLevel(boundary - 1), level - 1);
    expect(XPCalculator.xpInCurrentLevel(boundary + 7, level), 7);
  });
}
