import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/core/utils/reward_point_advisor.dart';
import 'package:liferpg/core/utils/xp_calculator.dart';

void main() {
  group('mission XP calculation', () {
    test('returns zero when difficulty is zero', () {
      expect(
        XPCalculator.calculateMissionXP(difficulty: 0, urgency: 50, fear: 50),
        0,
      );
    });

    test('returns zero when urgency is zero', () {
      expect(
        XPCalculator.calculateMissionXP(difficulty: 50, urgency: 0, fear: 50),
        0,
      );
    });

    test('calculates deterministic XP from attributes', () {
      expect(
        XPCalculator.calculateMissionXP(difficulty: 50, urgency: 50, fear: 0),
        2500,
      );
      expect(
        XPCalculator.calculateMissionXP(difficulty: 50, urgency: 50, fear: 50),
        3750,
      );
      expect(
        XPCalculator.calculateMissionXP(
          difficulty: 100,
          urgency: 100,
          fear: 100,
        ),
        20000,
      );
    });
  });

  group('attribute strategy labels', () {
    test('maps values into guide bands', () {
      expect(XPCalculator.attributeBand(0), 'Low');
      expect(XPCalculator.attributeBand(25), 'Low');
      expect(XPCalculator.attributeBand(26), 'Medium');
      expect(XPCalculator.attributeBand(50), 'Medium');
      expect(XPCalculator.attributeBand(51), 'High');
      expect(XPCalculator.attributeBand(75), 'High');
      expect(XPCalculator.attributeBand(76), 'Extreme');
      expect(XPCalculator.attributeBand(100), 'Extreme');
    });

    test('maps attributes to guide labels', () {
      expect(
        XPCalculator.attributeGuideLabel(MissionAttribute.difficulty, 10),
        'Trivial',
      );
      expect(
        XPCalculator.attributeGuideLabel(MissionAttribute.urgency, 50),
        'Middle',
      );
      expect(
        XPCalculator.attributeGuideLabel(MissionAttribute.fear, 90),
        'Dread',
      );
    });
  });

  group('reward point advisor', () {
    test('recommends one RP for daily non-child missions', () {
      expect(
        RewardPointAdvisor.recommendMissionRewardPoints(
          xpReward: 20000,
          isChildMission: false,
          recurrenceType: 'daily',
        ),
        1,
      );
    });

    test('uses non-child mission XP tiers', () {
      expect(
        RewardPointAdvisor.recommendMissionRewardPoints(
          xpReward: 100,
          isChildMission: false,
        ),
        5,
      );
      expect(
        RewardPointAdvisor.recommendMissionRewardPoints(
          xpReward: 1001,
          isChildMission: false,
        ),
        25,
      );
      expect(
        RewardPointAdvisor.recommendMissionRewardPoints(
          xpReward: 1000001,
          isChildMission: false,
        ),
        100,
      );
    });

    test('recommends one RP for daily and weekly child missions', () {
      for (final recurrenceType in ['daily', 'weekly']) {
        expect(
          RewardPointAdvisor.recommendMissionRewardPoints(
            xpReward: 20000,
            isChildMission: true,
            recurrenceType: recurrenceType,
          ),
          1,
        );
      }
    });

    test('uses child mission XP tiers and never recommends 100 RP', () {
      expect(
        RewardPointAdvisor.recommendMissionRewardPoints(
          xpReward: 1001,
          isChildMission: true,
        ),
        10,
      );
      expect(
        RewardPointAdvisor.recommendMissionRewardPoints(
          xpReward: 1000001,
          isChildMission: true,
        ),
        75,
      );
    });

    test('blends reward recommendation with similar historical rewards', () {
      expect(
        RewardPointAdvisor.recommendMissionRewardPoints(
          xpReward: 1100,
          isChildMission: false,
          historicalSamples: const [
            RewardPointHistorySample(xpReward: 1000, rewardPoints: 80),
            RewardPointHistorySample(xpReward: 1200, rewardPoints: 90),
          ],
        ),
        greaterThan(25),
      );
    });

    test('keeps zero XP missions at zero RP even when history exists', () {
      expect(
        RewardPointAdvisor.recommendMissionRewardPoints(
          xpReward: 0,
          isChildMission: false,
          historicalSamples: const [
            RewardPointHistorySample(xpReward: 1000, rewardPoints: 80),
          ],
        ),
        0,
      );
    });
  });
}
