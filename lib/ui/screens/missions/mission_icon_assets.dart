import '../../../core/constants/icon_registry.dart';

final missionIconOptions = LifeRPGIcons.missionAssetPaths;

String normalizeMissionIconAsset(String asset) {
  return switch (asset) {
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/crosshair.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/target.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/crosshair.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/target.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/overkill.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/effort.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/overdrive.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/effort.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/treasure-map.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/treasure-map.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/treasure-map.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/treasure-map.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/barbell.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/strength.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/archery-target.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/quest.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/skills.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/skills.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/weight-lifting-up.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/strength.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/brain.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/brain.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/feathered-wing.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/mobility.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/light-bulb.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/idea.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/gear-hammer.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/work.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/compass.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/compass.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/bookmark.svg' =>
      '${LifeRPGIcons.assetRoot}/missions/bookmark.svg',
    _ => asset,
  };
}
