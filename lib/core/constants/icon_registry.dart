import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SvgIconOption {
  final String key;
  final String label;
  final String assetPath;

  const SvgIconOption({
    required this.key,
    required this.label,
    required this.assetPath,
  });
}

class AppIconOption {
  final String key;
  final String label;
  final IconData icon;

  const AppIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class LifeRPGIcons {
  static const String assetRoot = 'assets/liferpg_icons';

  static const List<SvgIconOption> missionSvgOptions = [
    SvgIconOption(
      key: 'quest',
      label: 'Quest',
      assetPath: '$assetRoot/missions/quest.svg',
    ),
    SvgIconOption(
      key: 'target',
      label: 'Target',
      assetPath: '$assetRoot/missions/target.svg',
    ),
    SvgIconOption(
      key: 'effort',
      label: 'Effort',
      assetPath: '$assetRoot/missions/effort.svg',
    ),
    SvgIconOption(
      key: 'treasure_map',
      label: 'Treasure Map',
      assetPath: '$assetRoot/missions/treasure-map.svg',
    ),
    SvgIconOption(
      key: 'skills',
      label: 'Skills',
      assetPath: '$assetRoot/missions/skills.svg',
    ),
    SvgIconOption(
      key: 'strength',
      label: 'Strength',
      assetPath: '$assetRoot/missions/strength.svg',
    ),
    SvgIconOption(
      key: 'brain',
      label: 'Brain',
      assetPath: '$assetRoot/missions/brain.svg',
    ),
    SvgIconOption(
      key: 'mobility',
      label: 'Mobility',
      assetPath: '$assetRoot/missions/mobility.svg',
    ),
    SvgIconOption(
      key: 'idea',
      label: 'Idea',
      assetPath: '$assetRoot/missions/idea.svg',
    ),
    SvgIconOption(
      key: 'work',
      label: 'Work',
      assetPath: '$assetRoot/missions/work.svg',
    ),
    SvgIconOption(
      key: 'compass',
      label: 'Compass',
      assetPath: '$assetRoot/missions/compass.svg',
    ),
    SvgIconOption(
      key: 'bookmark',
      label: 'Bookmark',
      assetPath: '$assetRoot/missions/bookmark.svg',
    ),
  ];

  static const List<SvgIconOption> profileSvgOptions = [
    SvgIconOption(
      key: 'hooded_figure',
      label: 'Hooded Figure',
      assetPath: '$assetRoot/profile/hooded-figure.svg',
    ),
    SvgIconOption(
      key: 'hooded_assassin',
      label: 'Hooded Assassin',
      assetPath: '$assetRoot/profile/hooded-assassin.svg',
    ),
    SvgIconOption(
      key: 'ninja_head',
      label: 'Ninja Head',
      assetPath: '$assetRoot/profile/ninja-head.svg',
    ),
    SvgIconOption(
      key: 'person',
      label: 'Person',
      assetPath: '$assetRoot/profile/person.svg',
    ),
    SvgIconOption(
      key: 'character',
      label: 'Character',
      assetPath: '$assetRoot/profile/character.svg',
    ),
    SvgIconOption(
      key: 'black_knight_helm',
      label: 'Black Knight Helm',
      assetPath: '$assetRoot/profile/black-knight-helm.svg',
    ),
    SvgIconOption(
      key: 'knight_banner',
      label: 'Knight Banner',
      assetPath: '$assetRoot/profile/knight-banner.svg',
    ),
    SvgIconOption(
      key: 'angel_wings',
      label: 'Angel Wings',
      assetPath: '$assetRoot/profile/angel-wings.svg',
    ),
    SvgIconOption(
      key: 'aura',
      label: 'Aura',
      assetPath: '$assetRoot/profile/aura.svg',
    ),
    SvgIconOption(
      key: 'feathered_wing',
      label: 'Feathered Wing',
      assetPath: '$assetRoot/profile/feathered-wing.svg',
    ),
    SvgIconOption(
      key: 'angel_outfit',
      label: 'Angel Outfit',
      assetPath: '$assetRoot/profile/angel-outfit.svg',
    ),
    SvgIconOption(
      key: 'skills',
      label: 'Skills',
      assetPath: '$assetRoot/profile/skills.svg',
    ),
    SvgIconOption(
      key: 'apothecary',
      label: 'Apothecary',
      assetPath: '$assetRoot/profile/apothecary.svg',
    ),
    SvgIconOption(
      key: 'brain',
      label: 'Brain',
      assetPath: '$assetRoot/profile/brain.svg',
    ),
    SvgIconOption(
      key: 'shield',
      label: 'Shield',
      assetPath: '$assetRoot/profile/edged-shield.svg',
    ),
    SvgIconOption(
      key: 'fireball',
      label: 'Fireball',
      assetPath: '$assetRoot/profile/fireball.svg',
    ),
    SvgIconOption(
      key: 'compass',
      label: 'Compass',
      assetPath: '$assetRoot/profile/compass.svg',
    ),
    SvgIconOption(
      key: 'idea',
      label: 'Idea',
      assetPath: '$assetRoot/profile/light-bulb.svg',
    ),
    SvgIconOption(
      key: 'bookmark',
      label: 'Bookmark',
      assetPath: '$assetRoot/profile/bookmark.svg',
    ),
  ];

  static const List<SvgIconOption> rewardSvgOptions = [
    SvgIconOption(
      key: 'gift',
      label: 'Gift',
      assetPath: '$assetRoot/rewards/gift.svg',
    ),
    SvgIconOption(
      key: 'shopping_bag',
      label: 'Shopping Bag',
      assetPath: '$assetRoot/rewards/shopping-bag.svg',
    ),
    SvgIconOption(
      key: 'shop',
      label: 'Shop',
      assetPath: '$assetRoot/rewards/shop.svg',
    ),
    SvgIconOption(
      key: 'chest',
      label: 'Chest',
      assetPath: '$assetRoot/rewards/chest.svg',
    ),
    SvgIconOption(
      key: 'open_chest',
      label: 'Open Chest',
      assetPath: '$assetRoot/rewards/open-chest.svg',
    ),
    SvgIconOption(
      key: 'locked_chest',
      label: 'Locked Chest',
      assetPath: '$assetRoot/rewards/locked-chest.svg',
    ),
  ];

  static const List<SvgIconOption> systemSvgOptions = [
    SvgIconOption(
      key: 'notebook',
      label: 'Notebook',
      assetPath: '$assetRoot/system/notebook.svg',
    ),
    SvgIconOption(
      key: 'focus',
      label: 'Focus',
      assetPath: '$assetRoot/system/focus.svg',
    ),
  ];

  static final List<AppIconOption> rewardOptions = [
    AppIconOption(
      key: 'card_giftcard',
      label: 'Presente',
      icon: Icons.card_giftcard_outlined,
    ),
    AppIconOption(key: 'movie', label: 'Filme', icon: Icons.movie_outlined),
    AppIconOption(
      key: 'local_cafe',
      label: 'Cafe',
      icon: Icons.local_cafe_outlined,
    ),
    AppIconOption(
      key: 'sports_esports',
      label: 'Jogo',
      icon: Icons.sports_esports_outlined,
    ),
    AppIconOption(
      key: 'menu_book',
      label: 'Livro',
      icon: Icons.menu_book_outlined,
    ),
    AppIconOption(
      key: 'shopping_bag',
      label: 'Compra',
      icon: Icons.shopping_bag_outlined,
    ),
    AppIconOption(
      key: 'music',
      label: 'Musica',
      icon: Icons.music_note_outlined,
    ),
    AppIconOption(
      key: 'trophy',
      label: 'Trofeu',
      icon: FontAwesomeIcons.trophy.data,
    ),
    AppIconOption(
      key: 'coins',
      label: 'Moedas',
      icon: FontAwesomeIcons.coins.data,
    ),
  ];

  static IconData rewardIconFor(String? key) {
    for (final option in rewardOptions) {
      if (option.key == key) return option.icon;
    }
    return Icons.card_giftcard_outlined;
  }

  static List<String> get missionAssetPaths =>
      missionSvgOptions.map((option) => option.assetPath).toList();

  static List<String> get profileAssetPaths =>
      profileSvgOptions.map((option) => option.assetPath).toList();

  static List<String> get rewardAssetPaths =>
      rewardSvgOptions.map((option) => option.assetPath).toList();

  static List<String> get systemAssetPaths =>
      systemSvgOptions.map((option) => option.assetPath).toList();
}
