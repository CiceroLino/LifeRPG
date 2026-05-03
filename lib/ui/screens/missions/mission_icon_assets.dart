const missionIconOptions = [
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/archery-target.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/crosshair.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/overdrive.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/present.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/treasure-map.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/shopping-bag.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/shop.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/chest.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/skoll/open-treasure-chest.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/locked-chest.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/darkzaitzev/hooded-figure.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/angel-wings.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/aura.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/skills.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/weight-lifting-up.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/brain.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/feathered-wing.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/light-bulb.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/gear-hammer.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/compass.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/bookmark.svg',
];

String normalizeMissionIconAsset(String asset) {
  return switch (asset) {
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/crosshair.svg' =>
      'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/crosshair.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/overkill.svg' =>
      'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/overdrive.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/treasure-map.svg' =>
      'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/treasure-map.svg',
    'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/barbell.svg' =>
      'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/weight-lifting-up.svg',
    _ => asset,
  };
}
