import 'package:flutter/foundation.dart';

void registerThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['LifeRPG Game-icons.net assets'],
      'Icons made by Lorc, Delapouite, DarkZaitzev and Skoll.\n'
      'https://game-icons.net\n'
      'Creative Commons Attribution 3.0 Unported (CC BY 3.0).\n'
      'https://creativecommons.org/licenses/by/3.0/\n'
      'Selected and renamed SVG files; UI may tint or resize them.\n'
      'Original icon names and individual attribution: docs/security/icon-attribution.json in the LifeRPG source.',
    );
  });
}
