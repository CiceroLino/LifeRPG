import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/core/constants/icon_registry.dart';

void main() {
  test('mission icon registry points only to curated assets', () {
    expect(LifeRPGIcons.missionSvgOptions, isNotEmpty);

    for (final option in LifeRPGIcons.missionSvgOptions) {
      expect(option.assetPath, startsWith('${LifeRPGIcons.assetRoot}/'));
      expect(File(option.assetPath).existsSync(), isTrue);
    }
  });

  test('profile icon registry points only to curated assets', () {
    expect(LifeRPGIcons.profileSvgOptions, isNotEmpty);

    for (final option in LifeRPGIcons.profileSvgOptions) {
      expect(option.assetPath, startsWith('${LifeRPGIcons.assetRoot}/'));
      expect(File(option.assetPath).existsSync(), isTrue);
    }
  });

  test('supporting SVG registries point only to curated assets', () {
    final options = [
      ...LifeRPGIcons.rewardSvgOptions,
      ...LifeRPGIcons.systemSvgOptions,
    ];
    expect(options, isNotEmpty);

    for (final option in options) {
      expect(option.assetPath, startsWith('${LifeRPGIcons.assetRoot}/'));
      expect(File(option.assetPath).existsSync(), isTrue);
    }
  });

  test('reward icon registry includes existing stored keys and fallback', () {
    expect(LifeRPGIcons.rewardIconFor('card_giftcard'), isA<IconData>());
    expect(LifeRPGIcons.rewardIconFor('movie'), isA<IconData>());
    expect(LifeRPGIcons.rewardIconFor('local_cafe'), isA<IconData>());
    expect(LifeRPGIcons.rewardIconFor('sports_esports'), isA<IconData>());
    expect(LifeRPGIcons.rewardIconFor('menu_book'), isA<IconData>());
    expect(
      LifeRPGIcons.rewardIconFor('unknown'),
      Icons.card_giftcard_outlined,
    );
  });
}
